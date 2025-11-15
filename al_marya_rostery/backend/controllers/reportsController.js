const Order = require('../models/Order');
const User = require('../models/User');
const Coffee = require('../models/Coffee');
const Category = require('../models/Category');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');

// @desc    Generate sales report
// @route   GET /api/admin/reports/sales
// @access  Private/Admin
const generateSalesReport = async (req, res) => {
  try {
    const { 
      startDate, 
      endDate, 
      format = 'json',
      groupBy = 'day' // day, week, month
    } = req.query;

    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    // Sales aggregation pipeline
    let groupId;
    switch (groupBy) {
      case 'week':
        groupId = {
          year: { $year: '$createdAt' },
          week: { $week: '$createdAt' }
        };
        break;
      case 'month':
        groupId = {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' }
        };
        break;
      default:
        groupId = {
          year: { $year: '$createdAt' },
          month: { $month: '$createdAt' },
          day: { $dayOfMonth: '$createdAt' }
        };
    }

    const salesData = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
          status: { $in: ['delivered', 'completed'] }
        }
      },
      {
        $group: {
          _id: groupId,
          totalSales: { $sum: '$totalAmount' },
          orderCount: { $sum: 1 },
          averageOrderValue: { $avg: '$totalAmount' }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
      }
    ]);

    // Product performance
    const productPerformance = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
          status: { $in: ['delivered', 'completed'] }
        }
      },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.coffee',
          totalQuantity: { $sum: '$items.quantity' },
          totalRevenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
          orderCount: { $sum: 1 }
        }
      },
      {
        $lookup: {
          from: 'coffees',
          localField: '_id',
          foreignField: '_id',
          as: 'product'
        }
      },
      { $unwind: '$product' },
      {
        $project: {
          productName: '$product.name.en',
          totalQuantity: 1,
          totalRevenue: 1,
          orderCount: 1
        }
      },
      { $sort: { totalRevenue: -1 } },
      { $limit: 20 }
    ]);

    const reportData = {
      period: { startDate: start, endDate: end },
      summary: {
        totalRevenue: salesData.reduce((sum, item) => sum + item.totalSales, 0),
        totalOrders: salesData.reduce((sum, item) => sum + item.orderCount, 0),
        averageOrderValue: salesData.length > 0 
          ? salesData.reduce((sum, item) => sum + item.averageOrderValue, 0) / salesData.length 
          : 0
      },
      salesTrend: salesData,
      topProducts: productPerformance,
      generatedAt: new Date()
    };

    if (format === 'pdf') {
      return generateSalesPDF(res, reportData);
    }

    if (format === 'excel') {
      return generateSalesExcel(res, reportData);
    }

    res.json({
      success: true,
      data: reportData
    });

  } catch (error) {
    console.error('Generate sales report error:', error);
    res.status(500).json({
      success: false,
      message: 'Error generating sales report',
      error: error.message
    });
  }
};

// @desc    Generate user activity report
// @route   GET /api/admin/reports/users
// @access  Private/Admin
const generateUserReport = async (req, res) => {
  try {
    const { 
      startDate, 
      endDate, 
      format = 'json'
    } = req.query;

    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    // User registration trends
    const registrationTrend = await User.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' },
            day: { $dayOfMonth: '$createdAt' }
          },
          newUsers: { $sum: 1 }
        }
      },
      {
        $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
      }
    ]);

    // User engagement (orders per user)
    const userEngagement = await User.aggregate([
      {
        $lookup: {
          from: 'orders',
          localField: '_id',
          foreignField: 'user',
          as: 'orders'
        }
      },
      {
        $project: {
          name: 1,
          email: 1,
          createdAt: 1,
          totalOrders: { $size: '$orders' },
          totalSpent: {
            $sum: {
              $map: {
                input: {
                  $filter: {
                    input: '$orders',
                    as: 'order',
                    cond: { $in: ['$$order.status', ['delivered', 'completed']] }
                  }
                },
                as: 'order',
                in: '$$order.totalAmount'
              }
            }
          }
        }
      },
      { $sort: { totalSpent: -1 } },
      { $limit: 50 }
    ]);

    const reportData = {
      period: { startDate: start, endDate: end },
      summary: {
        totalUsers: await User.countDocuments(),
        newUsers: registrationTrend.reduce((sum, item) => sum + item.newUsers, 0),
        activeUsers: userEngagement.filter(u => u.totalOrders > 0).length
      },
      registrationTrend,
      topCustomers: userEngagement,
      generatedAt: new Date()
    };

    if (format === 'pdf') {
      return generateUserPDF(res, reportData);
    }

    if (format === 'excel') {
      return generateUserExcel(res, reportData);
    }

    res.json({
      success: true,
      data: reportData
    });

  } catch (error) {
    console.error('Generate user report error:', error);
    res.status(500).json({
      success: false,
      message: 'Error generating user report',
      error: error.message
    });
  }
};

// @desc    Generate product performance report
// @route   GET /api/admin/reports/products
// @access  Private/Admin
const generateProductReport = async (req, res) => {
  try {
    const { 
      startDate, 
      endDate, 
      format = 'json'
    } = req.query;

    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    // Product sales performance
    const productPerformance = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
          status: { $in: ['delivered', 'completed'] }
        }
      },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.coffee',
          totalQuantity: { $sum: '$items.quantity' },
          totalRevenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
          orderCount: { $sum: 1 },
          averagePrice: { $avg: '$items.price' }
        }
      },
      {
        $lookup: {
          from: 'coffees',
          localField: '_id',
          foreignField: '_id',
          as: 'product'
        }
      },
      { $unwind: '$product' },
      {
        $project: {
          productName: '$product.name.en',
          productNameAr: '$product.name.ar',
          category: '$product.category',
          totalQuantity: 1,
          totalRevenue: 1,
          orderCount: 1,
          averagePrice: 1,
          currentPrice: '$product.price'
        }
      },
      { $sort: { totalRevenue: -1 } }
    ]);

    // Category performance
    const categoryPerformance = await Order.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
          status: { $in: ['delivered', 'completed'] }
        }
      },
      { $unwind: '$items' },
      {
        $lookup: {
          from: 'coffees',
          localField: 'items.coffee',
          foreignField: '_id',
          as: 'product'
        }
      },
      { $unwind: '$product' },
      {
        $group: {
          _id: '$product.category',
          totalQuantity: { $sum: '$items.quantity' },
          totalRevenue: { $sum: { $multiply: ['$items.quantity', '$items.price'] } },
          orderCount: { $sum: 1 }
        }
      },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'category'
        }
      },
      { $unwind: '$category' },
      {
        $project: {
          categoryName: '$category.name.en',
          totalQuantity: 1,
          totalRevenue: 1,
          orderCount: 1
        }
      },
      { $sort: { totalRevenue: -1 } }
    ]);

    const reportData = {
      period: { startDate: start, endDate: end },
      summary: {
        totalProducts: await Coffee.countDocuments(),
        activeProducts: await Coffee.countDocuments({ isActive: true }),
        totalRevenue: productPerformance.reduce((sum, item) => sum + item.totalRevenue, 0)
      },
      productPerformance,
      categoryPerformance,
      generatedAt: new Date()
    };

    if (format === 'pdf') {
      return generateProductPDF(res, reportData);
    }

    if (format === 'excel') {
      return generateProductExcel(res, reportData);
    }

    res.json({
      success: true,
      data: reportData
    });

  } catch (error) {
    console.error('Generate product report error:', error);
    res.status(500).json({
      success: false,
      message: 'Error generating product report',
      error: error.message
    });
  }
};

// PDF Generation Functions
function generateSalesPDF(res, data) {
  try {
    const doc = new PDFDocument();
    
    // Set response headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=sales-report-${new Date().toISOString().split('T')[0]}.pdf`);
    
    // Pipe the PDF to the response
    doc.pipe(res);
    
    // Add content
    doc.fontSize(20).text('Sales Report', { align: 'center' });
    doc.moveDown();
    
    doc.fontSize(12)
       .text(`Period: ${data.period.startDate.toDateString()} - ${data.period.endDate.toDateString()}`)
       .text(`Total Revenue: AED ${data.summary.totalRevenue.toFixed(2)}`)
       .text(`Total Orders: ${data.summary.totalOrders}`)
       .text(`Average Order Value: AED ${data.summary.averageOrderValue.toFixed(2)}`);
    
    doc.moveDown();
    doc.fontSize(16).text('Top Products:', { underline: true });
    doc.moveDown();
    
    data.topProducts.forEach((product, index) => {
      doc.fontSize(10)
         .text(`${index + 1}. ${product.productName} - Revenue: AED ${product.totalRevenue.toFixed(2)} (${product.totalQuantity} items)`);
    });
    
    doc.end();
  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).json({ success: false, message: 'Error generating PDF' });
  }
}

function generateUserPDF(res, data) {
  try {
    const doc = new PDFDocument();
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=user-report-${new Date().toISOString().split('T')[0]}.pdf`);
    
    doc.pipe(res);
    
    doc.fontSize(20).text('User Activity Report', { align: 'center' });
    doc.moveDown();
    
    doc.fontSize(12)
       .text(`Period: ${data.period.startDate.toDateString()} - ${data.period.endDate.toDateString()}`)
       .text(`Total Users: ${data.summary.totalUsers}`)
       .text(`New Users: ${data.summary.newUsers}`)
       .text(`Active Users: ${data.summary.activeUsers}`);
    
    doc.moveDown();
    doc.fontSize(16).text('Top Customers:', { underline: true });
    doc.moveDown();
    
    data.topCustomers.slice(0, 20).forEach((customer, index) => {
      doc.fontSize(10)
         .text(`${index + 1}. ${customer.name} - Spent: AED ${customer.totalSpent.toFixed(2)} (${customer.totalOrders} orders)`);
    });
    
    doc.end();
  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).json({ success: false, message: 'Error generating PDF' });
  }
}

function generateProductPDF(res, data) {
  try {
    const doc = new PDFDocument();
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=product-report-${new Date().toISOString().split('T')[0]}.pdf`);
    
    doc.pipe(res);
    
    doc.fontSize(20).text('Product Performance Report', { align: 'center' });
    doc.moveDown();
    
    doc.fontSize(12)
       .text(`Period: ${data.period.startDate.toDateString()} - ${data.period.endDate.toDateString()}`)
       .text(`Total Products: ${data.summary.totalProducts}`)
       .text(`Active Products: ${data.summary.activeProducts}`)
       .text(`Total Revenue: AED ${data.summary.totalRevenue.toFixed(2)}`);
    
    doc.moveDown();
    doc.fontSize(16).text('Product Performance:', { underline: true });
    doc.moveDown();
    
    data.productPerformance.slice(0, 20).forEach((product, index) => {
      doc.fontSize(10)
         .text(`${index + 1}. ${product.productName} - Revenue: AED ${product.totalRevenue.toFixed(2)} (${product.totalQuantity} items)`);
    });
    
    doc.end();
  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).json({ success: false, message: 'Error generating PDF' });
  }
}

// Excel Generation Functions (simplified - would need ExcelJS for full implementation)
function generateSalesExcel(res, data) {
  // For now, return CSV format
  const csvData = [
    ['Sales Report'],
    [`Period: ${data.period.startDate.toDateString()} - ${data.period.endDate.toDateString()}`],
    [`Total Revenue: AED ${data.summary.totalRevenue.toFixed(2)}`],
    [`Total Orders: ${data.summary.totalOrders}`],
    [],
    ['Product Name', 'Revenue', 'Quantity'],
    ...data.topProducts.map(p => [p.productName, p.totalRevenue.toFixed(2), p.totalQuantity])
  ];

  const csvContent = csvData.map(row => row.join(',')).join('\n');

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename=sales-report-${new Date().toISOString().split('T')[0]}.csv`);
  res.send(csvContent);
}

function generateUserExcel(res, data) {
  const csvData = [
    ['User Activity Report'],
    [`Period: ${data.period.startDate.toDateString()} - ${data.period.endDate.toDateString()}`],
    [`Total Users: ${data.summary.totalUsers}`],
    [],
    ['Customer Name', 'Email', 'Total Spent', 'Total Orders'],
    ...data.topCustomers.map(c => [c.name, c.email, c.totalSpent.toFixed(2), c.totalOrders])
  ];

  const csvContent = csvData.map(row => row.join(',')).join('\n');

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename=user-report-${new Date().toISOString().split('T')[0]}.csv`);
  res.send(csvContent);
}

function generateProductExcel(res, data) {
  const csvData = [
    ['Product Performance Report'],
    [`Period: ${data.period.startDate.toDateString()} - ${data.period.endDate.toDateString()}`],
    [`Total Revenue: AED ${data.summary.totalRevenue.toFixed(2)}`],
    [],
    ['Product Name', 'Revenue', 'Quantity', 'Orders'],
    ...data.productPerformance.map(p => [p.productName, p.totalRevenue.toFixed(2), p.totalQuantity, p.orderCount])
  ];

  const csvContent = csvData.map(row => row.join(',')).join('\n');

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename=product-report-${new Date().toISOString().split('T')[0]}.csv`);
  res.send(csvContent);
}

module.exports = {
  generateSalesReport,
  generateUserReport,
  generateProductReport
};

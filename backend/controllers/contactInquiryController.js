const ContactInquiry = require('../models/ContactInquiry');
const { validationResult } = require('express-validator');

// Create new contact inquiry
exports.createContactInquiry = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    // Extract metadata from request
    const metadata = {
      source: req.body.source || 'website',
      ipAddress: req.ip,
      userAgent: req.get('User-Agent'),
      referrer: req.get('Referer'),
      sessionId: req.sessionID
    };

    const inquiryData = {
      ...req.body,
      metadata
    };

    const inquiry = new ContactInquiry(inquiryData);
    await inquiry.save();

    res.status(201).json({
      success: true,
      message: 'Contact inquiry submitted successfully',
      data: {
        id: inquiry._id,
        status: inquiry.status.current,
        createdAt: inquiry.createdAt
      }
    });
  } catch (error) {
    console.error('Error creating contact inquiry:', error);
    res.status(500).json({
      success: false,
      message: 'Error submitting contact inquiry',
      error: error.message
    });
  }
};

// Get all contact inquiries with filtering and pagination (Admin only)
exports.getAllContactInquiries = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 50,
      status,
      type,
      priority,
      department,
      assignedTo,
      startDate,
      endDate,
      search,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    // Build filter object
    const filter = {};
    
    if (status) filter['status.current'] = status;
    if (type) filter['inquiry.type'] = type;
    if (priority) filter['inquiry.priority'] = priority;
    if (department) filter['assignment.department'] = department;
    if (assignedTo) filter['assignment.assignedTo'] = assignedTo;
    
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }

    // Handle search
    if (search) {
      filter.$text = { $search: search };
    }

    // Build sort object
    const sort = {};
    if (search) {
      sort.score = { $meta: 'textScore' };
    } else {
      sort[sortBy] = sortOrder === 'desc' ? -1 : 1;
    }

    const inquiries = await ContactInquiry.find(filter)
      .sort(sort)
      .skip((page - 1) * limit)
      .limit(parseInt(limit))
      .populate('assignment.assignedTo', 'name email')
      .populate('assignment.assignedBy', 'name email')
      .populate('responses.respondedBy', 'name email')
      .populate('relatedOrder.orderId', 'orderNumber');

    const total = await ContactInquiry.countDocuments(filter);

    res.json({
      success: true,
      data: inquiries,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Error fetching contact inquiries:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching contact inquiries',
      error: error.message
    });
  }
};

// Get contact inquiry by ID
exports.getContactInquiryById = async (req, res) => {
  try {
    const inquiry = await ContactInquiry.findById(req.params.id)
      .populate('assignment.assignedTo', 'name email')
      .populate('assignment.assignedBy', 'name email')
      .populate('responses.respondedBy', 'name email')
      .populate('relatedOrder.orderId', 'orderNumber')
      .populate('internalNotes.addedBy', 'name email');
    
    if (!inquiry) {
      return res.status(404).json({
        success: false,
        message: 'Contact inquiry not found'
      });
    }

    res.json({
      success: true,
      data: inquiry
    });
  } catch (error) {
    console.error('Error fetching contact inquiry:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching contact inquiry',
      error: error.message
    });
  }
};

// Update inquiry status (Admin only)
exports.updateInquiryStatus = async (req, res) => {
  try {
    const { status, note } = req.body;
    const updatedBy = req.user.id;

    const inquiry = await ContactInquiry.findById(req.params.id);

    if (!inquiry) {
      return res.status(404).json({
        success: false,
        message: 'Contact inquiry not found'
      });
    }

    await inquiry.updateStatus(status, updatedBy, note);

    res.json({
      success: true,
      message: 'Inquiry status updated successfully',
      data: inquiry
    });
  } catch (error) {
    console.error('Error updating inquiry status:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating inquiry status',
      error: error.message
    });
  }
};

// Assign inquiry (Admin only)
exports.assignInquiry = async (req, res) => {
  try {
    const { assignedTo, department } = req.body;
    const assignedBy = req.user.id;

    const inquiry = await ContactInquiry.findById(req.params.id);

    if (!inquiry) {
      return res.status(404).json({
        success: false,
        message: 'Contact inquiry not found'
      });
    }

    await inquiry.assign(assignedTo, assignedBy, department);

    res.json({
      success: true,
      message: 'Inquiry assigned successfully',
      data: inquiry
    });
  } catch (error) {
    console.error('Error assigning inquiry:', error);
    res.status(500).json({
      success: false,
      message: 'Error assigning inquiry',
      error: error.message
    });
  }
};

// Add response to inquiry (Admin only)
exports.addResponse = async (req, res) => {
  try {
    const { message, isInternal = false, attachments = [] } = req.body;
    const respondedBy = req.user.id;

    const inquiry = await ContactInquiry.findById(req.params.id);

    if (!inquiry) {
      return res.status(404).json({
        success: false,
        message: 'Contact inquiry not found'
      });
    }

    const responseData = {
      respondedBy,
      message,
      isInternal,
      attachments
    };

    await inquiry.addResponse(responseData);

    res.json({
      success: true,
      message: 'Response added successfully',
      data: inquiry
    });
  } catch (error) {
    console.error('Error adding response:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding response',
      error: error.message
    });
  }
};

// Add internal note (Admin only)
exports.addInternalNote = async (req, res) => {
  try {
    const { note } = req.body;
    const addedBy = req.user.id;

    const inquiry = await ContactInquiry.findById(req.params.id);

    if (!inquiry) {
      return res.status(404).json({
        success: false,
        message: 'Contact inquiry not found'
      });
    }

    await inquiry.addInternalNote(note, addedBy);

    res.json({
      success: true,
      message: 'Internal note added successfully',
      data: inquiry
    });
  } catch (error) {
    console.error('Error adding internal note:', error);
    res.status(500).json({
      success: false,
      message: 'Error adding internal note',
      error: error.message
    });
  }
};

// Get inquiries by status
exports.getInquiriesByStatus = async (req, res) => {
  try {
    const { status } = req.params;
    const { limit = 50 } = req.query;
    
    const inquiries = await ContactInquiry.findByStatus(status, parseInt(limit));

    res.json({
      success: true,
      data: inquiries
    });
  } catch (error) {
    console.error('Error fetching inquiries by status:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching inquiries by status',
      error: error.message
    });
  }
};

// Get inquiries by department
exports.getInquiriesByDepartment = async (req, res) => {
  try {
    const { department } = req.params;
    const { limit = 50 } = req.query;
    
    const inquiries = await ContactInquiry.findByDepartment(department, parseInt(limit));

    res.json({
      success: true,
      data: inquiries
    });
  } catch (error) {
    console.error('Error fetching inquiries by department:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching inquiries by department',
      error: error.message
    });
  }
};

// Get inquiries by priority
exports.getInquiriesByPriority = async (req, res) => {
  try {
    const { priority } = req.params;
    const { limit = 50 } = req.query;
    
    const inquiries = await ContactInquiry.findByPriority(priority, parseInt(limit));

    res.json({
      success: true,
      data: inquiries
    });
  } catch (error) {
    console.error('Error fetching inquiries by priority:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching inquiries by priority',
      error: error.message
    });
  }
};

// Get overdue inquiries
exports.getOverdueInquiries = async (req, res) => {
  try {
    const inquiries = await ContactInquiry.findOverdue();

    res.json({
      success: true,
      data: inquiries
    });
  } catch (error) {
    console.error('Error fetching overdue inquiries:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching overdue inquiries',
      error: error.message
    });
  }
};

// Set satisfaction rating
exports.setSatisfactionRating = async (req, res) => {
  try {
    const { rating, feedback } = req.body;
    
    if (!rating || rating < 1 || rating > 5) {
      return res.status(400).json({
        success: false,
        message: 'Rating must be between 1 and 5'
      });
    }

    const inquiry = await ContactInquiry.findById(req.params.id);

    if (!inquiry) {
      return res.status(404).json({
        success: false,
        message: 'Contact inquiry not found'
      });
    }

    await inquiry.setSatisfactionRating(rating, feedback);

    res.json({
      success: true,
      message: 'Satisfaction rating submitted successfully',
      data: inquiry
    });
  } catch (error) {
    console.error('Error setting satisfaction rating:', error);
    res.status(500).json({
      success: false,
      message: 'Error setting satisfaction rating',
      error: error.message
    });
  }
};

// Get contact inquiry analytics (Admin only)
exports.getContactAnalytics = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // Default to 30 days ago
    const end = endDate ? new Date(endDate) : new Date();

    const analytics = await ContactInquiry.getAnalytics(start, end);

    // Get additional analytics
    const statusCounts = await ContactInquiry.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end }
        }
      },
      {
        $group: {
          _id: '$status.current',
          count: { $sum: 1 }
        }
      }
    ]);

    const typeCounts = await ContactInquiry.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end }
        }
      },
      {
        $group: {
          _id: '$inquiry.type',
          count: { $sum: 1 }
        }
      }
    ]);

    const priorityCounts = await ContactInquiry.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end }
        }
      },
      {
        $group: {
          _id: '$inquiry.priority',
          count: { $sum: 1 }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        summary: analytics[0] || {},
        statusDistribution: statusCounts,
        typeDistribution: typeCounts,
        priorityDistribution: priorityCounts,
        period: { startDate: start, endDate: end }
      }
    });
  } catch (error) {
    console.error('Error fetching contact analytics:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching contact analytics',
      error: error.message
    });
  }
};

// Delete contact inquiry (Admin only)
exports.deleteContactInquiry = async (req, res) => {
  try {
    const inquiry = await ContactInquiry.findByIdAndDelete(req.params.id);

    if (!inquiry) {
      return res.status(404).json({
        success: false,
        message: 'Contact inquiry not found'
      });
    }

    res.json({
      success: true,
      message: 'Contact inquiry deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting contact inquiry:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting contact inquiry',
      error: error.message
    });
  }
};

// Get my inquiries (for authenticated users)
exports.getMyInquiries = async (req, res) => {
  try {
    const { email } = req.user; // Assuming user email is available in req.user
    
    const inquiries = await ContactInquiry.find({
      'contactInfo.email': email
    })
    .sort({ createdAt: -1 })
    .select('-internalNotes -responses.isInternal'); // Hide internal notes and internal responses

    res.json({
      success: true,
      data: inquiries
    });
  } catch (error) {
    console.error('Error fetching user inquiries:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching your inquiries',
      error: error.message
    });
  }
};

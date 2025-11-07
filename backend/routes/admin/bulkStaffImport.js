const express = require('express');
const router = express.Router();
const multer = require('multer');
const csv = require('csv-parser');
const { Readable } = require('stream');
const Staff = require('../../models/Staff');
const qrBadgeService = require('../../services/qrBadgeService');
const { protect, authorize } = require('../../middleware/auth');

// Configure multer for CSV file upload (memory storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'text/csv' || file.originalname.endsWith('.csv')) {
      cb(null, true);
    } else {
      cb(new Error('Only CSV files are allowed'), false);
    }
  }
});

/**
 * @route   POST /api/admin/staff/bulk-import
 * @desc    Bulk import staff from CSV file
 * @access  Private (Admin only)
 * 
 * CSV Format:
 * name,email,phone,role,shiftStartTime,shiftEndTime
 * John Doe,john@example.com,+971501234567,barista,08:00,17:00
 */
router.post(
  '/bulk-import',
  protect,
  authorize('admin'),
  upload.single('csvFile'),
  async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No CSV file uploaded'
        });
      }

      console.log('📄 Processing CSV file:', req.file.originalname);

      const results = [];
      const errors = [];
      const stream = Readable.from(req.file.buffer.toString());

      // Parse CSV
      await new Promise((resolve, reject) => {
        stream
          .pipe(csv())
          .on('data', (data) => results.push(data))
          .on('end', resolve)
          .on('error', reject);
      });

      console.log(`📊 Found ${results.length} rows in CSV`);

      if (results.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'CSV file is empty'
        });
      }

      // Validate and import each staff member
      const imported = [];
      const skipped = [];

      for (let i = 0; i < results.length; i++) {
        const row = results[i];
        const rowNumber = i + 2; // +2 because row 1 is header

        try {
          // Validate required fields
          if (!row.name || !row.email || !row.phone || !row.role) {
            errors.push({
              row: rowNumber,
              data: row,
              error: 'Missing required fields (name, email, phone, role)'
            });
            continue;
          }

          // Validate role
          const validRoles = ['barista', 'manager', 'cashier'];
          if (!validRoles.includes(row.role.toLowerCase())) {
            errors.push({
              row: rowNumber,
              data: row,
              error: `Invalid role '${row.role}'. Must be: barista, manager, or cashier`
            });
            continue;
          }

          // Check if staff already exists
          const existingStaff = await Staff.findOne({
            email: row.email.toLowerCase(),
            isDeleted: false
          });

          if (existingStaff) {
            skipped.push({
              row: rowNumber,
              email: row.email,
              reason: 'Staff with this email already exists'
            });
            continue;
          }

          // Generate unique employee ID
          const rolePrefix = row.role.substring(0, 3).toUpperCase();
          const lastStaff = await Staff.findOne({ 
            employeeId: new RegExp(`^${rolePrefix}\\d+$`) 
          }).sort({ employeeId: -1 });
          
          let nextNumber = 1;
          if (lastStaff && lastStaff.employeeId) {
            const match = lastStaff.employeeId.match(/\d+$/);
            if (match) {
              nextNumber = parseInt(match[0]) + 1;
            }
          }
          const employeeId = `${rolePrefix}${String(nextNumber).padStart(3, '0')}`;

          // Generate QR badge
          const qrToken = qrBadgeService.generateQRToken(employeeId);
          const qrExpiresAt = new Date();
          qrExpiresAt.setMonth(qrExpiresAt.getMonth() + 6);

          // Create staff member
          const staff = new Staff({
            name: row.name.trim(),
            email: row.email.toLowerCase().trim(),
            phone: row.phone.trim(),
            role: row.role.toLowerCase(),
            employeeId,
            status: 'inactive', // Set to inactive until they activate
            shiftStartTime: row.shiftStartTime || '09:00',
            shiftEndTime: row.shiftEndTime || '18:00',
            qrBadgeToken: qrToken,
            qrBadgeGeneratedAt: new Date(),
            qrBadgeExpiresAt: qrExpiresAt,
            requirePinChange: true,
            isDeleted: false
          });

          await staff.save();

          imported.push({
            row: rowNumber,
            employeeId: staff.employeeId,
            name: staff.name,
            email: staff.email,
            role: staff.role
          });

          console.log(`✅ Row ${rowNumber}: ${staff.employeeId} - ${staff.name}`);

        } catch (error) {
          console.error(`❌ Row ${rowNumber} error:`, error.message);
          errors.push({
            row: rowNumber,
            data: row,
            error: error.message
          });
        }
      }

      // Summary
      const summary = {
        total: results.length,
        imported: imported.length,
        skipped: skipped.length,
        errors: errors.length
      };

      console.log('\n📊 Import Summary:', summary);

      res.json({
        success: true,
        message: `Successfully imported ${imported.length} staff members`,
        summary,
        imported,
        skipped,
        errors
      });

    } catch (error) {
      console.error('Bulk import error:', error);
      res.status(500).json({
        success: false,
        message: 'Error processing CSV file',
        error: error.message
      });
    }
  }
);

/**
 * @route   GET /api/admin/staff/bulk-import/template
 * @desc    Download CSV template for bulk import
 * @access  Private (Admin only)
 */
router.get(
  '/bulk-import/template',
  protect,
  authorize('admin'),
  (req, res) => {
    const csvContent = [
      'name,email,phone,role,shiftStartTime,shiftEndTime',
      'John Doe,john@example.com,+971501234567,barista,08:00,17:00',
      'Jane Smith,jane@example.com,+971507654321,manager,09:00,18:00',
      'Ahmed Ali,ahmed@example.com,+971509876543,cashier,10:00,19:00'
    ].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename="staff_import_template.csv"');
    res.send(csvContent);
  }
);

module.exports = router;

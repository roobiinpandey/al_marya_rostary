const AuditLog = require('../models/AuditLog');

// Helper function to log admin actions
const logAdminAction = async (userId, action, details = {}, req = null, targetUserId = null) => {
  try {
    const logData = {
      userId,
      action,
      details,
      targetUserId
    };

    // Extract IP and user agent from request if provided
    if (req) {
      logData.ipAddress = req.ip || req.connection.remoteAddress;
      logData.userAgent = req.get('User-Agent');
    }

    await AuditLog.create(logData);
  } catch (error) {
    console.error('Failed to log admin action:', error);
  }
};

// Helper function to log user actions
const logUserAction = async (userId, action, details = {}, req = null) => {
  return logAdminAction(userId, action, details, req, null);
};

// Log audit action (main function used throughout the app)
const logAudit = async (userId, action, resourceType, resourceId, details = {}) => {
  try {
    await AuditLog.create({
      adminId: userId,
      action,
      resourceType,
      resourceId,
      details,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('Failed to log audit action:', error);
  }
};

// Get audit logs with filtering and pagination
const getAuditLogs = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Build filter object
    const filter = {};
    
    if (req.query.adminId) {
      filter.adminId = req.query.adminId;
    }
    
    if (req.query.action) {
      filter.action = req.query.action;
    }
    
    if (req.query.resourceType) {
      filter.resourceType = req.query.resourceType;
    }
    
    if (req.query.dateFrom || req.query.dateTo) {
      filter.timestamp = {};
      if (req.query.dateFrom) {
        filter.timestamp.$gte = new Date(req.query.dateFrom);
      }
      if (req.query.dateTo) {
        filter.timestamp.$lte = new Date(req.query.dateTo);
      }
    }

    const logs = await AuditLog.find(filter)
      .populate('adminId', 'name email')
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit);

    const total = await AuditLog.countDocuments(filter);
    const pages = Math.ceil(total / limit);

    // Transform data for frontend
    const transformedLogs = logs.map(log => ({
      _id: log._id,
      action: log.action,
      resourceType: log.resourceType,
      resourceId: log.resourceId,
      details: log.details,
      adminName: log.adminId?.name || 'Unknown Admin',
      adminEmail: log.adminId?.email || 'N/A',
      createdAt: log.timestamp
    }));

    res.json({
      success: true,
      data: {
        logs: transformedLogs,
        pagination: {
          page,
          limit,
          total,
          pages
        }
      }
    });
  } catch (error) {
    console.error('Get audit logs error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch audit logs',
      error: error.message
    });
  }
};

// Get audit log statistics
const getAuditStats = async (req, res) => {
  try {
    const totalLogs = await AuditLog.countDocuments();
    
    // Get logs from today
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const actionsToday = await AuditLog.countDocuments({ 
      timestamp: { $gte: today } 
    });

    // Get action breakdown
    const actionBreakdown = await AuditLog.aggregate([
      {
        $group: {
          _id: '$action',
          count: { $sum: 1 }
        }
      },
      {
        $sort: { count: -1 }
      },
      {
        $limit: 10
      }
    ]);

    res.json({
      success: true,
      data: {
        totalLogs,
        actionsToday,
        actionBreakdown
      }
    });
  } catch (error) {
    console.error('Get audit stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch audit statistics',
      error: error.message
    });
  }
};

// Clean up old audit logs
const cleanupOldLogs = async (req, res) => {
  try {
    const { days = 30 } = req.query;
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - parseInt(days));

    const result = await AuditLog.deleteMany({
      timestamp: { $lt: cutoffDate }
    });

    // Log the cleanup action
    await logAudit(req.user.id, 'CLEANUP_AUDIT_LOGS', 'System', 'cleanup', {
      deletedCount: result.deletedCount,
      cutoffDate: cutoffDate.toISOString()
    });

    res.json({
      success: true,
      message: `Cleaned up ${result.deletedCount} old audit logs`,
      data: {
        deletedCount: result.deletedCount
      }
    });
  } catch (error) {
    console.error('Cleanup logs error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to cleanup audit logs',
      error: error.message
    });
  }
};

module.exports = {
  logAdminAction,
  logUserAction,
  logAudit,
  getAuditLogs,
  getAuditStats,
  cleanupOldLogs
};

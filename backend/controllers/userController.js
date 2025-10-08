const User = require('../models/User');
const { logAdminAction } = require('../utils/auditLogger');
const mongoose = require('mongoose');

// @desc    Get all users
// @route   GET /api/users
// @access  Private/Admin
const getUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Build filter object
    const filter = {};
    
    // Role filtering (supports multiple roles)
    if (req.query.role) {
      if (Array.isArray(req.query.role)) {
        filter.roles = { $in: req.query.role };
      } else {
        filter.roles = { $in: [req.query.role] };
      }
    }
    
    if (req.query.isActive !== undefined) filter.isActive = req.query.isActive === 'true';
    if (req.query.isEmailVerified !== undefined) filter.isEmailVerified = req.query.isEmailVerified === 'true';
    
    // Date range filtering
    if (req.query.dateFrom || req.query.dateTo) {
      filter.createdAt = {};
      if (req.query.dateFrom) filter.createdAt.$gte = new Date(req.query.dateFrom);
      if (req.query.dateTo) filter.createdAt.$lte = new Date(req.query.dateTo);
    }

    // Search functionality
    if (req.query.search) {
      filter.$or = [
        { name: { $regex: req.query.search, $options: 'i' } },
        { email: { $regex: req.query.search, $options: 'i' } },
        { phone: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    // Sorting options
    let sortOption = { createdAt: -1 }; // default sort
    if (req.query.sortBy) {
      const sortBy = req.query.sortBy;
      const sortOrder = req.query.sortOrder === 'asc' ? 1 : -1;
      sortOption = { [sortBy]: sortOrder };
    }

    const users = await User.find(filter)
      .select('-password')
      .sort(sortOption)
      .skip(skip)
      .limit(limit);

    const total = await User.countDocuments(filter);
    const pages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: users,
      pagination: {
        page,
        limit,
        total,
        pages
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
      error: error.message
    });
  }
};

// @desc    Get single user
// @route   GET /api/users/:id
// @access  Private/Admin
const getUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user',
      error: error.message
    });
  }
};

// @desc    Update user
// @route   PUT /api/users/:id
// @access  Private/Admin
const updateUser = async (req, res) => {
  try {
    const { name, email, phone, role, isActive } = req.body;

    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if email is being changed and if it's already taken
    if (email && email !== user.email) {
      const existingUser = await User.findByEmail(email);
      if (existingUser && existingUser._id.toString() !== user._id.toString()) {
        return res.status(400).json({
          success: false,
          message: 'Email already taken by another user'
        });
      }
    }

    // Update user
    user.name = name || user.name;
    user.email = email || user.email;
    user.phone = phone || user.phone;
    user.role = role || user.role;
    user.isActive = isActive !== undefined ? isActive : user.isActive;

    await user.save();

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_UPDATED',
      { targetUser: user._id, changes: req.body },
      req,
      user._id
    );

    res.json({
      success: true,
      message: 'User updated successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
      error: error.message
    });
  }
};

// @desc    Delete user
// @route   DELETE /api/users/:id
// @access  Private/Admin
const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    await User.findByIdAndDelete(req.params.id);

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_DELETED',
      { deletedUser: { id: user._id, name: user.name, email: user.email } },
      req,
      user._id
    );

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
      error: error.message
    });
  }
};

// @desc    Get user statistics
// @route   GET /api/users/stats
// @access  Private/Admin
const getUserStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ isActive: true });
    const adminUsers = await User.countDocuments({ roles: 'admin' });
    const customerUsers = await User.countDocuments({ roles: 'customer' });

    // Get users registered in the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const newUsers = await User.countDocuments({ createdAt: { $gte: thirtyDaysAgo } });

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          activeUsers,
          inactiveUsers: totalUsers - activeUsers,
          adminUsers,
          customerUsers,
          newUsers
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user statistics',
      error: error.message
    });
  }
};

// @desc    Create new user (Admin only)
// @route   POST /api/admin/users
// @access  Private/Admin
const createUser = async (req, res) => {
  try {
    const { name, email, password, phone, roles, isActive, isEmailVerified } = req.body;

    // Check if user already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'User with this email already exists'
      });
    }

    // Create user
    const user = await User.create({
      name,
      email,
      password,
      phone,
      roles: roles || ['customer'],
      isActive: isActive !== undefined ? isActive : true,
      isEmailVerified: isEmailVerified !== undefined ? isEmailVerified : false
    });

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_CREATED',
      { createdUser: { id: user._id, name: user.name, email: user.email, roles: user.roles } },
      req,
      user._id
    );

    res.status(201).json({
      success: true,
      message: 'User created successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create user',
      error: error.message
    });
  }
};

// @desc    Bulk update users
// @route   PUT /api/admin/users/bulk
// @access  Private/Admin
const bulkUpdateUsers = async (req, res) => {
  try {
    const { userIds, updates } = req.body;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'User IDs array is required'
      });
    }

    // Validate user IDs
    const validUserIds = userIds.filter(id => mongoose.Types.ObjectId.isValid(id));
    if (validUserIds.length !== userIds.length) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user IDs provided'
      });
    }

    // Perform bulk update
    const result = await User.updateMany(
      { _id: { $in: validUserIds } },
      { $set: updates },
      { runValidators: true }
    );

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_UPDATED',
      { 
        bulkUpdate: true, 
        affectedUsers: validUserIds.length, 
        updates 
      },
      req
    );

    res.json({
      success: true,
      message: `Updated ${result.modifiedCount} users successfully`,
      data: {
        matchedCount: result.matchedCount,
        modifiedCount: result.modifiedCount
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to bulk update users',
      error: error.message
    });
  }
};

// @desc    Toggle user status (activate/deactivate)
// @route   PATCH /api/admin/users/:id/toggle-status
// @access  Private/Admin
const toggleUserStatus = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const previousStatus = user.isActive;
    user.isActive = !user.isActive;
    await user.save();

    // Log admin action
    await logAdminAction(
      req.user.id,
      user.isActive ? 'USER_ACTIVATED' : 'USER_DEACTIVATED',
      { 
        targetUser: user._id, 
        previousStatus, 
        newStatus: user.isActive 
      },
      req,
      user._id
    );

    res.json({
      success: true,
      message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to toggle user status',
      error: error.message
    });
  }
};

// @desc    Update user roles
// @route   PATCH /api/admin/users/:id/roles
// @access  Private/Admin
const updateUserRoles = async (req, res) => {
  try {
    const { roles } = req.body;

    if (!Array.isArray(roles) || roles.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Roles array is required'
      });
    }

    // Validate roles
    const validRoles = ['customer', 'admin'];
    const invalidRoles = roles.filter(role => !validRoles.includes(role));
    if (invalidRoles.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid roles: ${invalidRoles.join(', ')}`
      });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const previousRoles = [...user.roles];
    user.roles = roles;
    await user.save();

    // Log admin action
    await logAdminAction(
      req.user.id,
      'USER_ROLE_CHANGED',
      { 
        targetUser: user._id, 
        previousRoles, 
        newRoles: roles 
      },
      req,
      user._id
    );

    res.json({
      success: true,
      message: 'User roles updated successfully',
      data: user
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update user roles',
      error: error.message
    });
  }
};

// @desc    Get user activity/login history
// @route   GET /api/admin/users/:id/activity
// @access  Private/Admin
const getUserActivity = async (req, res) => {
  try {
    const AuditLog = require('../models/AuditLog');
    
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Get user activity logs
    const activities = await AuditLog.find({
      $or: [
        { userId: req.params.id },
        { targetUserId: req.params.id }
      ]
    })
    .populate('userId', 'name email')
    .sort({ timestamp: -1 })
    .skip(skip)
    .limit(limit);

    const total = await AuditLog.countDocuments({
      $or: [
        { userId: req.params.id },
        { targetUserId: req.params.id }
      ]
    });

    const pages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: activities,
      pagination: {
        page,
        limit,
        total,
        pages
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user activity',
      error: error.message
    });
  }
};

// @desc    Export users data
// @route   GET /api/admin/users/export
// @access  Private/Admin
const exportUsers = async (req, res) => {
  try {
    const { format = 'json' } = req.query;
    
    // Build filter (same as getUsers)
    const filter = {};
    if (req.query.role) {
      if (Array.isArray(req.query.role)) {
        filter.roles = { $in: req.query.role };
      } else {
        filter.roles = { $in: [req.query.role] };
      }
    }
    if (req.query.isActive !== undefined) filter.isActive = req.query.isActive === 'true';
    if (req.query.search) {
      filter.$or = [
        { name: { $regex: req.query.search, $options: 'i' } },
        { email: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    const users = await User.find(filter)
      .select('-password')
      .sort({ createdAt: -1 });

    // Log export action
    await logAdminAction(
      req.user.id,
      'USER_EXPORT',
      { format, totalExported: users.length },
      req
    );

    if (format === 'csv') {
      // Convert to CSV format
      const csv = users.map(user => ({
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone || '',
        roles: user.roles.join(', '),
        isActive: user.isActive,
        isEmailVerified: user.isEmailVerified,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin || ''
      }));

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=users.csv');
      
      // Simple CSV conversion (you might want to use a proper CSV library)
      const headers = Object.keys(csv[0] || {}).join(',');
      const rows = csv.map(row => Object.values(row).join(','));
      const csvContent = [headers, ...rows].join('\n');
      
      res.send(csvContent);
    } else {
      res.json({
        success: true,
        data: users,
        meta: {
          totalExported: users.length,
          exportedAt: new Date()
        }
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to export users',
      error: error.message
    });
  }
};

module.exports = {
  getUsers,
  getUser,
  updateUser,
  deleteUser,
  getUserStats,
  createUser,
  bulkUpdateUsers,
  toggleUserStatus,
  updateUserRoles,
  getUserActivity,
  exportUsers
};

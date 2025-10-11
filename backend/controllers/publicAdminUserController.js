const User = require('../models/User');
const mongoose = require('mongoose');

// Public Admin User Controller - No authentication required
// These functions are similar to userController but without auth/audit logging

// @desc    Get all users
// @route   GET /api/public-admin/users
// @access  Public (for development only)
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
    console.error('Error fetching users:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch users',
      error: error.message
    });
  }
};

// @desc    Get single user
// @route   GET /api/public-admin/users/:id
// @access  Public (for development only)
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
    console.error('Error fetching user:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user',
      error: error.message
    });
  }
};

// @desc    Update user
// @route   PUT /api/public-admin/users/:id
// @access  Public (for development only)
const updateUser = async (req, res) => {
  try {
    const { name, email, phone, roles, isActive } = req.body;

    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Check if email is being changed and if it's already taken
    if (email && email !== user.email) {
      const existingUser = await User.findOne({ email: email });
      if (existingUser && existingUser._id.toString() !== user._id.toString()) {
        return res.status(400).json({
          success: false,
          message: 'Email already taken by another user'
        });
      }
    }

    // Update user fields
    if (name !== undefined) user.name = name;
    if (email !== undefined) user.email = email;
    if (phone !== undefined) user.phone = phone;
    if (roles !== undefined) user.roles = roles;
    if (isActive !== undefined) user.isActive = isActive;

    await user.save();

    // Return updated user without password
    const updatedUser = await User.findById(user._id).select('-password');

    res.json({
      success: true,
      message: 'User updated successfully',
      data: updatedUser
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update user',
      error: error.message
    });
  }
};

// @desc    Delete user
// @route   DELETE /api/public-admin/users/:id
// @access  Public (for development only)
const deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Store user info for response
    const deletedUserInfo = {
      id: user._id,
      name: user.name,
      email: user.email
    };

    await User.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'User deleted successfully',
      data: deletedUserInfo
    });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete user',
      error: error.message
    });
  }
};

// @desc    Get user statistics
// @route   GET /api/public-admin/users/stats
// @access  Public (for development only)
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

    // Get users registered today
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);
    const newUsersToday = await User.countDocuments({ 
      createdAt: { $gte: todayStart, $lte: todayEnd } 
    });

    // Get users registered this week
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - 7);
    const newUsersWeek = await User.countDocuments({ createdAt: { $gte: weekStart } });

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          activeUsers,
          inactiveUsers: totalUsers - activeUsers,
          adminUsers,
          customerUsers,
          newUsers,
          newUsersToday,
          newUsersWeek
        }
      }
    });
  } catch (error) {
    console.error('Error fetching user statistics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user statistics',
      error: error.message
    });
  }
};

// @desc    Create new user
// @route   POST /api/public-admin/users
// @access  Public (for development only)
const createUser = async (req, res) => {
  try {
    const { name, email, password, phone, roles, isActive, isEmailVerified } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email: email });
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

    // Return user without password
    const newUser = await User.findById(user._id).select('-password');

    res.status(201).json({
      success: true,
      message: 'User created successfully',
      data: newUser
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create user',
      error: error.message
    });
  }
};

// @desc    Toggle user status (activate/deactivate)
// @route   PATCH /api/public-admin/users/:id/toggle-status
// @access  Public (for development only)
const toggleUserStatus = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    user.isActive = !user.isActive;
    await user.save();

    // Return updated user without password
    const updatedUser = await User.findById(user._id).select('-password');

    res.json({
      success: true,
      message: `User ${user.isActive ? 'activated' : 'deactivated'} successfully`,
      data: updatedUser
    });
  } catch (error) {
    console.error('Error toggling user status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle user status',
      error: error.message
    });
  }
};

// @desc    Export users data
// @route   GET /api/public-admin/users/export
// @access  Public (for development only)
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
      
      // Simple CSV conversion
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
    console.error('Error exporting users:', error);
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
  toggleUserStatus,
  exportUsers
};
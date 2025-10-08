const Notification = require('../models/Notification');
const { validationResult } = require('express-validator');
const pushNotificationService = require('../services/pushNotificationService');
const auditLogger = require('../utils/auditLogger');

// @desc    Get all notifications
// @route   GET /api/notifications
// @access  Private/Admin
const getNotifications = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = {};

    // Add status filter
    if (req.query.status) {
      filter.status = req.query.status;
    }

    // Add type filter
    if (req.query.type) {
      filter.type = req.query.type;
    }

    // Add search functionality
    if (req.query.search) {
      filter.$or = [
        { title: { $regex: req.query.search, $options: 'i' } },
        { message: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    const notifications = await Notification.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'name email')
      .select('-__v');

    const total = await Notification.countDocuments(filter);

    res.json({
      success: true,
      data: notifications,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get single notification
// @route   GET /api/notifications/:id
// @access  Private/Admin
const getNotification = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id)
      .populate('createdBy', 'name email')
      .populate('specificUsers', 'name email');

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      data: notification
    });
  } catch (error) {
    console.error('Get notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Create new notification
// @route   POST /api/notifications
// @access  Private/Admin
const createNotification = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const notificationData = {
      ...req.body,
      targetAudience: req.body.targetAudience ? JSON.parse(req.body.targetAudience) : ['all'],
      specificUsers: req.body.specificUsers ? JSON.parse(req.body.specificUsers) : [],
      categories: req.body.categories ? JSON.parse(req.body.categories) : [],
      tags: req.body.tags ? JSON.parse(req.body.tags) : [],
      actionButton: req.body.actionButton ? JSON.parse(req.body.actionButton) : undefined,
      metadata: {
        ...req.body.metadata,
        platform: req.body.platform || 'all'
      }
    };

    // Handle file upload if image provided
    if (req.file) {
      notificationData.image = `/uploads/${req.file.filename}`;
    }

    // Set status based on scheduled date
    if (notificationData.scheduledDate) {
      notificationData.status = 'scheduled';
    }

    const notification = await Notification.create(notificationData);

    res.status(201).json({
      success: true,
      data: notification,
      message: 'Notification created successfully'
    });
  } catch (error) {
    console.error('Create notification error:', error);

    // Delete uploaded file if notification creation fails
    if (req.file) {
      const fs = require('fs');
      const path = require('path');
      fs.unlinkSync(path.join(__dirname, '../uploads', req.file.filename));
    }

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update notification
// @route   PUT /api/notifications/:id
// @access  Private/Admin
const updateNotification = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    let updateData = { ...req.body };

    // Handle file upload if new image provided
    if (req.file) {
      updateData.image = `/uploads/${req.file.filename}`;

      // Delete old image file
      const oldNotification = await Notification.findById(req.params.id);
      if (oldNotification && oldNotification.image) {
        const fs = require('fs');
        const path = require('path');
        const oldImagePath = path.join(__dirname, '..', oldNotification.image);
        if (fs.existsSync(oldImagePath)) {
          fs.unlinkSync(oldImagePath);
        }
      }
    }

    // Parse JSON fields
    if (updateData.targetAudience) updateData.targetAudience = JSON.parse(updateData.targetAudience);
    if (updateData.specificUsers) updateData.specificUsers = JSON.parse(updateData.specificUsers);
    if (updateData.categories) updateData.categories = JSON.parse(updateData.categories);
    if (updateData.tags) updateData.tags = JSON.parse(updateData.tags);
    if (updateData.actionButton) updateData.actionButton = JSON.parse(updateData.actionButton);

    // Update status based on scheduled date
    if (updateData.scheduledDate && updateData.status === 'draft') {
      updateData.status = 'scheduled';
    }

    const notification = await Notification.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).populate('createdBy', 'name email');

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      data: notification,
      message: 'Notification updated successfully'
    });
  } catch (error) {
    console.error('Update notification error:', error);

    // Delete uploaded file if update fails
    if (req.file) {
      const fs = require('fs');
      const path = require('path');
      fs.unlinkSync(path.join(__dirname, '../uploads', req.file.filename));
    }

    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Delete notification
// @route   DELETE /api/notifications/:id
// @access  Private/Admin
const deleteNotification = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    // Don't allow deletion of sent notifications
    if (notification.status === 'sent') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete sent notifications'
      });
    }

    // Delete image file if exists
    if (notification.image) {
      const fs = require('fs');
      const path = require('path');
      const imagePath = path.join(__dirname, '..', notification.image);
      if (fs.existsSync(imagePath)) {
        fs.unlinkSync(imagePath);
      }
    }

    await Notification.findByIdAndDelete(req.params.id);

    res.json({
      success: true,
      message: 'Notification deleted successfully'
    });
  } catch (error) {
    console.error('Delete notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Send notification immediately
// @route   POST /api/notifications/:id/send
// @access  Private/Admin
const sendNotification = async (req, res) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    if (notification.status === 'sent') {
      return res.status(400).json({
        success: false,
        message: 'Notification has already been sent'
      });
    }

    // Update status to sending
    notification.status = 'sending';
    await notification.save();

    let sendResult;

    try {
      // Send push notification based on target audience
      sendResult = await pushNotificationService.sendByAudience(notification);

      // Update notification with delivery stats
      await notification.markAsSent(
        sendResult.totalSent || 0,
        sendResult.successCount || 0
      );

      // Update failure stats if any
      if (sendResult.failureCount > 0) {
        await notification.updateDeliveryStats(0, 0, sendResult.failureCount);
      }

      // Log the action
      await auditLogger.log({
        action: 'NOTIFICATION_SENT',
        resource: 'Notification',
        resourceId: notification._id,
        details: {
          title: notification.title,
          targetAudience: notification.targetAudience,
          totalSent: sendResult.totalSent,
          successCount: sendResult.successCount,
          failureCount: sendResult.failureCount
        },
        adminId: req.user?.id
      });

      res.json({
        success: true,
        data: notification,
        sendResult: {
          totalSent: sendResult.totalSent,
          successCount: sendResult.successCount,
          failureCount: sendResult.failureCount,
          simulated: sendResult.simulated || false
        },
        message: `Notification sent successfully${sendResult.simulated ? ' (simulated)' : ''}`
      });

    } catch (sendError) {
      console.error('Push notification send error:', sendError);
      
      // Mark notification as failed
      notification.status = 'failed';
      await notification.save();

      res.status(500).json({
        success: false,
        message: 'Failed to send push notification',
        error: process.env.NODE_ENV === 'development' ? sendError.message : undefined
      });
    }

  } catch (error) {
    console.error('Send notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get notification statistics
// @route   GET /api/notifications/stats
// @access  Private/Admin
const getNotificationStats = async (req, res) => {
  try {
    const stats = await Notification.getStats();

    const recentNotifications = await Notification.find({ status: 'sent' })
      .sort({ sentDate: -1 })
      .limit(10)
      .select('title type sentDate deliveryStats');

    const typeStats = await Notification.aggregate([
      { $match: { status: 'sent' } },
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 },
          totalSent: { $sum: '$deliveryStats.totalSent' },
          totalClicked: { $sum: '$deliveryStats.totalClicked' }
        }
      },
      { $sort: { count: -1 } }
    ]);

    res.json({
      success: true,
      data: {
        overview: stats,
        recentNotifications,
        typeStats
      }
    });
  } catch (error) {
    console.error('Get notification stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get notifications ready to send (for cron job)
// @route   GET /api/notifications/ready-to-send
// @access  Private/System
const getReadyToSend = async (req, res) => {
  try {
    const notifications = await Notification.findReadyToSend()
      .populate('specificUsers', 'name email')
      .limit(10); // Limit to prevent overwhelming the system

    res.json({
      success: true,
      data: notifications
    });
  } catch (error) {
    console.error('Get ready to send notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Send test notification
// @route   POST /api/notifications/test
// @access  Private/Admin
const sendTestNotification = async (req, res) => {
  try {
    const { title, message, deviceTokens, topic } = req.body;

    if (!title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Title and message are required'
      });
    }

    const testNotification = {
      title,
      message,
      type: 'info',
      priority: 'normal'
    };

    let sendResult;

    if (topic) {
      // Send to topic
      sendResult = await pushNotificationService.sendToTopic(topic, testNotification);
    } else if (deviceTokens && deviceTokens.length > 0) {
      // Send to specific devices
      sendResult = await pushNotificationService.sendToDevices(deviceTokens, testNotification);
    } else {
      // Send to all users
      sendResult = await pushNotificationService.sendByAudience({
        ...testNotification,
        targetAudience: ['all']
      });
    }

    // Log the test action
    await auditLogger.log({
      action: 'TEST_NOTIFICATION_SENT',
      resource: 'Notification',
      details: {
        title,
        message,
        target: topic ? `topic:${topic}` : (deviceTokens ? 'specific_devices' : 'all_users'),
        result: sendResult
      },
      adminId: req.user?.id
    });

    res.json({
      success: true,
      sendResult,
      message: `Test notification sent${sendResult.simulated ? ' (simulated)' : ''}`
    });

  } catch (error) {
    console.error('Send test notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getNotifications,
  getNotification,
  createNotification,
  updateNotification,
  deleteNotification,
  sendNotification,
  sendTestNotification,
  getNotificationStats,
  getReadyToSend
};

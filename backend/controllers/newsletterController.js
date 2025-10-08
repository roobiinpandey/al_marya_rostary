const Newsletter = require('../models/Newsletter');
const { validationResult } = require('express-validator');
const emailService = require('../services/emailService');
const auditLogger = require('../utils/auditLogger');

// @desc    Get all newsletters
// @route   GET /api/newsletters
// @access  Private/Admin
const getNewsletters = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = {};

    // Add status filter
    if (req.query.status) {
      filter.status = req.query.status;
    }

    // Add campaign type filter
    if (req.query.campaignType) {
      filter['metadata.campaignType'] = req.query.campaignType;
    }

    // Add search functionality
    if (req.query.search) {
      filter.$or = [
        { title: { $regex: req.query.search, $options: 'i' } },
        { subject: { $regex: req.query.search, $options: 'i' } }
      ];
    }

    const newsletters = await Newsletter.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'name email')
      .select('-content.html'); // Exclude HTML content in list view

    const total = await Newsletter.countDocuments(filter);

    res.json({
      success: true,
      data: newsletters,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get newsletters error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get single newsletter
// @route   GET /api/newsletters/:id
// @access  Private/Admin
const getNewsletter = async (req, res) => {
  try {
    const newsletter = await Newsletter.findById(req.params.id)
      .populate('createdBy', 'name email');

    if (!newsletter) {
      return res.status(404).json({
        success: false,
        message: 'Newsletter not found'
      });
    }

    res.json({
      success: true,
      data: newsletter
    });
  } catch (error) {
    console.error('Get newsletter error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Create new newsletter
// @route   POST /api/newsletters
// @access  Private/Admin
const createNewsletter = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const newsletterData = {
      ...req.body,
      targetAudience: req.body.targetAudience ? JSON.parse(req.body.targetAudience) : ['all'],
      recipientEmails: req.body.recipientEmails ? JSON.parse(req.body.recipientEmails) : [],
      tags: req.body.tags ? JSON.parse(req.body.tags) : [],
      createdBy: req.user.id,
      content: {
        html: req.body.htmlContent,
        text: req.body.textContent || ''
      },
      metadata: {
        campaignType: req.body.campaignType || 'newsletter',
        priority: req.body.priority || 'normal',
        testEmails: req.body.testEmails ? JSON.parse(req.body.testEmails) : []
      }
    };

    // Set status based on scheduled date
    if (newsletterData.scheduledDate) {
      newsletterData.status = 'scheduled';
    }

    const newsletter = await Newsletter.create(newsletterData);

    // Log the action
    await auditLogger.log({
      action: 'NEWSLETTER_CREATED',
      resource: 'Newsletter',
      resourceId: newsletter._id,
      details: {
        title: newsletter.title,
        subject: newsletter.subject,
        targetAudience: newsletter.targetAudience,
        status: newsletter.status
      },
      adminId: req.user.id
    });

    res.status(201).json({
      success: true,
      data: newsletter,
      message: 'Newsletter created successfully'
    });
  } catch (error) {
    console.error('Create newsletter error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update newsletter
// @route   PUT /api/newsletters/:id
// @access  Private/Admin
const updateNewsletter = async (req, res) => {
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

    // Parse JSON fields
    if (updateData.targetAudience) updateData.targetAudience = JSON.parse(updateData.targetAudience);
    if (updateData.recipientEmails) updateData.recipientEmails = JSON.parse(updateData.recipientEmails);
    if (updateData.tags) updateData.tags = JSON.parse(updateData.tags);
    if (updateData.testEmails) updateData.metadata = { ...updateData.metadata, testEmails: JSON.parse(updateData.testEmails) };

    // Handle content update
    if (updateData.htmlContent || updateData.textContent) {
      updateData.content = {
        html: updateData.htmlContent,
        text: updateData.textContent || ''
      };
      delete updateData.htmlContent;
      delete updateData.textContent;
    }

    // Update status based on scheduled date
    if (updateData.scheduledDate && updateData.status === 'draft') {
      updateData.status = 'scheduled';
    }

    const newsletter = await Newsletter.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).populate('createdBy', 'name email');

    if (!newsletter) {
      return res.status(404).json({
        success: false,
        message: 'Newsletter not found'
      });
    }

    // Log the action
    await auditLogger.log({
      action: 'NEWSLETTER_UPDATED',
      resource: 'Newsletter',
      resourceId: newsletter._id,
      details: {
        title: newsletter.title,
        subject: newsletter.subject,
        status: newsletter.status
      },
      adminId: req.user.id
    });

    res.json({
      success: true,
      data: newsletter,
      message: 'Newsletter updated successfully'
    });
  } catch (error) {
    console.error('Update newsletter error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Delete newsletter
// @route   DELETE /api/newsletters/:id
// @access  Private/Admin
const deleteNewsletter = async (req, res) => {
  try {
    const newsletter = await Newsletter.findById(req.params.id);

    if (!newsletter) {
      return res.status(404).json({
        success: false,
        message: 'Newsletter not found'
      });
    }

    // Don't allow deletion of sent newsletters
    if (newsletter.status === 'sent') {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete sent newsletters'
      });
    }

    await Newsletter.findByIdAndDelete(req.params.id);

    // Log the action
    await auditLogger.log({
      action: 'NEWSLETTER_DELETED',
      resource: 'Newsletter',
      resourceId: req.params.id,
      details: {
        title: newsletter.title,
        subject: newsletter.subject
      },
      adminId: req.user.id
    });

    res.json({
      success: true,
      message: 'Newsletter deleted successfully'
    });
  } catch (error) {
    console.error('Delete newsletter error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Send newsletter immediately
// @route   POST /api/newsletters/:id/send
// @access  Private/Admin
const sendNewsletter = async (req, res) => {
  try {
    const newsletter = await Newsletter.findById(req.params.id);

    if (!newsletter) {
      return res.status(404).json({
        success: false,
        message: 'Newsletter not found'
      });
    }

    if (newsletter.status === 'sent') {
      return res.status(400).json({
        success: false,
        message: 'Newsletter has already been sent'
      });
    }

    // Update status to sending
    newsletter.status = 'sending';
    await newsletter.save();

    try {
      // Send newsletter
      const sendResult = await emailService.sendNewsletter({
        subject: newsletter.subject,
        html: newsletter.content.html,
        text: newsletter.content.text,
        targetAudience: newsletter.targetAudience,
        recipientEmails: newsletter.recipientEmails
      });

      // Update newsletter with delivery stats
      await newsletter.markAsSent(
        sendResult.totalSent || 0,
        sendResult.successCount || 0,
        sendResult.failureCount || 0
      );

      // Log the action
      await auditLogger.log({
        action: 'NEWSLETTER_SENT',
        resource: 'Newsletter',
        resourceId: newsletter._id,
        details: {
          title: newsletter.title,
          subject: newsletter.subject,
          targetAudience: newsletter.targetAudience,
          totalSent: sendResult.totalSent,
          successCount: sendResult.successCount,
          failureCount: sendResult.failureCount
        },
        adminId: req.user?.id
      });

      res.json({
        success: true,
        data: newsletter,
        sendResult: {
          totalSent: sendResult.totalSent,
          successCount: sendResult.successCount,
          failureCount: sendResult.failureCount,
          simulated: sendResult.simulated || false
        },
        message: `Newsletter sent successfully${sendResult.simulated ? ' (simulated)' : ''}`
      });

    } catch (sendError) {
      console.error('Newsletter send error:', sendError);
      
      // Mark newsletter as failed
      newsletter.status = 'failed';
      await newsletter.save();

      res.status(500).json({
        success: false,
        message: 'Failed to send newsletter',
        error: process.env.NODE_ENV === 'development' ? sendError.message : undefined
      });
    }

  } catch (error) {
    console.error('Send newsletter error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Send test newsletter
// @route   POST /api/newsletters/:id/test
// @access  Private/Admin
const sendTestNewsletter = async (req, res) => {
  try {
    const { testEmails } = req.body;
    
    if (!testEmails || testEmails.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Test email addresses are required'
      });
    }

    const newsletter = await Newsletter.findById(req.params.id);

    if (!newsletter) {
      return res.status(404).json({
        success: false,
        message: 'Newsletter not found'
      });
    }

    // Send test newsletter
    const sendResult = await emailService.sendNewsletter({
      subject: `[TEST] ${newsletter.subject}`,
      html: newsletter.content.html,
      text: newsletter.content.text,
      recipientEmails: testEmails
    });

    // Log the action
    await auditLogger.log({
      action: 'NEWSLETTER_TEST_SENT',
      resource: 'Newsletter',
      resourceId: newsletter._id,
      details: {
        title: newsletter.title,
        testEmails: testEmails,
        result: sendResult
      },
      adminId: req.user.id
    });

    res.json({
      success: true,
      sendResult,
      message: `Test newsletter sent to ${testEmails.length} recipient(s)${sendResult.simulated ? ' (simulated)' : ''}`
    });

  } catch (error) {
    console.error('Send test newsletter error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get newsletter statistics
// @route   GET /api/newsletters/stats
// @access  Private/Admin
const getNewsletterStats = async (req, res) => {
  try {
    const stats = await Newsletter.getStats();

    const recentNewsletters = await Newsletter.find({ status: 'sent' })
      .sort({ sentDate: -1 })
      .limit(10)
      .select('title subject sentDate deliveryStats')
      .populate('createdBy', 'name');

    const campaignTypeStats = await Newsletter.aggregate([
      { $match: { status: 'sent' } },
      {
        $group: {
          _id: '$metadata.campaignType',
          count: { $sum: 1 },
          totalSent: { $sum: '$deliveryStats.totalSent' },
          totalSuccessful: { $sum: '$deliveryStats.successCount' }
        }
      },
      { $sort: { count: -1 } }
    ]);

    res.json({
      success: true,
      data: {
        overview: stats,
        recentNewsletters,
        campaignTypeStats
      }
    });
  } catch (error) {
    console.error('Get newsletter stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get newsletters ready to send (for cron job)
// @route   GET /api/newsletters/ready-to-send
// @access  Private/System
const getReadyToSend = async (req, res) => {
  try {
    const newsletters = await Newsletter.findReadyToSend()
      .limit(5); // Limit to prevent overwhelming the system

    res.json({
      success: true,
      data: newsletters
    });
  } catch (error) {
    console.error('Get ready to send newsletters error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getNewsletters,
  getNewsletter,
  createNewsletter,
  updateNewsletter,
  deleteNewsletter,
  sendNewsletter,
  sendTestNewsletter,
  getNewsletterStats,
  getReadyToSend
};

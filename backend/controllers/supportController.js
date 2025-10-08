const SupportTicket = require('../models/SupportTicket');
const { validationResult } = require('express-validator');
const emailService = require('../services/emailService');
const auditLogger = require('../utils/auditLogger');

// @desc    Get all support tickets
// @route   GET /api/support-tickets
// @access  Private/Admin
const getSupportTickets = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const filter = {};

    // Add filters
    if (req.query.status) {
      filter.status = req.query.status;
    }

    if (req.query.priority) {
      filter.priority = req.query.priority;
    }

    if (req.query.category) {
      filter.category = req.query.category;
    }

    if (req.query.assignedTo) {
      filter.assignedTo = req.query.assignedTo;
    }

    // Add search functionality
    if (req.query.search) {
      filter.$or = [
        { title: { $regex: req.query.search, $options: 'i' } },
        { ticketNumber: { $regex: req.query.search, $options: 'i' } },
        { 'guestInfo.email': { $regex: req.query.search, $options: 'i' } }
      ];
    }

    const tickets = await SupportTicket.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('customer', 'name email')
      .populate('assignedTo', 'name email')
      .populate('relatedOrder', 'orderNumber totalAmount')
      .select('-messages'); // Exclude messages in list view for performance

    const total = await SupportTicket.countDocuments(filter);

    res.json({
      success: true,
      data: tickets,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get support tickets error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get single support ticket
// @route   GET /api/support-tickets/:id
// @access  Private/Admin
const getSupportTicket = async (req, res) => {
  try {
    const ticket = await SupportTicket.findById(req.params.id)
      .populate('customer', 'name email phone')
      .populate('assignedTo', 'name email')
      .populate('relatedOrder', 'orderNumber totalAmount status items')
      .populate('messages.sender', 'name email')
      .populate('resolution.resolvedBy', 'name email');

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Support ticket not found'
      });
    }

    res.json({
      success: true,
      data: ticket
    });
  } catch (error) {
    console.error('Get support ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Create new support ticket
// @route   POST /api/support-tickets
// @access  Public
const createSupportTicket = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const ticketData = {
      title: req.body.title,
      description: req.body.description,
      category: req.body.category || 'general',
      priority: req.body.priority || 'normal',
      tags: req.body.tags ? JSON.parse(req.body.tags) : [],
      relatedOrder: req.body.relatedOrder || null,
      metadata: {
        source: req.body.source || 'web',
        userAgent: req.get('User-Agent'),
        ipAddress: req.ip
      }
    };

    // Handle customer info
    if (req.user) {
      // Authenticated user
      ticketData.customer = req.user.id;
    } else {
      // Guest user
      ticketData.guestInfo = {
        name: req.body.guestName,
        email: req.body.guestEmail,
        phone: req.body.guestPhone
      };
    }

    // Add initial message
    const initialMessage = {
      sender: req.user?.id || null,
      senderType: 'customer',
      message: req.body.description
    };

    // Handle file attachments if any
    if (req.files && req.files.length > 0) {
      initialMessage.attachments = req.files.map(file => ({
        filename: file.filename,
        originalName: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
        path: file.path
      }));
    }

    const ticket = await SupportTicket.create(ticketData);
    
    // Add the initial message
    await ticket.addMessage(initialMessage);

    // Send confirmation email
    const customerEmail = req.user?.email || req.body.guestEmail;
    const customerName = req.user?.name || req.body.guestName;

    if (customerEmail) {
      try {
        await emailService.sendEmail({
          to: customerEmail,
          subject: `Support Ticket Created - ${ticket.ticketNumber}`,
          html: `
            <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
              <h1 style="color: #8B4513;">Qahwat Al Emarat Support</h1>
              <h2>Support Ticket Created</h2>
              <p>Dear ${customerName},</p>
              <p>Your support ticket has been created successfully. Here are the details:</p>
              <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
                <p><strong>Ticket Number:</strong> ${ticket.ticketNumber}</p>
                <p><strong>Title:</strong> ${ticket.title}</p>
                <p><strong>Category:</strong> ${ticket.category}</p>
                <p><strong>Priority:</strong> ${ticket.priority}</p>
              </div>
              <p>We'll respond to your ticket as soon as possible. You can track the status of your ticket using the ticket number above.</p>
              <p>Thank you for contacting Qahwat Al Emarat support!</p>
            </div>
          `
        });
      } catch (emailError) {
        console.error('Failed to send ticket confirmation email:', emailError);
      }
    }

    // Log the action
    await auditLogger.log({
      action: 'SUPPORT_TICKET_CREATED',
      resource: 'SupportTicket',
      resourceId: ticket._id,
      details: {
        ticketNumber: ticket.ticketNumber,
        title: ticket.title,
        category: ticket.category,
        customer: req.user?.id || 'guest'
      },
      adminId: req.user?.id
    });

    res.status(201).json({
      success: true,
      data: ticket,
      message: 'Support ticket created successfully'
    });
  } catch (error) {
    console.error('Create support ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Update support ticket
// @route   PUT /api/support-tickets/:id
// @access  Private/Admin
const updateSupportTicket = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation errors',
        errors: errors.array()
      });
    }

    const updateData = {};
    
    // Allow updating specific fields
    if (req.body.title) updateData.title = req.body.title;
    if (req.body.category) updateData.category = req.body.category;
    if (req.body.priority) updateData.priority = req.body.priority;
    if (req.body.status) updateData.status = req.body.status;
    if (req.body.assignedTo !== undefined) updateData.assignedTo = req.body.assignedTo;
    if (req.body.tags) updateData.tags = JSON.parse(req.body.tags);

    const ticket = await SupportTicket.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    ).populate('customer', 'name email')
     .populate('assignedTo', 'name email');

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Support ticket not found'
      });
    }

    // Log the action
    await auditLogger.log({
      action: 'SUPPORT_TICKET_UPDATED',
      resource: 'SupportTicket',
      resourceId: ticket._id,
      details: {
        ticketNumber: ticket.ticketNumber,
        changes: updateData
      },
      adminId: req.user.id
    });

    res.json({
      success: true,
      data: ticket,
      message: 'Support ticket updated successfully'
    });
  } catch (error) {
    console.error('Update support ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Add message to support ticket
// @route   POST /api/support-tickets/:id/messages
// @access  Private/Admin or Customer (owner)
const addTicketMessage = async (req, res) => {
  try {
    const { message, isInternal } = req.body;

    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Message content is required'
      });
    }

    const ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Support ticket not found'
      });
    }

    // Check permissions
    const isAdmin = req.user.role === 'admin';
    const isCustomer = ticket.customer && ticket.customer.toString() === req.user.id;

    if (!isAdmin && !isCustomer) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const messageData = {
      sender: req.user.id,
      senderType: isAdmin ? 'admin' : 'customer',
      message: message.trim(),
      isInternal: isAdmin ? (isInternal || false) : false
    };

    // Handle file attachments if any
    if (req.files && req.files.length > 0) {
      messageData.attachments = req.files.map(file => ({
        filename: file.filename,
        originalName: file.originalname,
        mimetype: file.mimetype,
        size: file.size,
        path: file.path
      }));
    }

    await ticket.addMessage(messageData);

    // Send email notification to the other party
    if (!messageData.isInternal) {
      try {
        if (isAdmin && ticket.customer) {
          // Admin replied to customer
          const customer = await ticket.populate('customer', 'name email');
          await emailService.sendEmail({
            to: customer.customer.email,
            subject: `Update on Support Ticket ${ticket.ticketNumber}`,
            html: `
              <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
                <h1 style="color: #8B4513;">Qahwat Al Emarat Support</h1>
                <h2>Ticket Update</h2>
                <p>Dear ${customer.customer.name},</p>
                <p>There's a new update on your support ticket <strong>${ticket.ticketNumber}</strong>:</p>
                <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
                  <p><strong>Message:</strong></p>
                  <p>${message}</p>
                </div>
                <p>You can view the full conversation and reply to this ticket in your account.</p>
              </div>
            `
          });
        } else if (!isAdmin) {
          // Customer replied - notify assigned admin or all admins
          // This would typically notify the assigned admin or support team
          console.log(`Customer replied to ticket ${ticket.ticketNumber}`);
        }
      } catch (emailError) {
        console.error('Failed to send ticket update email:', emailError);
      }
    }

    // Log the action
    await auditLogger.log({
      action: 'TICKET_MESSAGE_ADDED',
      resource: 'SupportTicket',
      resourceId: ticket._id,
      details: {
        ticketNumber: ticket.ticketNumber,
        messageType: messageData.senderType,
        isInternal: messageData.isInternal
      },
      adminId: req.user.id
    });

    const updatedTicket = await SupportTicket.findById(req.params.id)
      .populate('messages.sender', 'name email');

    res.json({
      success: true,
      data: updatedTicket,
      message: 'Message added successfully'
    });
  } catch (error) {
    console.error('Add ticket message error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Assign support ticket
// @route   POST /api/support-tickets/:id/assign
// @access  Private/Admin
const assignSupportTicket = async (req, res) => {
  try {
    const { assignedTo } = req.body;

    const ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Support ticket not found'
      });
    }

    await ticket.assignTo(assignedTo);

    // Log the action
    await auditLogger.log({
      action: 'TICKET_ASSIGNED',
      resource: 'SupportTicket',
      resourceId: ticket._id,
      details: {
        ticketNumber: ticket.ticketNumber,
        assignedTo: assignedTo
      },
      adminId: req.user.id
    });

    const updatedTicket = await SupportTicket.findById(req.params.id)
      .populate('assignedTo', 'name email');

    res.json({
      success: true,
      data: updatedTicket,
      message: 'Ticket assigned successfully'
    });
  } catch (error) {
    console.error('Assign support ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Resolve support ticket
// @route   POST /api/support-tickets/:id/resolve
// @access  Private/Admin
const resolveSupportTicket = async (req, res) => {
  try {
    const { summary, feedback } = req.body;

    if (!summary || summary.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Resolution summary is required'
      });
    }

    const ticket = await SupportTicket.findById(req.params.id);

    if (!ticket) {
      return res.status(404).json({
        success: false,
        message: 'Support ticket not found'
      });
    }

    await ticket.resolve({
      summary: summary.trim(),
      resolvedBy: req.user.id,
      feedback: feedback?.trim()
    });

    // Send resolution email to customer
    const customerEmail = ticket.customer?.email || ticket.guestInfo?.email;
    const customerName = ticket.customer?.name || ticket.guestInfo?.name;

    if (customerEmail) {
      try {
        await emailService.sendEmail({
          to: customerEmail,
          subject: `Support Ticket Resolved - ${ticket.ticketNumber}`,
          html: `
            <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
              <h1 style="color: #8B4513;">Qahwat Al Emarat Support</h1>
              <h2>Ticket Resolved</h2>
              <p>Dear ${customerName},</p>
              <p>Your support ticket <strong>${ticket.ticketNumber}</strong> has been resolved.</p>
              <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
                <p><strong>Resolution Summary:</strong></p>
                <p>${summary}</p>
              </div>
              <p>If you're satisfied with the resolution, no further action is needed. If you have any additional questions or concerns, please reply to this email or create a new support ticket.</p>
              <p>Thank you for choosing Qahwat Al Emarat!</p>
            </div>
          `
        });
      } catch (emailError) {
        console.error('Failed to send resolution email:', emailError);
      }
    }

    // Log the action
    await auditLogger.log({
      action: 'TICKET_RESOLVED',
      resource: 'SupportTicket',
      resourceId: ticket._id,
      details: {
        ticketNumber: ticket.ticketNumber,
        summary: summary
      },
      adminId: req.user.id
    });

    const updatedTicket = await SupportTicket.findById(req.params.id)
      .populate('resolution.resolvedBy', 'name email');

    res.json({
      success: true,
      data: updatedTicket,
      message: 'Ticket resolved successfully'
    });
  } catch (error) {
    console.error('Resolve support ticket error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// @desc    Get support ticket statistics
// @route   GET /api/support-tickets/stats
// @access  Private/Admin
const getSupportTicketStats = async (req, res) => {
  try {
    const stats = await SupportTicket.getStats();

    const recentTickets = await SupportTicket.find({})
      .sort({ createdAt: -1 })
      .limit(10)
      .populate('customer', 'name email')
      .populate('assignedTo', 'name')
      .select('ticketNumber title status priority category createdAt');

    const overdueTickets = await SupportTicket.findOverdue();

    res.json({
      success: true,
      data: {
        overview: stats.overview,
        priorityBreakdown: stats.priorityBreakdown,
        categoryBreakdown: stats.categoryBreakdown,
        recentTickets,
        overdueTickets: overdueTickets.length,
        overdueList: overdueTickets.slice(0, 5) // Top 5 overdue tickets
      }
    });
  } catch (error) {
    console.error('Get support ticket stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

module.exports = {
  getSupportTickets,
  getSupportTicket,
  createSupportTicket,
  updateSupportTicket,
  addTicketMessage,
  assignSupportTicket,
  resolveSupportTicket,
  getSupportTicketStats
};

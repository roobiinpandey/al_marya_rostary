const express = require('express');
const router = express.Router();
const emailService = require('../services/emailService');
const enhancedEmailService = require('../services/enhancedEmailService');
const { protect, authorize } = require('../middleware/auth');

/**
 * Test basic email configuration
 * GET /api/test/email-config
 */
router.get('/email-config', protect, authorize('admin'), async (req, res) => {
  try {
    const config = {
      smtp_host: process.env.SMTP_HOST || 'Not configured',
      smtp_port: process.env.SMTP_PORT || 'Not configured',
      smtp_user: process.env.SMTP_USER || 'Not configured',
      smtp_pass_configured: !!process.env.SMTP_PASS && process.env.SMTP_PASS !== 'your-gmail-app-password-here',
      email_provider: process.env.EMAIL_PROVIDER || 'gmail (default)',
      from_name: process.env.EMAIL_FROM_NAME || 'Not configured',
      from_address: process.env.EMAIL_FROM_ADDRESS || 'Not configured'
    };

    res.json({
      success: true,
      message: 'Email configuration retrieved',
      config,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve email configuration',
      error: error.message
    });
  }
});

/**
 * Test email sending
 * POST /api/test/send-email
 * Body: { to: "email@example.com", service: "original|enhanced" }
 */
router.post('/send-email', protect, authorize('admin'), async (req, res) => {
  try {
    const { to, service = 'enhanced' } = req.body;
    
    if (!to) {
      return res.status(400).json({
        success: false,
        message: 'Email address is required'
      });
    }

    const serviceToUse = service === 'enhanced' ? enhancedEmailService : emailService;
    
    const result = await serviceToUse.sendTestEmail(to);

    res.json({
      success: true,
      message: 'Test email sent',
      result,
      service_used: service,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to send test email',
      error: error.message
    });
  }
});

/**
 * Get enhanced email service status
 * GET /api/test/email-status
 */
router.get('/email-status', protect, authorize('admin'), async (req, res) => {
  try {
    const status = enhancedEmailService.getStatus();
    
    res.json({
      success: true,
      message: 'Email service status retrieved',
      status,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get email service status',
      error: error.message
    });
  }
});

/**
 * Test email verification process
 * POST /api/test/email-verification
 * Body: { email: "test@example.com", name: "Test User" }
 */
router.post('/email-verification', protect, authorize('admin'), async (req, res) => {
  try {
    const { email, name = 'Test User' } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email address is required'
      });
    }

    const verificationToken = 'test-token-' + Date.now();
    
    const result = await enhancedEmailService.sendEmailVerification(email, name, verificationToken);

    res.json({
      success: true,
      message: 'Email verification test sent',
      result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to send email verification test',
      error: error.message
    });
  }
});

/**
 * Test password reset email
 * POST /api/test/password-reset
 * Body: { email: "test@example.com", name: "Test User" }
 */
router.post('/password-reset', protect, authorize('admin'), async (req, res) => {
  try {
    const { email, name = 'Test User' } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email address is required'
      });
    }

    const resetToken = 'test-reset-token-' + Date.now();
    
    const result = await enhancedEmailService.sendPasswordReset(email, name, resetToken);

    res.json({
      success: true,
      message: 'Password reset test sent',
      result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to send password reset test',
      error: error.message
    });
  }
});

/**
 * Reinitialize email service
 * POST /api/test/reinit-email
 */
router.post('/reinit-email', protect, authorize('admin'), async (req, res) => {
  try {
    await enhancedEmailService.initializeService();
    const status = enhancedEmailService.getStatus();
    
    res.json({
      success: true,
      message: 'Email service reinitialized',
      status,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to reinitialize email service',
      error: error.message
    });
  }
});

/**
 * Test newsletter functionality
 * POST /api/test/newsletter
 * Body: { emails: ["test1@example.com", "test2@example.com"] }
 */
router.post('/newsletter', protect, authorize('admin'), async (req, res) => {
  try {
    const { emails = [] } = req.body;
    
    if (!emails.length) {
      return res.status(400).json({
        success: false,
        message: 'At least one email address is required'
      });
    }

    const newsletterData = {
      subject: 'Test Newsletter - Al Marya Rostery',
      html: `
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
          <h1 style="color: #A89A6A;">Al Marya Rostery Newsletter Test</h1>
          <p>This is a test newsletter to verify the email service functionality.</p>
          <p><strong>Timestamp:</strong> ${new Date().toISOString()}</p>
          <p>If you received this email, the newsletter system is working correctly!</p>
        </div>
      `,
      recipientEmails: emails
    };
    
    const result = await enhancedEmailService.sendNewsletter(newsletterData);

    res.json({
      success: true,
      message: 'Newsletter test completed',
      result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to send newsletter test',
      error: error.message
    });
  }
});

module.exports = router;

const nodemailer = require('nodemailer');
const User = require('../models/User');
const auditLogger = require('../utils/auditLogger');

class EnhancedEmailService {
  constructor() {
    this.transporter = null;
    this.isConfigured = false;
    this.provider = 'gmail'; // default
    this.initializeService();
  }

  /**
   * Initialize email service with multiple provider support
   */
  async initializeService() {
    try {
      const provider = process.env.EMAIL_PROVIDER || 'gmail';
      
      switch (provider.toLowerCase()) {
        case 'gmail':
          await this.initializeGmail();
          break;
        case 'oauth2':
          await this.initializeGmailOAuth2();
          break;
        case 'sendgrid':
          await this.initializeSendGrid();
          break;
        case 'ses':
          await this.initializeAWSSES();
          break;
        default:
          console.warn(`⚠️  Unknown email provider: ${provider}. Falling back to Gmail.`);
          await this.initializeGmail();
      }
    } catch (error) {
      console.error('❌ Email service initialization failed:', error.message);
      this.fallbackToSimulation();
    }
  }

  /**
   * Initialize Gmail with App Password
   */
  async initializeGmail() {
    const config = {
      host: process.env.SMTP_HOST || 'smtp.gmail.com',
      port: parseInt(process.env.SMTP_PORT) || 587,
      secure: process.env.SMTP_SECURE === 'true',
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS
      },
      tls: {
        rejectUnauthorized: false // For development
      }
    };

    if (!config.auth.user || !config.auth.pass || config.auth.pass === 'your-gmail-app-password-here') {
      throw new Error('Gmail credentials not configured. Please set SMTP_USER and SMTP_PASS in .env file.');
    }

    this.transporter = nodemailer.createTransport(config);
    this.provider = 'gmail';
    
    await this.verifyConnection();
  }

  /**
   * Initialize Gmail with OAuth2
   */
  async initializeGmailOAuth2() {
    const config = {
      service: 'gmail',
      auth: {
        type: 'OAuth2',
        user: process.env.GMAIL_USER,
        clientId: process.env.GMAIL_CLIENT_ID,
        clientSecret: process.env.GMAIL_CLIENT_SECRET,
        refreshToken: process.env.GMAIL_REFRESH_TOKEN
      }
    };

    if (!config.auth.user || !config.auth.clientId || !config.auth.clientSecret || !config.auth.refreshToken) {
      throw new Error('Gmail OAuth2 credentials not configured.');
    }

    this.transporter = nodemailer.createTransport(config);
    this.provider = 'oauth2';
    
    await this.verifyConnection();
  }

  /**
   * Initialize SendGrid
   */
  async initializeSendGrid() {
    const sgMail = require('@sendgrid/mail');
    
    if (!process.env.SENDGRID_API_KEY) {
      throw new Error('SendGrid API key not configured.');
    }

    sgMail.setApiKey(process.env.SENDGRID_API_KEY);
    
    // Create a custom transporter for SendGrid
    this.transporter = {
      sendMail: async (mailOptions) => {
        const msg = {
          to: mailOptions.to,
          from: mailOptions.from.address || mailOptions.from,
          subject: mailOptions.subject,
          html: mailOptions.html,
          text: mailOptions.text
        };
        
        return await sgMail.send(msg);
      }
    };
    
    this.provider = 'sendgrid';
    this.isConfigured = true;
    console.log('✅ SendGrid email service configured');
  }

  /**
   * Initialize AWS SES
   */
  async initializeAWSSES() {
    const AWS = require('aws-sdk');
    
    if (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY) {
      throw new Error('AWS SES credentials not configured.');
    }

    AWS.config.update({
      accessKeyId: process.env.AWS_ACCESS_KEY_ID,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
      region: process.env.AWS_REGION || 'us-east-1'
    });

    this.transporter = nodemailer.createTransport({
      SES: new AWS.SES({ apiVersion: '2010-12-01' })
    });

    this.provider = 'ses';
    await this.verifyConnection();
  }

  /**
   * Verify email connection
   */
  async verifyConnection() {
    try {
      if (this.transporter && this.transporter.verify) {
        await this.transporter.verify();
        this.isConfigured = true;
        console.log(`✅ ${this.provider.toUpperCase()} email service verified successfully`);
      } else {
        this.isConfigured = true;
        console.log(`✅ ${this.provider.toUpperCase()} email service configured`);
      }
    } catch (error) {
      console.warn(`⚠️  ${this.provider.toUpperCase()} verification failed:`, error.message);
      
      // Try to fallback to another provider
      await this.attemptFallback(error);
    }
  }

  /**
   * Attempt fallback to another email provider
   */
  async attemptFallback(originalError) {
    console.log('🔄 Attempting fallback email providers...');
    
    const fallbackProviders = ['sendgrid', 'ses'];
    
    for (const provider of fallbackProviders) {
      try {
        console.log(`🔄 Trying ${provider.toUpperCase()}...`);
        
        if (provider === 'sendgrid' && process.env.SENDGRID_API_KEY) {
          await this.initializeSendGrid();
          return;
        }
        
        if (provider === 'ses' && process.env.AWS_ACCESS_KEY_ID) {
          await this.initializeAWSSES();
          return;
        }
      } catch (error) {
        console.warn(`❌ ${provider.toUpperCase()} fallback failed:`, error.message);
      }
    }
    
    console.warn('⚠️  All email providers failed. Using simulation mode.');
    console.warn('Original error:', originalError.message);
    this.fallbackToSimulation();
  }

  /**
   * Fallback to simulation mode
   */
  fallbackToSimulation() {
    this.isConfigured = false;
    this.provider = 'simulation';
    console.log('📧 Email service will run in simulation mode');
  }

  /**
   * Send email with retry mechanism
   */
  async sendEmail(emailData, retryCount = 0) {
    const maxRetries = 3;
    
    try {
      if (!this.isConfigured) {
        return this.simulateEmailSend(emailData);
      }

      const mailOptions = this.buildMailOptions(emailData);
      const result = await this.transporter.sendMail(mailOptions);

      console.log(`📧 Email sent via ${this.provider.toUpperCase()} to ${emailData.to}: ${result.messageId || 'Success'}`);
      
      return {
        success: true,
        messageId: result.messageId || 'sent',
        recipient: emailData.to,
        provider: this.provider
      };

    } catch (error) {
      console.error(`❌ Email send error (${this.provider}):`, error.message);
      
      // Retry logic
      if (retryCount < maxRetries) {
        console.log(`🔄 Retrying email send... (${retryCount + 1}/${maxRetries})`);
        await this.delay(1000 * (retryCount + 1)); // Exponential backoff
        return this.sendEmail(emailData, retryCount + 1);
      }
      
      // Try fallback provider
      if (this.provider !== 'simulation') {
        console.log('🔄 Attempting fallback for failed email...');
        await this.attemptFallback(error);
        
        if (this.isConfigured) {
          return this.sendEmail(emailData, 0); // Reset retry count for new provider
        }
      }
      
      return {
        success: false,
        error: error.message,
        recipient: emailData.to,
        provider: this.provider
      };
    }
  }

  /**
   * Build mail options for different providers
   */
  buildMailOptions(emailData) {
    const { to, subject, html, text, attachments } = emailData;
    
    return {
      from: {
        name: process.env.EMAIL_FROM_NAME || 'Al Marya Rostery',
        address: process.env.EMAIL_FROM_ADDRESS || process.env.SMTP_USER
      },
      to,
      subject,
      html,
      text: text || this.stripHtml(html),
      attachments
    };
  }

  /**
   * Send test email to verify configuration
   */
  async sendTestEmail(to = process.env.SMTP_USER) {
    const testEmailData = {
      to,
      subject: 'Al Marya Rostery - Email Service Test',
      html: `
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
          <h1 style="color: #A89A6A;">Al Marya Rostery</h1>
          <h2>Email Service Test</h2>
          <p>This is a test email to verify the email service configuration.</p>
          <p><strong>Provider:</strong> ${this.provider.toUpperCase()}</p>
          <p><strong>Timestamp:</strong> ${new Date().toISOString()}</p>
          <p><strong>Status:</strong> ✅ Email service is working correctly!</p>
        </div>
      `
    };

    return await this.sendEmail(testEmailData);
  }

  /**
   * Get service status
   */
  getStatus() {
    return {
      configured: this.isConfigured,
      provider: this.provider,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Simulate email sending for development/testing
   */
  async simulateEmailSend(emailData) {
    console.log('📧 Simulating email send...');
    console.log(`Provider: SIMULATION`);
    console.log(`To: ${emailData.to}`);
    console.log(`Subject: ${emailData.subject}`);
    console.log(`Content Preview: ${(emailData.html || emailData.text).substring(0, 100)}...`);

    // Simulate processing time
    await this.delay(500);

    return {
      success: true,
      messageId: 'simulated-' + Date.now(),
      recipient: emailData.to,
      provider: 'simulation'
    };
  }

  /**
   * Strip HTML tags from text
   */
  stripHtml(html) {
    if (!html) return '';
    return html.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim();
  }

  /**
   * Delay helper function
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // Import all the existing methods from the original service
  async sendNewsletter(newsletterData) {
    // Implementation from original service
    const { subject, html, text, targetAudience, recipientEmails } = newsletterData;

    try {
      let recipients = [];

      if (recipientEmails && recipientEmails.length > 0) {
        recipients = recipientEmails;
      } else {
        recipients = await this.getNewsletterRecipients(targetAudience);
      }

      if (recipients.length === 0) {
        return {
          success: true,
          totalSent: 0,
          successCount: 0,
          failureCount: 0,
          message: 'No recipients found'
        };
      }

      console.log(`📧 Sending newsletter to ${recipients.length} recipients via ${this.provider.toUpperCase()}...`);

      const batchSize = 10;
      const results = [];
      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < recipients.length; i += batchSize) {
        const batch = recipients.slice(i, i + batchSize);
        const batchPromises = batch.map(email => 
          this.sendEmail({
            to: email,
            subject,
            html,
            text
          })
        );

        const batchResults = await Promise.all(batchPromises);
        results.push(...batchResults);

        batchResults.forEach(result => {
          if (result.success) {
            successCount++;
          } else {
            failureCount++;
          }
        });

        if (i + batchSize < recipients.length) {
          await this.delay(1000);
        }
      }

      console.log(`📧 Newsletter sent: ${successCount}/${recipients.length} successful`);

      return {
        success: true,
        totalSent: recipients.length,
        successCount,
        failureCount,
        results,
        provider: this.provider
      };

    } catch (error) {
      console.error('❌ Newsletter send error:', error);
      return {
        success: false,
        error: error.message,
        totalSent: 0,
        successCount: 0,
        failureCount: 0
      };
    }
  }

  async sendEmailVerification(email, name, verificationToken) {
    const verificationUrl = `${process.env.BASE_URL}/verify-email?token=${verificationToken}`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #A89A6A;">Al Marya Rostery</h1>
        </div>
        <h2 style="color: #333;">Email Verification Required</h2>
        <p>Dear ${name},</p>
        <p>Thank you for creating an account with Al Marya Rostery! Please verify your email address by clicking the button below:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" style="background: #A89A6A; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
            Verify Email Address
          </a>
        </div>
        <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #666;">${verificationUrl}</p>
        <p style="margin-top: 30px; color: #666; font-size: 14px;">
          This link will expire in 24 hours. If you didn't create an account with us, please ignore this email.
        </p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px; text-align: center;">
          Al Marya Rostery - Premium Coffee Experience<br>
          UAE
        </p>
      </div>
    `;

    return await this.sendEmail({
      to: email,
      subject: 'Verify Your Email Address - Al Marya Rostery',
      html
    });
  }

  async sendPasswordReset(email, name, resetToken) {
    const resetUrl = `${process.env.BASE_URL}/reset-password?token=${resetToken}`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #A89A6A;">Al Marya Rostery</h1>
        </div>
        <h2 style="color: #333;">Password Reset Request</h2>
        <p>Dear ${name},</p>
        <p>We received a request to reset your password. Click the button below to create a new password:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${resetUrl}" style="background: #e74c3c; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
            Reset Password
          </a>
        </div>
        <p>If the button doesn't work, you can copy and paste this link into your browser:</p>
        <p style="word-break: break-all; color: #666;">${resetUrl}</p>
        <p style="margin-top: 30px; color: #666; font-size: 14px;">
          This link will expire in 1 hour. If you didn't request a password reset, please ignore this email and your password will remain unchanged.
        </p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px; text-align: center;">
          Al Marya Rostery - Premium Coffee Experience<br>
          UAE
        </p>
      </div>
    `;

    return await this.sendEmail({
      to: email,
      subject: 'Password Reset - Al Marya Rostery',
      html
    });
  }

  async sendOrderConfirmation(order, user) {
    const email = user?.email || order.guestInfo?.email;
    const name = user?.name || order.guestInfo?.name;

    if (!email) {
      return { success: false, error: 'No email address available' };
    }

    const itemsHtml = order.items.map(item => `
      <tr>
        <td style="padding: 10px; border-bottom: 1px solid #eee;">${item.name}</td>
        <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: center;">${item.selectedSize || ''}</td>
        <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: center;">${item.quantity}</td>
        <td style="padding: 10px; border-bottom: 1px solid #eee; text-align: right;">AED ${item.subtotal.toFixed(2)}</td>
      </tr>
    `).join('');

    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #A89A6A;">Al Marya Rostery</h1>
        </div>
        <h2 style="color: #333;">Order Confirmation</h2>
        <p>Dear ${name},</p>
        <p>Thank you for your order! Here are the details:</p>
        
        <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
          <h3 style="margin-top: 0;">Order #${order.orderNumber}</h3>
          <p><strong>Status:</strong> ${order.status}</p>
          <p><strong>Total:</strong> AED ${order.totalAmount.toFixed(2)}</p>
          <p><strong>Payment:</strong> ${order.paymentMethod}</p>
          <p><strong>Delivery:</strong> ${order.deliveryMethod}</p>
        </div>

        <h3>Order Items:</h3>
        <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
          <thead>
            <tr style="background: #f1f1f1;">
              <th style="padding: 10px; text-align: left;">Item</th>
              <th style="padding: 10px; text-align: center;">Size</th>
              <th style="padding: 10px; text-align: center;">Qty</th>
              <th style="padding: 10px; text-align: right;">Total</th>
            </tr>
          </thead>
          <tbody>
            ${itemsHtml}
          </tbody>
        </table>

        <p>We'll notify you when your order is ready!</p>
        
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px; text-align: center;">
          Al Marya Rostery - Premium Coffee Experience<br>
          UAE
        </p>
      </div>
    `;

    return await this.sendEmail({
      to: email,
      subject: `Order Confirmation #${order.orderNumber} - Al Marya Rostery`,
      html
    });
  }

  async getNewsletterRecipients(targetAudience = ['all']) {
    try {
      let query = { 
        email: { $exists: true, $ne: null, $ne: '' },
        emailVerified: true
      };

      if (!targetAudience.includes('all')) {
        const conditions = [];

        if (targetAudience.includes('new-customers')) {
          conditions.push({ createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } });
        }

        if (targetAudience.includes('returning-customers')) {
          conditions.push({ lastLogin: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } });
        }

        if (targetAudience.includes('loyal-customers')) {
          conditions.push({ loyaltyPoints: { $gte: 100 } });
        }

        if (conditions.length > 0) {
          query.$or = conditions;
        }
      }

      const users = await User.find(query).select('email');
      return users.map(user => user.email);

    } catch (error) {
      console.error('Error getting newsletter recipients:', error);
      return [];
    }
  }
}

// Export singleton instance
module.exports = new EnhancedEmailService();

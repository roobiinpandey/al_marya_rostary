const nodemailer = require('nodemailer');
const User = require('../models/User');
const auditLogger = require('../utils/auditLogger');

class EmailService {
  constructor() {
    this.transporter = null;
    this.isConfigured = false;
    this.initializeTransporter();
  }

  /**
   * Initialize email transporter with SMTP configuration
   */
  initializeTransporter() {
    try {
      // Check if email configuration is available
      const emailConfig = {
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS
        }
      };

      if (!emailConfig.host || !emailConfig.auth.user || !emailConfig.auth.pass) {
        console.warn('⚠️  Email configuration not complete. Email features will be simulated.');
        this.isConfigured = false;
        return;
      }

      this.transporter = nodemailer.createTransporter(emailConfig);

      // Verify the connection
      this.transporter.verify((error, success) => {
        if (error) {
          console.error('❌ Email transporter verification failed:', error.message);
          this.isConfigured = false;
        } else {
          console.log('✅ Email service configured successfully');
          this.isConfigured = true;
        }
      });

    } catch (error) {
      console.error('❌ Email service initialization error:', error.message);
      this.isConfigured = false;
    }
  }

  /**
   * Send email to single recipient
   * @param {Object} emailData - Email data
   * @returns {Promise<Object>} Send result
   */
  async sendEmail(emailData) {
    const { to, subject, html, text, attachments } = emailData;

    if (!this.isConfigured) {
      return this.simulateEmailSend(emailData);
    }

    try {
      const mailOptions = {
        from: {
          name: process.env.EMAIL_FROM_NAME || 'Qahwat Al Emarat',
          address: process.env.EMAIL_FROM_ADDRESS || process.env.SMTP_USER
        },
        to,
        subject,
        html,
        text: text || this.stripHtml(html),
        attachments
      };

      const result = await this.transporter.sendMail(mailOptions);

      console.log(`📧 Email sent to ${to}: ${result.messageId}`);
      return {
        success: true,
        messageId: result.messageId,
        recipient: to
      };

    } catch (error) {
      console.error('❌ Email send error:', error);
      return {
        success: false,
        error: error.message,
        recipient: to
      };
    }
  }

  /**
   * Send newsletter to multiple recipients
   * @param {Object} newsletterData - Newsletter data
   * @returns {Promise<Object>} Send result
   */
  async sendNewsletter(newsletterData) {
    const { subject, html, text, targetAudience, recipientEmails } = newsletterData;

    try {
      let recipients = [];

      if (recipientEmails && recipientEmails.length > 0) {
        // Send to specific recipients
        recipients = recipientEmails;
      } else {
        // Get recipients based on target audience
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

      console.log(`📧 Sending newsletter to ${recipients.length} recipients...`);

      // Send emails in batches to avoid overwhelming SMTP server
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

        // Count successes and failures
        batchResults.forEach(result => {
          if (result.success) {
            successCount++;
          } else {
            failureCount++;
          }
        });

        // Add delay between batches to avoid rate limiting
        if (i + batchSize < recipients.length) {
          await this.delay(1000); // 1 second delay
        }
      }

      console.log(`📧 Newsletter sent: ${successCount}/${recipients.length} successful`);

      return {
        success: true,
        totalSent: recipients.length,
        successCount,
        failureCount,
        results
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

  /**
   * Send email confirmation/verification
   * @param {String} email - User email
   * @param {String} name - User name
   * @param {String} verificationToken - Verification token
   * @returns {Promise<Object>} Send result
   */
  async sendEmailVerification(email, name, verificationToken) {
    const verificationUrl = `${process.env.BASE_URL}/verify-email?token=${verificationToken}`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #8B4513;">Qahwat Al Emarat</h1>
        </div>
        <h2 style="color: #333;">Email Verification Required</h2>
        <p>Dear ${name},</p>
        <p>Thank you for creating an account with Qahwat Al Emarat! Please verify your email address by clicking the button below:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="${verificationUrl}" style="background: #8B4513; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; display: inline-block;">
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
          Qahwat Al Emarat - Premium Coffee Experience<br>
          UAE
        </p>
      </div>
    `;

    return await this.sendEmail({
      to: email,
      subject: 'Verify Your Email Address - Qahwat Al Emarat',
      html
    });
  }

  /**
   * Send password reset email
   * @param {String} email - User email
   * @param {String} name - User name  
   * @param {String} resetToken - Password reset token
   * @returns {Promise<Object>} Send result
   */
  async sendPasswordReset(email, name, resetToken) {
    const resetUrl = `${process.env.BASE_URL}/reset-password?token=${resetToken}`;
    
    const html = `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #8B4513;">Qahwat Al Emarat</h1>
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
          Qahwat Al Emarat - Premium Coffee Experience<br>
          UAE
        </p>
      </div>
    `;

    return await this.sendEmail({
      to: email,
      subject: 'Password Reset - Qahwat Al Emarat',
      html
    });
  }

  /**
   * Send order confirmation email
   * @param {Object} order - Order data
   * @param {Object} user - User data
   * @returns {Promise<Object>} Send result
   */
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
          <h1 style="color: #8B4513;">Qahwat Al Emarat</h1>
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
          Qahwat Al Emarat - Premium Coffee Experience<br>
          UAE
        </p>
      </div>
    `;

    return await this.sendEmail({
      to: email,
      subject: `Order Confirmation #${order.orderNumber} - Qahwat Al Emarat`,
      html
    });
  }

  /**
   * Get newsletter recipients based on target audience
   * @param {Array} targetAudience - Target audience criteria
   * @returns {Promise<Array>} Array of email addresses
   */
  async getNewsletterRecipients(targetAudience = ['all']) {
    try {
      let query = { 
        email: { $exists: true, $ne: null, $ne: '' },
        emailVerified: true // Only send to verified emails
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

  /**
   * Simulate email sending for development/testing
   */
  async simulateEmailSend(emailData) {
    console.log('📧 Simulating email send...');
    console.log(`To: ${emailData.to}`);
    console.log(`Subject: ${emailData.subject}`);
    console.log(`Content: ${emailData.html || emailData.text}`);

    // Simulate processing time
    await this.delay(500);

    return {
      success: true,
      messageId: 'simulated-' + Date.now(),
      recipient: emailData.to,
      simulated: true
    };
  }

  /**
   * Strip HTML tags from text
   */
  stripHtml(html) {
    return html.replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim();
  }

  /**
   * Delay helper function
   */
  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Test email configuration
   */
  async testConfiguration() {
    if (!this.isConfigured) {
      return { success: false, message: 'Email not configured' };
    }

    try {
      await this.transporter.verify();
      return { success: true, message: 'Email configuration is working' };
    } catch (error) {
      return { success: false, message: error.message };
    }
  }
}

// Export singleton instance
module.exports = new EmailService();

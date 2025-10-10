#!/usr/bin/env node
// Load environment variables FIRST
require('dotenv').config();

// Then require email service
const emailService = require('./services/emailService');

async function testEmailConfiguration() {
  console.log('\n🔧 Email Configuration Test');
  console.log('================================');
  
  // Check environment variables
  console.log('\n📋 Environment Variables Check:');
  const requiredVars = ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASS', 'EMAIL_FROM_ADDRESS'];
  let missingVars = [];
  
  // Detect email service provider
  let emailProvider = 'Unknown';
  const smtpHost = process.env.SMTP_HOST;
  if (smtpHost) {
    if (smtpHost.includes('mailjet')) emailProvider = 'Mailjet';
    else if (smtpHost.includes('sendgrid')) emailProvider = 'SendGrid';
    else if (smtpHost.includes('gmail')) emailProvider = 'Gmail';
    else if (smtpHost.includes('amazon')) emailProvider = 'AWS SES';
    else if (smtpHost.includes('maileroo')) emailProvider = 'Maileroo';
  }
  
  console.log(`📧 Detected Email Provider: ${emailProvider}`);
  console.log('');
  
  requiredVars.forEach(varName => {
    const value = process.env[varName];
    if (value) {
      let displayValue = value;
      if (varName === 'SMTP_PASS') {
        displayValue = '***hidden***';
      } else if (varName === 'SMTP_USER' && emailProvider === 'Mailjet') {
        // Show partial Mailjet API key for verification
        displayValue = value.length > 10 ? `${value.substring(0, 10)}...` : value;
      }
      console.log(`✅ ${varName}: ${displayValue}`);
    } else {
      console.log(`❌ ${varName}: Not set`);
      missingVars.push(varName);
    }
  });
  
  if (missingVars.length > 0) {
    console.log('\n⚠️  Missing required environment variables:');
    missingVars.forEach(varName => {
      console.log(`   - ${varName}`);
    });
    console.log('\nPlease set these variables and try again.');
    console.log('\n📚 Setup Options:');
    console.log('   • For Mailjet (Recommended): node setup-mailjet-email.js');
    console.log('   • For Gmail (Development): node setup-gmail-email.js');
    console.log('   • Manual setup: See EMAIL_SETUP_GUIDE.md');
    return;
  }
  
  // Test email service configuration
  console.log('\n🧪 Testing Email Service Configuration...');
  try {
    const configTest = await emailService.testConfiguration();
    if (configTest.success) {
      console.log('✅ Email service configuration: OK');
    } else {
      console.log(`❌ Email service configuration: ${configTest.message}`);
      return;
    }
  } catch (error) {
    console.log(`❌ Email service configuration error: ${error.message}`);
    return;
  }
  
  // Test sending an actual email
  const testEmail = process.argv[2] || process.env.TEST_EMAIL;
  if (!testEmail) {
    console.log('\n💡 To test sending emails, run:');
    console.log('   node test-email-config.js your-email@example.com');
    return;
  }
  
  console.log(`\n📧 Sending test email to: ${testEmail}`);
  try {
    const emailResult = await emailService.sendEmail({
      to: testEmail,
      subject: 'Qahwat Al Emarat - Email Service Test',
      html: `
        <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #8B4513;">Qahwat Al Emarat</h1>
          </div>
          <h2 style="color: #333;">Email Service Test</h2>
          <p>🎉 Congratulations! Your email service is working correctly.</p>
          <p><strong>Test Details:</strong></p>
          <ul>
            <li>Timestamp: ${new Date().toISOString()}</li>
            <li>Environment: ${process.env.NODE_ENV || 'development'}</li>
            <li>SMTP Host: ${process.env.SMTP_HOST}</li>
            <li>From Address: ${process.env.EMAIL_FROM_ADDRESS}</li>
          </ul>
          <p>Your authentication system is now ready to send:</p>
          <ul>
            <li>✅ Email verification messages</li>
            <li>✅ Password reset emails</li>
            <li>✅ Order confirmations</li>
          </ul>
          <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
          <p style="color: #999; font-size: 12px; text-align: center;">
            Qahwat Al Emarat - Premium Coffee Experience<br>
            UAE
          </p>
        </div>
      `
    });
    
    if (emailResult.success) {
      console.log('✅ Test email sent successfully!');
      console.log(`   Message ID: ${emailResult.messageId}`);
      console.log(`   Check your inbox at: ${testEmail}`);
      
      if (emailProvider === 'Mailjet') {
        console.log('\n📊 Mailjet Features Available:');
        console.log('   • Real-time email tracking and analytics');
        console.log('   • Email template builder');
        console.log('   • A/B testing capabilities');
        console.log('   • Dedicated IP options');
        console.log('   • Dashboard: https://app.mailjet.com/');
      }
    } else {
      console.log(`❌ Failed to send test email: ${emailResult.error}`);
      
      if (emailProvider === 'Mailjet') {
        console.log('\n💡 Mailjet Troubleshooting:');
        console.log('   • Verify API Key and Secret Key are correct');
        console.log('   • Ensure sender email is verified in Mailjet dashboard');
        console.log('   • Check account status and limits');
        console.log('   • Dashboard: https://app.mailjet.com/');
      }
    }
    
  } catch (error) {
    console.log(`❌ Error sending test email: ${error.message}`);
  }
  
  console.log('\n🏁 Email configuration test completed.');
}

// Run the test
testEmailConfiguration().catch(error => {
  console.error('💥 Unexpected error:', error);
  process.exit(1);
});

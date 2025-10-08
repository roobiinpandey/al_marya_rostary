#!/bin/bash

# Test Email Configuration
echo "📧 Testing Email Configuration..."

# Check required environment variables
if [ -z "$SMTP_HOST" ]; then
    echo "❌ SMTP_HOST not set"
    exit 1
fi

if [ -z "$SMTP_USER" ]; then
    echo "❌ SMTP_USER not set"
    exit 1
fi

if [ -z "$SMTP_PASS" ]; then
    echo "❌ SMTP_PASS not set"
    exit 1
fi

# Create temporary test file
cat > test-email.js << 'EOF'
const nodemailer = require('nodemailer');

async function testEmail() {
    try {
        console.log('📧 Testing email configuration...');
        
        // Check environment variables
        const emailConfig = {
            host: process.env.SMTP_HOST,
            port: parseInt(process.env.SMTP_PORT) || 587,
            secure: process.env.SMTP_SECURE === 'true',
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        };
        
        console.log('📧 SMTP Host:', emailConfig.host);
        console.log('📧 SMTP Port:', emailConfig.port);
        console.log('📧 SMTP Secure:', emailConfig.secure);
        console.log('📧 SMTP User:', emailConfig.auth.user);
        
        // Create transporter
        const transporter = nodemailer.createTransporter(emailConfig);
        
        // Verify connection
        console.log('🔗 Verifying SMTP connection...');
        const verified = await transporter.verify();
        
        if (verified) {
            console.log('✅ SMTP connection verified successfully');
        } else {
            console.log('❌ SMTP connection verification failed');
        }
        
        // Test email sending (optional - requires test recipient)
        const testRecipient = process.env.TEST_EMAIL;
        if (testRecipient) {
            console.log('📧 Sending test email to:', testRecipient);
            
            const mailOptions = {
                from: {
                    name: process.env.EMAIL_FROM_NAME || 'Qahwat Al Emarat',
                    address: process.env.EMAIL_FROM_ADDRESS || process.env.SMTP_USER
                },
                to: testRecipient,
                subject: 'Test Email from Qahwat Al Emarat Backend',
                html: `
                    <h1>Email Service Test</h1>
                    <p>This is a test email from your Qahwat Al Emarat backend service.</p>
                    <p><strong>Timestamp:</strong> ${new Date().toISOString()}</p>
                    <p>If you receive this email, your email service is configured correctly!</p>
                `
            };
            
            const result = await transporter.sendMail(mailOptions);
            console.log('✅ Test email sent successfully');
            console.log('📧 Message ID:', result.messageId);
        } else {
            console.log('ℹ️  Skipping test email (TEST_EMAIL not set)');
        }
        
        console.log('🎉 Email configuration test PASSED');
        
    } catch (error) {
        console.error('❌ Email test failed:', error.message);
        console.error('💡 Common issues:');
        console.error('   - Check SMTP credentials');
        console.error('   - Verify SMTP host and port');
        console.error('   - For Gmail: use app-specific password');
        console.error('   - For SendGrid: use "apikey" as username');
        process.exit(1);
    }
}

testEmail();
EOF

# Run email test
node test-email.js

# Cleanup
rm test-email.js

echo "✅ Email configuration test completed"

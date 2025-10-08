require('dotenv').config();
const nodemailer = require('nodemailer');

async function testMaileroo() {
    console.log('📧 Testing Maileroo Email Configuration...');
    
    // Check environment variables
    const requiredVars = ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASS'];
    const missingVars = requiredVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
        console.error('❌ Missing required environment variables:', missingVars.join(', '));
        console.log('💡 Please set these variables in your .env file:');
        console.log('   SMTP_HOST=smtp.maileroo.com');
        console.log('   SMTP_USER=your-maileroo-username');
        console.log('   SMTP_PASS=your-maileroo-password');
        return false;
    }
    
    try {
        // Maileroo configuration
        const emailConfig = {
            host: process.env.SMTP_HOST,
            port: parseInt(process.env.SMTP_PORT) || 587,
            secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            },
            // Maileroo specific options
            tls: {
                rejectUnauthorized: false // For development/testing
            }
        };
        
        console.log('📧 Maileroo Configuration:');
        console.log('- Host:', emailConfig.host);
        console.log('- Port:', emailConfig.port);
        console.log('- Secure:', emailConfig.secure);
        console.log('- User:', emailConfig.auth.user);
        console.log('- Pass:', '*'.repeat(emailConfig.auth.pass?.length || 0));
        
        // Create transporter
        console.log('\n🔗 Creating Maileroo transporter...');
        const transporter = nodemailer.createTransport(emailConfig);
        
        // Verify connection
        console.log('🔍 Verifying SMTP connection...');
        const verified = await transporter.verify();
        
        if (verified) {
            console.log('✅ Maileroo SMTP connection verified successfully!');
        } else {
            console.log('❌ Maileroo SMTP connection verification failed');
            return false;
        }
        
        // Test email sending (optional)
        const testRecipient = process.env.TEST_EMAIL;
        if (testRecipient) {
            console.log('\n📧 Sending test email via Maileroo to:', testRecipient);
            
            const mailOptions = {
                from: {
                    name: process.env.EMAIL_FROM_NAME || 'Qahwat Al Emarat',
                    address: process.env.EMAIL_FROM_ADDRESS || process.env.SMTP_USER
                },
                to: testRecipient,
                subject: 'Test Email from Qahwat Al Emarat via Maileroo',
                html: `
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
                        <div style="text-align: center; margin-bottom: 30px;">
                            <h1 style="color: #8B4513;">Qahwat Al Emarat</h1>
                        </div>
                        <h2 style="color: #333;">Maileroo Email Service Test</h2>
                        <p>Congratulations! 🎉</p>
                        <p>This test email was sent successfully using <strong>Maileroo</strong> email service.</p>
                        <div style="background: #f8f9fa; padding: 20px; border-radius: 5px; margin: 20px 0;">
                            <h3 style="margin-top: 0;">Test Details:</h3>
                            <p><strong>Timestamp:</strong> ${new Date().toISOString()}</p>
                            <p><strong>Service:</strong> Maileroo SMTP</p>
                            <p><strong>From:</strong> ${process.env.EMAIL_FROM_NAME || 'Qahwat Al Emarat'}</p>
                            <p><strong>Host:</strong> ${emailConfig.host}:${emailConfig.port}</p>
                        </div>
                        <p>If you receive this email, your Maileroo configuration is working perfectly!</p>
                        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
                        <p style="color: #999; font-size: 12px; text-align: center;">
                            Qahwat Al Emarat - Premium Coffee Experience<br>
                            UAE
                        </p>
                    </div>
                `,
                text: `
                    Qahwat Al Emarat - Maileroo Email Service Test
                    
                    Congratulations! This test email was sent successfully using Maileroo email service.
                    
                    Test Details:
                    - Timestamp: ${new Date().toISOString()}
                    - Service: Maileroo SMTP
                    - From: ${process.env.EMAIL_FROM_NAME || 'Qahwat Al Emarat'}
                    - Host: ${emailConfig.host}:${emailConfig.port}
                    
                    If you receive this email, your Maileroo configuration is working perfectly!
                `
            };
            
            const result = await transporter.sendMail(mailOptions);
            console.log('✅ Test email sent successfully via Maileroo!');
            console.log('📧 Message ID:', result.messageId);
            console.log('📮 Accepted:', result.accepted);
            console.log('❌ Rejected:', result.rejected);
        } else {
            console.log('ℹ️  Skipping test email (set TEST_EMAIL=your@email.com to test sending)');
        }
        
        console.log('\n🎉 Maileroo configuration test PASSED!');
        console.log('📋 Ready for production deployment');
        
        return true;
        
    } catch (error) {
        console.error('\n❌ Maileroo test failed:', error.message);
        
        console.log('\n🔧 Troubleshooting Maileroo:');
        console.log('1. Verify your Maileroo SMTP credentials');
        console.log('2. Check if your Maileroo account is active');
        console.log('3. Ensure SMTP is enabled in your Maileroo dashboard');
        console.log('4. Try different SMTP ports (587, 465, 25)');
        console.log('5. Check firewall/network restrictions');
        
        if (error.code === 'EAUTH') {
            console.log('💡 Authentication failed - check username/password');
        } else if (error.code === 'ECONNECTION') {
            console.log('💡 Connection failed - check host and port');
        }
        
        return false;
    }
}

// Run the test
testMaileroo().then(success => {
    if (success) {
        console.log('\n🚀 Maileroo is ready for your application!');
    } else {
        console.log('\n❌ Please fix the Maileroo configuration and try again');
    }
    process.exit(success ? 0 : 1);
}).catch(error => {
    console.error('💥 Test crashed:', error);
    process.exit(1);
});

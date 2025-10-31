#!/bin/bash

echo "🔧 Gmail SMTP Configuration Fix"
echo "==============================="
echo ""

echo "📧 Current Gmail Setup:"
echo "Email: $(grep '^SMTP_USER=' .env | cut -d'=' -f2)"
echo "App Password: $(grep '^SMTP_PASS=' .env | cut -d'=' -f2)"
echo ""

echo "🔍 Step 1: Verify Gmail Account Requirements"
echo "--------------------------------------------"
echo "✅ Gmail account: almaryahrostery@gmail.com"
echo ""
echo "Please verify the following settings:"
echo ""
echo "1️⃣ Enable 2-Factor Authentication:"
echo "   🔗 Go to: https://myaccount.google.com/security"
echo "   👀 Ensure '2-Step Verification' is ON"
echo ""
echo "2️⃣ Generate App Password:"
echo "   🔗 Go to: https://myaccount.google.com/apppasswords"
echo "   📱 Create new App Password for 'Mail'"
echo "   📋 Copy the 16-character password (format: abcd efgh ijkl mnop)"
echo ""

echo "🧪 Step 2: Test Current Configuration"
echo "------------------------------------"

# Create a Gmail test script
cat > test-gmail-connection.js << 'EOF'
const nodemailer = require('nodemailer');
require('dotenv').config();

console.log('🔍 Testing Gmail SMTP Configuration...');
console.log('📧 Email:', process.env.SMTP_USER);
console.log('🔑 App Password Length:', process.env.SMTP_PASS ? process.env.SMTP_PASS.length : 'NOT SET');
console.log('');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false, // true for 465, false for other ports
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  },
  tls: {
    rejectUnauthorized: false
  }
});

console.log('⚡ Testing SMTP connection...');
transporter.verify((error, success) => {
  if (error) {
    console.log('❌ Gmail SMTP Test Failed:');
    console.log('Error:', error.message);
    
    if (error.message.includes('535-5.7.8')) {
      console.log('');
      console.log('🔧 SOLUTION: Invalid credentials detected');
      console.log('📋 Action needed:');
      console.log('   1. Check 2FA is enabled on Gmail account');
      console.log('   2. Generate new App Password');
      console.log('   3. Update SMTP_PASS in .env file');
      console.log('   4. Restart server');
    }
  } else {
    console.log('✅ Gmail SMTP Test Successful!');
    console.log('📧 Ready to send emails');
  }
});

// Test sending an email
async function testSendEmail() {
  try {
    console.log('');
    console.log('📨 Testing email sending...');
    
    const mailOptions = {
      from: `"${process.env.EMAIL_FROM_NAME}" <${process.env.EMAIL_FROM_ADDRESS}>`,
      to: process.env.SMTP_USER, // Send to self for testing
      subject: '✅ Al Marya Rostery - Gmail Test Email',
      html: `
        <h2>🎉 Gmail Configuration Successful!</h2>
        <p>This is a test email from Al Marya Rostery backend.</p>
        <p><strong>✅ Gmail SMTP is working correctly!</strong></p>
        <p>Time: ${new Date().toLocaleString()}</p>
        <hr>
        <p><em>Al Marya Rostery - Premium Coffee Experience</em></p>
      `
    };

    const info = await transporter.sendMail(mailOptions);
    console.log('✅ Test email sent successfully!');
    console.log('📧 Message ID:', info.messageId);
    console.log('🎯 Email delivered to:', process.env.SMTP_USER);
    
  } catch (error) {
    console.log('❌ Test email failed:', error.message);
  }
}

// Wait 2 seconds then test sending
setTimeout(testSendEmail, 2000);
EOF

echo "▶️  Running Gmail connection test..."
node test-gmail-connection.js

echo ""
echo "🔧 Step 3: Fix Configuration (if needed)"
echo "----------------------------------------"

if [ $? -ne 0 ]; then
    echo "❌ Gmail test failed. Follow these steps:"
    echo ""
    echo "1️⃣ Generate NEW App Password:"
    echo "   🔗 https://myaccount.google.com/apppasswords"
    echo "   📱 Delete old 'Mail' app password"
    echo "   📋 Create new one and copy it"
    echo ""
    echo "2️⃣ Update .env file:"
    echo "   📝 Edit SMTP_PASS=your_new_app_password"
    echo "   💾 Save the file"
    echo ""
    echo "3️⃣ Restart server:"
    echo "   🔄 npm restart"
    echo ""
else
    echo "✅ Gmail configuration is working!"
fi

# Clean up test file
rm -f test-gmail-connection.js

echo ""
echo "📞 Need help? Check these links:"
echo "🔗 Gmail App Passwords: https://myaccount.google.com/apppasswords"
echo "🔗 Gmail 2FA Setup: https://myaccount.google.com/security"
echo "🔗 Google Support: https://support.google.com/mail/?p=BadCredentials"
echo ""
echo "==============================="

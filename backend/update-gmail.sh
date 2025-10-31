#!/bin/bash

echo "🔧 Gmail App Password Updater"
echo "=============================="
echo ""

# Function to update app password
update_app_password() {
    echo "📝 Current Gmail configuration:"
    echo "Email: $(grep '^SMTP_USER=' .env | cut -d'=' -f2)"
    echo "Current App Password: $(grep '^SMTP_PASS=' .env | cut -d'=' -f2)"
    echo ""
    
    echo "📋 To get a new App Password:"
    echo "1. Go to: https://myaccount.google.com/apppasswords"
    echo "2. Create new App Password for 'Mail'"
    echo "3. Copy the 16-character password"
    echo ""
    
    read -p "Enter your new Gmail App Password (16 chars with spaces): " new_password
    
    if [ -z "$new_password" ]; then
        echo "❌ No password entered. Exiting."
        exit 1
    fi
    
    # Validate password format (should be 19 characters including spaces)
    if [ ${#new_password} -ne 19 ]; then
        echo "⚠️  Warning: App Password should be 19 characters (including spaces)"
        echo "   Expected format: 'abcd efgh ijkl mnop'"
        echo "   Your input: '$new_password' (${#new_password} characters)"
        echo ""
        read -p "Continue anyway? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            echo "❌ Cancelled. Please get the correct App Password."
            exit 1
        fi
    fi
    
    # Backup current .env
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    echo "💾 Backed up current .env file"
    
    # Update the password
    sed -i '' "s/^SMTP_PASS=.*/SMTP_PASS=$new_password/" .env
    
    echo "✅ Updated SMTP_PASS in .env file"
    echo ""
    echo "📧 New Gmail configuration:"
    echo "Email: $(grep '^SMTP_USER=' .env | cut -d'=' -f2)"
    echo "App Password: $(grep '^SMTP_PASS=' .env | cut -d'=' -f2)"
    echo ""
}

# Function to test the connection
test_gmail_connection() {
    echo "🧪 Testing Gmail SMTP connection..."
    
    # Create test script
    cat > test-gmail.js << 'EOF'
const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

console.log('⚡ Testing SMTP connection...');
transporter.verify((error, success) => {
  if (error) {
    console.log('❌ Gmail SMTP Test Failed:');
    console.log('Error:', error.message);
    process.exit(1);
  } else {
    console.log('✅ Gmail SMTP Test Successful!');
    console.log('📧 Ready to send emails');
    process.exit(0);
  }
});
EOF

    node test-gmail.js
    test_result=$?
    rm -f test-gmail.js
    
    return $test_result
}

# Main script
echo "🔍 Current Status:"
if test_gmail_connection 2>/dev/null; then
    echo "✅ Gmail is already working!"
    echo ""
    read -p "Do you want to update the App Password anyway? (y/N): " update_anyway
    if [[ ! $update_anyway =~ ^[Yy]$ ]]; then
        echo "✅ No changes made. Gmail is working correctly."
        exit 0
    fi
fi

echo "🔧 Gmail authentication is not working. Let's fix it!"
echo ""

update_app_password

echo "🧪 Testing new configuration..."
if test_gmail_connection; then
    echo ""
    echo "🎉 SUCCESS! Gmail SMTP is now working!"
    echo ""
    echo "🔄 Next steps:"
    echo "1. Restart your server: npm restart"
    echo "2. Check server logs for: '✅ Email SMTP connection verified'"
    echo "3. Email service will switch from simulation to live mode"
else
    echo ""
    echo "❌ Gmail test still failed. Please check:"
    echo "1. 2FA is enabled on almaryahrostery@gmail.com"
    echo "2. App Password was copied correctly (19 chars with spaces)"
    echo "3. Go to: https://myaccount.google.com/apppasswords"
    echo ""
    echo "💡 You can run this script again with: ./update-gmail.sh"
fi

echo ""
echo "=============================="

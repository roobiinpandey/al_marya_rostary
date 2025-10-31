#!/bin/bash

# Gmail App Password Setup Script for Al Marya Rostery
# This script helps set up Gmail App Password for email authentication

echo "🔧 Al Marya Rostery - Gmail App Password Setup"
echo "=============================================="
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "Please make sure you're running this from the backend directory."
    exit 1
fi

echo "📋 Current Email Configuration:"
echo "SMTP_HOST: $(grep 'SMTP_HOST=' .env | cut -d'=' -f2)"
echo "SMTP_USER: $(grep 'SMTP_USER=' .env | cut -d'=' -f2)"
echo "SMTP_PASS: $(grep 'SMTP_PASS=' .env | cut -d'=' -f2)"
echo ""

# Check if current password is placeholder
current_pass=$(grep 'SMTP_PASS=' .env | cut -d'=' -f2)
if [ "$current_pass" = "your-gmail-app-password-here" ]; then
    echo "⚠️  SMTP_PASS is still using placeholder value!"
    echo ""
    echo "📝 To fix this, follow these steps:"
    echo ""
    echo "1️⃣  Enable 2-Factor Authentication on Gmail:"
    echo "   - Go to: https://myaccount.google.com/security"
    echo "   - Enable 2-Step Verification"
    echo ""
    echo "2️⃣  Generate App Password:"
    echo "   - Go to: https://myaccount.google.com/apppasswords"
    echo "   - Select 'Mail' as the app"
    echo "   - Generate a 16-character password"
    echo ""
    echo "3️⃣  Update .env file:"
    echo "   - Replace 'your-gmail-app-password-here' with your app password"
    echo "   - Example: SMTP_PASS=abcd efgh ijkl mnop"
    echo ""
    echo "4️⃣  Restart the server:"
    echo "   - npm restart"
    echo ""
    
    read -p "Do you want to update the password now? (y/n): " update_now
    
    if [ "$update_now" = "y" ] || [ "$update_now" = "Y" ]; then
        echo ""
        read -p "Enter your Gmail App Password (16 characters): " new_password
        
        if [ ${#new_password} -eq 19 ]; then  # 16 chars + 3 spaces = 19
            # Update .env file
            sed -i.bak "s/SMTP_PASS=.*/SMTP_PASS=$new_password/" .env
            echo "✅ Password updated successfully!"
            echo ""
            echo "🔄 Restarting server..."
            
            # Kill existing server if running
            if pgrep -f "node.*server.js" > /dev/null; then
                pkill -f "node.*server.js"
                echo "🛑 Stopped existing server"
                sleep 2
            fi
            
            # Start server
            npm start &
            echo "🚀 Server restarted"
            
        else
            echo "❌ Invalid password format. App passwords are 16 characters long (with spaces)."
            echo "Example format: abcd efgh ijkl mnop"
        fi
    fi
    
else
    echo "✅ SMTP_PASS appears to be configured"
    echo ""
    echo "🧪 Testing email configuration..."
    
    # Test if server is running
    if curl -s http://localhost:5001/health > /dev/null 2>&1; then
        echo "✅ Server is running"
        echo ""
        echo "📧 You can test email functionality at:"
        echo "   - Email config: GET http://localhost:5001/api/test/email-config"
        echo "   - Send test email: POST http://localhost:5001/api/test/send-email"
        echo "   - Email status: GET http://localhost:5001/api/test/email-status"
        echo ""
        echo "💡 Use admin credentials to access these endpoints"
    else
        echo "⚠️  Server is not running. Start it with: npm start"
    fi
fi

echo ""
echo "📚 For more information, see: EMAIL_SETUP_GUIDE.md"
echo ""

# Alternative email providers section
echo "🔄 Alternative Email Providers:"
echo "If Gmail doesn't work, you can use:"
echo ""
echo "📧 SendGrid:"
echo "   - Set EMAIL_PROVIDER=sendgrid in .env"
echo "   - Add SENDGRID_API_KEY=your-api-key"
echo ""
echo "📧 AWS SES:"
echo "   - Set EMAIL_PROVIDER=ses in .env"
echo "   - Add AWS credentials to .env"
echo ""
echo "📧 OAuth2 (Most Secure):"
echo "   - Set EMAIL_PROVIDER=oauth2 in .env"
echo "   - Add Google OAuth2 credentials"
echo ""

echo "🎯 Current Status: Email service will run in simulation mode until configured properly."
echo "=============================================="

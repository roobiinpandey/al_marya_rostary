#!/bin/bash

echo "🔧 Gmail App Password Setup for Al Marya Rostery"
echo "==============================================="
echo ""
echo "Current configuration:"
echo "SMTP_USER: $(grep 'SMTP_USER=' .env | cut -d'=' -f2)"
echo "SMTP_PASS: $(grep 'SMTP_PASS=' .env | cut -d'=' -f2)"
echo ""

if grep -q "REPLACE_WITH_YOUR_16_CHAR_APP_PASSWORD" .env; then
    echo "❌ Gmail App Password not configured yet!"
    echo ""
    echo "📋 Follow these steps:"
    echo ""
    echo "1️⃣  Enable 2-Factor Authentication:"
    echo "   🔗 https://myaccount.google.com/security"
    echo ""
    echo "2️⃣  Generate App Password:"
    echo "   🔗 https://myaccount.google.com/apppasswords"
    echo "   - Select 'Mail' from dropdown"
    echo "   - Click 'Generate'"
    echo "   - Copy the 16-character password"
    echo ""
    echo "3️⃣  Enter your Gmail App Password below:"
    read -p "Gmail App Password (16 chars with spaces): " app_password
    
    if [ ! -z "$app_password" ]; then
        # Update .env file
        if [[ "$app_password" =~ ^[a-z]{4}\ [a-z]{4}\ [a-z]{4}\ [a-z]{4}$ ]]; then
            sed -i.bak "s/SMTP_PASS=REPLACE_WITH_YOUR_16_CHAR_APP_PASSWORD/SMTP_PASS=$app_password/" .env
            echo ""
            echo "✅ Gmail App Password updated successfully!"
            echo ""
            echo "🚀 Testing email configuration..."
            
            # Start server in background and test
            if ! pgrep -f "node.*server.js" > /dev/null; then
                echo "🔄 Starting server..."
                npm start > /dev/null 2>&1 &
                SERVER_PID=$!
                sleep 5
                
                # Test email configuration
                echo "📧 Testing email service..."
                curl -s http://localhost:5001/health > /dev/null
                if [ $? -eq 0 ]; then
                    echo "✅ Server is running and responding"
                    echo ""
                    echo "🎯 Email service should now work!"
                    echo "   Check server logs for email verification status"
                else
                    echo "⚠️  Server might still be starting..."
                fi
            else
                echo "✅ Server is already running"
                echo "🔄 Email service will reinitialize automatically"
            fi
            
        else
            echo "❌ Invalid format. App passwords should be like: abcd efgh ijkl mnop"
        fi
    else
        echo "❌ No password provided"
    fi
else
    echo "✅ Gmail App Password appears to be configured!"
    echo ""
    echo "🧪 Testing current configuration..."
    
    if pgrep -f "node.*server.js" > /dev/null; then
        echo "✅ Server is running"
        echo "📧 Check server logs to see if email verification succeeded"
    else
        echo "🔄 Starting server to test configuration..."
        npm start &
        echo "📧 Watch the server logs for email service status"
    fi
fi

echo ""
echo "📚 Troubleshooting Tips:"
echo "• If still getting errors, check that 2FA is enabled on Gmail"
echo "• Make sure you're using the Gmail account: almaryahrostery@gmail.com"
echo "• App passwords are case-sensitive and include spaces"
echo "• Server logs will show: '✅ Email SMTP connection verified successfully'"
echo ""

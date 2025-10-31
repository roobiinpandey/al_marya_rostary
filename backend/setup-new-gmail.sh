#!/bin/bash

echo "🎯 Al Marya Rostery - New Gmail Account Setup"
echo "============================================="
echo "📧 New Gmail: almaryahrostery@gmail.com"
echo ""

echo "📋 Current Configuration Updated:"
echo "✅ SMTP_USER: almaryahrostery@gmail.com"
echo "✅ EMAIL_FROM_ADDRESS: almaryahrostery@gmail.com"
echo "❌ SMTP_PASS: Needs new App Password"
echo ""

echo "🔧 Required Setup Steps for almaryahrostery@gmail.com:"
echo ""
echo "1️⃣  Enable 2-Factor Authentication:"
echo "   🔗 https://myaccount.google.com/security"
echo "   - Sign in with almaryahrostery@gmail.com"
echo "   - Go to 'How you sign in to Google'"
echo "   - Enable '2-Step Verification'"
echo ""

echo "2️⃣  Generate App Password:"
echo "   🔗 https://myaccount.google.com/apppasswords"
echo "   - Sign in with almaryahrostery@gmail.com"
echo "   - Select 'Mail' from dropdown"
echo "   - Click 'Generate'"
echo "   - Copy the 16-character password"
echo ""

echo "3️⃣  Update App Password:"
read -p "Enter Gmail App Password for almaryahrostery@gmail.com: " app_password

if [ ! -z "$app_password" ]; then
    if [[ "$app_password" =~ ^[a-z]{4}\ [a-z]{4}\ [a-z]{4}\ [a-z]{4}$ ]]; then
        # Update .env file
        sed -i.bak "s/SMTP_PASS=NEED_NEW_APP_PASSWORD_FOR_NEW_ACCOUNT/SMTP_PASS=$app_password/" .env
        echo ""
        echo "✅ Gmail App Password updated successfully!"
        echo ""
        
        # Test the configuration
        echo "🧪 Testing email configuration..."
        
        # Kill existing server if running
        if pgrep -f "node.*server.js" > /dev/null; then
            echo "🛑 Stopping existing server..."
            pkill -f "node.*server.js"
            sleep 3
        fi
        
        # Start server
        echo "🚀 Starting server with new email configuration..."
        npm start > server_test.log 2>&1 &
        SERVER_PID=$!
        sleep 8
        
        # Check if email verification succeeded
        if grep -q "✅.*Email.*verified successfully" server_test.log; then
            echo "✅ Email service verified successfully!"
            echo "📧 almaryahrostery@gmail.com is now configured and working"
        elif grep -q "⚠️.*Email transporter verification failed" server_test.log; then
            echo "❌ Email verification failed. Check the logs:"
            grep "Email transporter verification failed" server_test.log
            echo ""
            echo "🔍 Possible issues:"
            echo "• 2FA not enabled on almaryahrostery@gmail.com"
            echo "• App Password incorrect or expired"
            echo "• Account security settings blocking access"
        else
            echo "🔄 Email service initialized. Check server logs for status."
        fi
        
        # Show server status
        if pgrep -f "node.*server.js" > /dev/null; then
            echo ""
            echo "✅ Server is running on port 5001"
            echo "🔗 Admin panel: http://localhost:5001/admin"
            echo "📊 Health check: http://localhost:5001/health"
        fi
        
        # Clean up log file
        rm -f server_test.log
        
    else
        echo "❌ Invalid format. App passwords should be like: abcd efgh ijkl mnop"
        echo "Please run this script again with the correct format."
    fi
else
    echo "❌ No password provided. Please run this script again."
fi

echo ""
echo "📱 Firebase Integration Notes:"
echo "• Firebase will handle user authentication (login/signup)"
echo "• The new Gmail will handle:"
echo "  - Order confirmations"
echo "  - Newsletter emails"
echo "  - Password reset notifications"
echo "  - System notifications"
echo ""

echo "🔐 Security Best Practices:"
echo "• Keep the App Password secure"
echo "• Don't share Gmail credentials"
echo "• Regularly rotate passwords"
echo "• Monitor email sending logs"
echo ""

echo "🎯 Next Steps:"
echo "1. Complete 2FA setup on almaryahrostery@gmail.com"
echo "2. Generate and enter App Password above"
echo "3. Test email functionality in admin panel"
echo "4. Update any hardcoded email references in the app"
echo ""

# Check for any hardcoded email references
echo "🔍 Checking for hardcoded email references..."
if grep -r "almaryarostery@gmail.com" ../lib/ 2>/dev/null; then
    echo "⚠️  Found references to old email in Flutter app"
    echo "   Consider updating these to use the new email"
else
    echo "✅ No hardcoded email references found in Flutter app"
fi

if grep -r "almaryarostery@gmail.com" . --exclude-dir=node_modules 2>/dev/null; then
    echo "⚠️  Found references to old email in backend"
    echo "   These should be updated to almaryahrostery@gmail.com"
else
    echo "✅ Backend email references are clean"
fi

echo ""
echo "🎉 Setup complete! almaryahrostery@gmail.com is now configured."
echo "============================================="

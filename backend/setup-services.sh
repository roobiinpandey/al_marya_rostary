#!/bin/bash

# Firebase and Email Setup Script for Qahwat Al Emarat Backend
# This script helps you configure Firebase and Email services

echo "🔧 Qahwat Al Emarat - Service Configuration Setup"
echo "================================================"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found! Please make sure you're in the backend directory."
    exit 1
fi

echo "📋 Current service status:"
echo ""

# Check current configuration
echo "🔥 Firebase Configuration:"
if grep -q "FIREBASE_SERVICE_ACCOUNT_KEY=" .env && ! grep -q "^# FIREBASE_SERVICE_ACCOUNT_KEY=" .env; then
    echo "   ✅ Firebase service account key is configured"
else
    echo "   ⚠️  Firebase service account key is not configured"
    echo "   📝 You need to set up Firebase for push notifications"
fi

if grep -q "FIREBASE_PROJECT_ID=" .env && ! grep -q "^# FIREBASE_PROJECT_ID=" .env; then
    echo "   ✅ Firebase project ID is configured"
else
    echo "   ⚠️  Firebase project ID is not configured"
fi

echo ""
echo "📧 Email Configuration:"
if grep -q "SMTP_HOST=" .env && ! grep -q "^# SMTP_HOST=" .env; then
    echo "   ✅ SMTP host is configured"
else
    echo "   ⚠️  SMTP host is not configured"
    echo "   📝 You need to set up email service (Gmail/Maileroo)"
fi

if grep -q "SMTP_USER=" .env && ! grep -q "^# SMTP_USER=" .env; then
    echo "   ✅ SMTP user is configured"
else
    echo "   ⚠️  SMTP user is not configured"
fi

if grep -q "SMTP_PASS=" .env && ! grep -q "^# SMTP_PASS=" .env; then
    echo "   ✅ SMTP password is configured"
else
    echo "   ⚠️  SMTP password is not configured"
fi

echo ""
echo "🚀 Quick Setup Options:"
echo ""
echo "1. Configure Gmail SMTP (recommended):"
echo "   - Enable 2FA in your Gmail account"
echo "   - Generate App Password"
echo "   - Update .env with Gmail SMTP settings"
echo ""
echo "2. Configure Firebase:"
echo "   - Create Firebase project at https://console.firebase.google.com"
echo "   - Generate service account key"
echo "   - Update .env with Firebase credentials"
echo ""
echo "3. Test configuration:"
echo "   node test-firebase-simple.js  # Test Firebase"
echo "   node test-maileroo.js         # Test Email"
echo ""

# Interactive setup
echo "🔧 Would you like to set up Gmail SMTP now? (y/n)"
read -r setup_gmail

if [ "$setup_gmail" = "y" ] || [ "$setup_gmail" = "Y" ]; then
    echo ""
    echo "📧 Gmail SMTP Setup:"
    echo "Please enter your Gmail credentials:"
    
    read -p "Gmail address: " gmail_user
    read -p "App password (16 characters): " gmail_pass
    
    # Update .env file
    if grep -q "^# SMTP_HOST=" .env; then
        sed -i '' 's/^# SMTP_HOST=.*/SMTP_HOST=smtp.gmail.com/' .env
        sed -i '' 's/^# SMTP_PORT=.*/SMTP_PORT=587/' .env
        sed -i '' 's/^# SMTP_SECURE=.*/SMTP_SECURE=false/' .env
        sed -i '' "s/^# SMTP_USER=.*/SMTP_USER=${gmail_user}/" .env
        sed -i '' "s/^# SMTP_PASS=.*/SMTP_PASS=${gmail_pass}/" .env
        sed -i '' "s/^# EMAIL_FROM_ADDRESS=.*/EMAIL_FROM_ADDRESS=${gmail_user}/" .env
        echo "✅ Gmail SMTP configured in .env file"
    else
        echo "SMTP_HOST=smtp.gmail.com" >> .env
        echo "SMTP_PORT=587" >> .env
        echo "SMTP_SECURE=false" >> .env
        echo "SMTP_USER=${gmail_user}" >> .env
        echo "SMTP_PASS=${gmail_pass}" >> .env
        echo "EMAIL_FROM_ADDRESS=${gmail_user}" >> .env
        echo "✅ Gmail SMTP added to .env file"
    fi
    
    echo ""
    echo "🧪 Testing email configuration..."
    node test-maileroo.js
fi

echo ""
echo "📖 For complete setup instructions, see:"
echo "   📄 FIREBASE_EMAIL_SETUP_GUIDE.md"
echo ""
echo "🔄 Remember to restart your server after making changes:"
echo "   npm start"
echo ""

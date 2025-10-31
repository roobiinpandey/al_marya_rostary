# Email Service Setup Guide - Al Marya Rostery

## Current Issue
The email service is failing with "Invalid login: 535-5.7.8 Username and Password not accepted" because the `.env` file contains placeholder credentials instead of real Gmail app passwords.

## 🔧 Quick Fix Solutions

### Solution 1: Gmail App Password (Recommended)

1. **Enable 2-Factor Authentication on Gmail**:
   - Go to [Google Account Settings](https://myaccount.google.com/)
   - Navigate to Security → 2-Step Verification
   - Enable 2-Step Verification

2. **Generate App Password**:
   - Go to Security → App passwords
   - Select "Mail" as the app
   - Generate a 16-character app password

3. **Update .env file**:
   ```bash
   SMTP_USER=almaryarostery@gmail.com
   SMTP_PASS=abcd efgh ijkl mnop  # Your 16-character app password
   ```

### Solution 2: OAuth2 Authentication (Most Secure)

1. **Create Google Cloud Project**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create new project or use existing
   - Enable Gmail API

2. **Create OAuth2 Credentials**:
   - Go to APIs & Services → Credentials
   - Create OAuth2 client ID for "Desktop application"
   - Download credentials JSON

3. **Update environment variables**:
   ```bash
   GMAIL_CLIENT_ID=your-client-id
   GMAIL_CLIENT_SECRET=your-client-secret
   GMAIL_REFRESH_TOKEN=your-refresh-token
   ```

### Solution 3: Alternative Email Service (Fallback)

Use SendGrid, AWS SES, or Maileroo as backup:

#### SendGrid Setup:
```bash
SENDGRID_API_KEY=your-sendgrid-api-key
EMAIL_PROVIDER=sendgrid
```

#### AWS SES Setup:
```bash
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
EMAIL_PROVIDER=ses
```

## 🚀 Implementation Status

- ✅ **Analysis Complete**: Identified placeholder credentials in .env
- ✅ **Current Setup**: Gmail SMTP with invalid credentials
- 🔄 **In Progress**: Implementing Gmail App Password support
- ⏳ **Pending**: OAuth2 implementation
- ⏳ **Pending**: Fallback email services
- ⏳ **Pending**: Enhanced error handling

## 📋 Step-by-Step Instructions

### For Gmail App Password (Easiest):

1. **Verify Gmail Account**: Make sure `almaryarostery@gmail.com` exists and you have access
2. **Enable 2FA**: Required for app passwords
3. **Generate App Password**:
   - Visit: https://myaccount.google.com/apppasswords
   - Select "Mail" → Generate
   - Copy the 16-character password
4. **Update .env**:
   ```bash
   SMTP_PASS=abcd efgh ijkl mnop  # Replace with actual app password
   ```
5. **Restart server**: `npm restart`

### For OAuth2 (Most Secure):

1. **Google Cloud Setup**:
   ```bash
   # Enable Gmail API
   gcloud services enable gmail.googleapis.com
   
   # Create OAuth2 credentials
   gcloud auth application-default login
   ```

2. **Generate Refresh Token**:
   - Use Google OAuth2 Playground
   - Authorize Gmail API
   - Exchange code for refresh token

3. **Update Configuration**:
   - Add OAuth2 credentials to .env
   - Modify emailService.js to use OAuth2

## 🔍 Troubleshooting

### Common Issues:

1. **"Invalid login" Error**:
   - Check if 2FA is enabled
   - Verify app password is correct
   - Ensure no spaces in password

2. **"Authentication failed" Error**:
   - Check if Gmail account is locked
   - Verify SMTP settings
   - Try different port (465 for SSL)

3. **"Rate limited" Error**:
   - Implement retry logic
   - Add delays between emails
   - Use email queue system

### Debug Commands:

```bash
# Test email configuration
curl -X POST http://localhost:5001/api/test-email

# Check environment variables
node -e "console.log(process.env.SMTP_USER, process.env.SMTP_PASS)"

# Verify SMTP connection
telnet smtp.gmail.com 587
```

## 🛠️ Enhanced Features (Planned)

1. **Multiple Provider Support**:
   - Gmail (App Password + OAuth2)
   - SendGrid
   - AWS SES
   - Maileroo

2. **Intelligent Fallback**:
   - Auto-switch on failure
   - Health monitoring
   - Rate limit handling

3. **Advanced Features**:
   - Email templates
   - Queue management
   - Analytics tracking
   - Bounce handling

## 📞 Support

If you need immediate email functionality:

1. **Quick Fix**: Update SMTP_PASS with Gmail app password
2. **Alternative**: Use simulation mode (already working)
3. **Long-term**: Implement OAuth2 or alternative service

## 🔐 Security Notes

- Never commit real credentials to Git
- Use environment variables only
- Rotate passwords regularly
- Monitor email sending logs
- Implement rate limiting

---

**Next Steps**: Follow Solution 1 for immediate fix, then implement Solution 2 for production security.

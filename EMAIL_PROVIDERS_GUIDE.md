# Alternative Email Service Configurations
# Choose ONE of the options below and update your .env file

# =============================================================================
# OPTION 1: Gmail App Password (Current Setup - Just needs password)
# =============================================================================
# 1. Enable 2FA on Gmail: https://myaccount.google.com/security
# 2. Generate App Password: https://myaccount.google.com/apppasswords
# 3. Replace SMTP_PASS in .env with your 16-character app password

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=almaryarostery@gmail.com
SMTP_PASS=your-16-char-app-password-here  # Replace this

# =============================================================================
# OPTION 2: SendGrid (Professional Email Service)
# =============================================================================
# 1. Sign up at: https://sendgrid.com
# 2. Create API key in Settings > API Keys
# 3. Add these to your .env:

# EMAIL_PROVIDER=sendgrid
# SENDGRID_API_KEY=SG.your-api-key-here

# =============================================================================
# OPTION 3: Maileroo (Alternative SMTP Service)
# =============================================================================
# 1. Sign up at: https://maileroo.com
# 2. Get SMTP credentials from dashboard
# 3. Replace current SMTP settings with:

# SMTP_HOST=smtp.maileroo.com
# SMTP_PORT=587
# SMTP_SECURE=false
# SMTP_USER=your-maileroo-username
# SMTP_PASS=your-maileroo-password

# =============================================================================
# OPTION 4: Gmail OAuth2 (Most Secure)
# =============================================================================
# 1. Create Google Cloud Project: https://console.cloud.google.com
# 2. Enable Gmail API
# 3. Create OAuth2 credentials
# 4. Add these to your .env:

# EMAIL_PROVIDER=oauth2
# GMAIL_USER=almaryarostery@gmail.com
# GMAIL_CLIENT_ID=your-client-id
# GMAIL_CLIENT_SECRET=your-client-secret
# GMAIL_REFRESH_TOKEN=your-refresh-token

# =============================================================================
# OPTION 5: AWS SES (Enterprise Solution)
# =============================================================================
# 1. Set up AWS SES: https://console.aws.amazon.com/ses
# 2. Verify domain/email
# 3. Create IAM user with SES permissions
# 4. Add these to your .env:

# EMAIL_PROVIDER=ses
# AWS_ACCESS_KEY_ID=your-access-key
# AWS_SECRET_ACCESS_KEY=your-secret-key
# AWS_REGION=us-east-1

# =============================================================================
# Testing Commands (run these after configuration)
# =============================================================================

# Test current configuration:
# curl http://localhost:5001/api/test/email-config -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Send test email:
# curl -X POST http://localhost:5001/api/test/send-email \
#      -H "Content-Type: application/json" \
#      -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
#      -d '{"to":"your-email@example.com"}'

# Check email service status:
# curl http://localhost:5001/api/test/email-status -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

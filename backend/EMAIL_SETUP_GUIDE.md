# Email Service Setup Guide

This guide will help you configure email services for your Qahwat Al Emarat application to send notifications, newsletters, and order confirmations.

## Overview
The warning you're seeing:
```
⚠️ Email configuration not complete. Email features will be simulated.
```

This happens because the email service needs SMTP configuration to send real emails.

## Email Service Options

### Option 1: Gmail SMTP (Easiest for Development)

**Requirements:**
- Gmail account
- App-specific password (recommended)

**Configuration:**
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=your-email@gmail.com
```

**Setup Steps:**
1. Enable 2-factor authentication on your Gmail account
2. Generate an app-specific password:
   - Google Account → Security → App passwords
   - Generate password for "Mail"
   - Use this password in `SMTP_PASS`

### Option 2: SendGrid (Recommended for Production)

**Why SendGrid:**
- High deliverability rates
- Professional email features
- Better for newsletters and bulk emails
- Free tier: 100 emails/day

**Setup Steps:**
1. Sign up at [SendGrid](https://sendgrid.com/)
2. Verify your domain (optional but recommended)
3. Create an API key:
   - Settings → API Keys → Create API Key
   - Full Access or Mail Send permissions

**Configuration:**
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### Option 3: AWS SES (Scalable Production)

**Why AWS SES:**
- Very cost-effective for high volume
- Excellent deliverability
- Integrates well with other AWS services

**Configuration:**
```bash
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-ses-smtp-username
SMTP_PASS=your-ses-smtp-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

**Setup Steps:**
1. Set up AWS SES in AWS Console
2. Verify your sending domain
3. Create SMTP credentials
4. Request production access (remove sandbox mode)

### Option 4: Mailgun

**Configuration:**
```bash
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-mailgun-user
SMTP_PASS=your-mailgun-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### Option 5: Maileroo (Recommended Alternative)

**Why Maileroo:**
- Excellent deliverability rates
- Simple setup and pricing
- Good for both transactional and marketing emails
- Reliable service with good support

**Configuration:**
```bash
SMTP_HOST=smtp.maileroo.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-maileroo-username
SMTP_PASS=your-maileroo-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

**Setup Steps:**
1. Sign up at [Maileroo](https://maileroo.com/)
2. Verify your account and domain (optional but recommended)
3. Get SMTP credentials from dashboard
4. Use the credentials in your environment variables

### Option 6: Custom SMTP Server

If you have your own mail server:
```bash
SMTP_HOST=mail.yourdomain.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-username
SMTP_PASS=your-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

## Environment Variables Reference

### Required Variables:
```bash
# SMTP Server Configuration
SMTP_HOST=smtp.example.com           # SMTP server hostname
SMTP_PORT=587                        # SMTP port (587 for TLS, 465 for SSL)
SMTP_SECURE=false                    # true for port 465, false for others
SMTP_USER=your-username              # SMTP authentication username
SMTP_PASS=your-password              # SMTP authentication password

# Email Branding
EMAIL_FROM_NAME=Qahwat Al Emarat     # Sender display name
EMAIL_FROM_ADDRESS=noreply@yourdomain.com  # Sender email address

# Application URLs (for email links)
BASE_URL=https://your-app.render.com # Base URL for verification links
```

## Render Deployment Configuration

### Add to Render Environment Variables:

1. Go to your Render service dashboard
2. Navigate to "Environment" tab  
3. Add these variables based on your chosen provider:

**Example for SendGrid:**
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=SG.your-sendgrid-api-key
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
BASE_URL=https://your-app.render.com
```

## Email Types Supported

Your application sends these types of emails:

### 1. Email Verification
- **Trigger:** New user registration
- **Content:** Email confirmation link
- **Template:** Built-in responsive design

### 2. Password Reset
- **Trigger:** User requests password reset
- **Content:** Secure reset link (1-hour expiry)
- **Template:** Built-in responsive design

### 3. Order Confirmations
- **Trigger:** New order placement
- **Content:** Order details, items, total
- **Template:** Formatted order summary

### 4. Newsletters
- **Trigger:** Admin sends newsletter
- **Content:** Custom HTML content
- **Features:** Batch sending, target audience

## Testing Email Configuration

### Backend Test Script

Create `backend/test-email.js`:
```javascript
const emailService = require('./services/emailService');

async function testEmail() {
  console.log('Testing email configuration...');
  
  // Test configuration
  const configTest = await emailService.testConfiguration();
  console.log('Configuration test:', configTest);
  
  // Test sending email
  const emailTest = await emailService.sendEmail({
    to: 'your-test-email@example.com',
    subject: 'Test Email from Qahwat Al Emarat',
    html: '<h1>Test Email</h1><p>If you receive this, email service is working!</p>'
  });
  
  console.log('Email send test:', emailTest);
}

testEmail().catch(console.error);
```

Run test:
```bash
cd backend
node test-email.js
```

### Manual Test via API

After deployment, test email endpoint:

```bash
# Test email verification
curl -X POST https://your-app.render.com/api/test/send-verification-email \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "token": "test-token"
  }'
```

## Domain Authentication (Recommended)

### For Production Use:

1. **Set up SPF Record:**
   ```
   TXT record: "v=spf1 include:sendgrid.net ~all"
   ```

2. **Set up DKIM:**
   - Configure with your email provider
   - Add DKIM DNS records

3. **Set up DMARC:**
   ```
   TXT record: "v=DMARC1; p=quarantine; rua=mailto:admin@yourdomain.com"
   ```

### Benefits:
- Better email deliverability
- Reduced spam classification
- Professional appearance
- Brand trust

## Email Templates Customization

### Modifying Templates

Email templates are in `backend/services/emailService.js`:

1. **Verification Email Template** (line ~117)
2. **Password Reset Template** (line ~157)
3. **Order Confirmation Template** (line ~197)

### Custom Branding

Update the HTML templates with:
- Your logo URL
- Brand colors
- Custom styling
- Contact information

### Example Customization:
```javascript
const html = `
  <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
    <div style="text-align: center; margin-bottom: 30px;">
      <img src="${process.env.BASE_URL}/assets/images/logo.png" alt="Qahwat Al Emarat" style="max-width: 200px;">
    </div>
    <!-- Your email content -->
  </div>
`;
```

## Monitoring and Analytics

### Email Metrics to Track:

1. **Delivery Rate:** Successfully delivered emails
2. **Open Rate:** Emails opened by recipients
3. **Click Rate:** Links clicked in emails
4. **Bounce Rate:** Failed deliveries
5. **Unsubscribe Rate:** Newsletter unsubscribes

### SendGrid Analytics

If using SendGrid:
- Dashboard → Statistics
- Track opens, clicks, bounces
- Set up event webhooks for real-time data

### Webhook Integration

Set up webhooks to track email events:
```javascript
// backend/routes/webhooks.js
router.post('/sendgrid', (req, res) => {
  const events = req.body;
  events.forEach(event => {
    console.log('Email event:', event.event, event.email);
    // Store in database or analytics
  });
  res.status(200).send('OK');
});
```

## Error Handling and Fallbacks

### Common Issues:

1. **Authentication Failed**
   - Check SMTP credentials
   - Verify account status
   - Check for rate limiting

2. **High Bounce Rate**
   - Verify email addresses
   - Check DNS configuration
   - Review email content for spam triggers

3. **Emails Going to Spam**
   - Set up domain authentication
   - Avoid spam keywords
   - Warm up IP address gradually

### Error Logging

Emails errors are logged with context:
```javascript
console.error('❌ Email send error:', {
  recipient: to,
  error: error.message,
  timestamp: new Date()
});
```

## Security Best Practices

1. **Secure Credentials:**
   - Use environment variables
   - Never commit SMTP passwords to Git
   - Rotate passwords regularly

2. **Rate Limiting:**
   - Implement sending limits
   - Use batch processing for newsletters
   - Add delays between batches

3. **Input Validation:**
   - Validate email addresses
   - Sanitize email content
   - Prevent email injection attacks

4. **Privacy Compliance:**
   - Include unsubscribe links
   - Respect user preferences
   - Comply with GDPR/local laws

## Expected Success Messages

After proper configuration, you should see:
```
✅ Email service configured successfully
📧 Email sent to user@example.com: message-id-12345
📧 Newsletter sent: 95/100 successful
```

Instead of:
```
⚠️ Email configuration not complete. Email features will be simulated.
📧 Simulating email send...
```

## Production Checklist

- [ ] Choose email service provider
- [ ] Set up account and authentication
- [ ] Configure environment variables in Render
- [ ] Test email sending functionality
- [ ] Set up domain authentication (SPF, DKIM, DMARC)
- [ ] Configure monitoring and alerts
- [ ] Test all email templates
- [ ] Verify newsletter functionality
- [ ] Check spam folder placement
- [ ] Monitor delivery rates

## Troubleshooting

### Debug Mode

Enable detailed logging:
```bash
NODE_ENV=development
DEBUG=nodemailer*
```

### Test Commands

```bash
# Test SMTP connection
telnet smtp.sendgrid.net 587

# Test DNS records
dig TXT yourdomain.com
```

### Common Error Messages

1. **"Invalid login"** → Check credentials
2. **"Connection timeout"** → Check firewall/network
3. **"Message rejected"** → Check content and sender reputation
4. **"Rate limit exceeded"** → Reduce sending frequency

## Support Resources

- **SendGrid:** [Documentation](https://docs.sendgrid.com/)
- **AWS SES:** [Developer Guide](https://docs.aws.amazon.com/ses/)
- **Nodemailer:** [Documentation](https://nodemailer.com/)

## Next Steps

1. Set up Firebase push notifications (see FIREBASE_SETUP_GUIDE.md)
2. Configure all environment variables
3. Test both services in production
4. Monitor service health and delivery rates

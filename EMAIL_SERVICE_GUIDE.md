# Email Service Configuration Guide

## Current Status
⚠️ Gmail SMTP is timing out on Render deployment
✅ App is running in **simulation mode** (emails are logged but not sent)
✅ App functionality is NOT affected - everything else works perfectly

## Why Gmail SMTP Fails on Render
1. **Port restrictions** - Render may block outbound SMTP ports
2. **IP blocking** - Gmail may block Render's shared IPs
3. **Security policies** - Gmail prefers OAuth2 for server connections

## Solutions

### Option 1: SendGrid (Recommended - Free tier available)
**Pros:**
- 100 emails/day free forever
- Excellent deliverability
- Works perfectly with Render
- Simple SMTP setup

**Setup:**
1. Sign up at https://sendgrid.com
2. Create an API key
3. Update environment variables in Render:
   ```
   SMTP_HOST=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_SECURE=false
   SMTP_USER=apikey
   SMTP_PASS=<your-sendgrid-api-key>
   EMAIL_FROM_ADDRESS=noreply@yourdomain.com
   ```

### Option 2: Mailgun (Good alternative)
**Pros:**
- 5,000 emails/month free for 3 months
- Reliable for transactional emails

**Setup:**
1. Sign up at https://mailgun.com
2. Verify your domain or use sandbox
3. Update environment variables:
   ```
   SMTP_HOST=smtp.mailgun.org
   SMTP_PORT=587
   SMTP_SECURE=false
   SMTP_USER=<your-mailgun-smtp-username>
   SMTP_PASS=<your-mailgun-smtp-password>
   ```

### Option 3: AWS SES (Best for scale)
**Pros:**
- Extremely cheap ($0.10 per 1000 emails)
- Highly scalable
- Best deliverability

**Setup:**
1. Create AWS account
2. Set up SES in your region
3. Verify sender email
4. Update environment variables

### Option 4: Keep Gmail (Try fixes)
**If you want to keep using Gmail:**

1. **Generate new App Password:**
   - Go to https://myaccount.google.com/security
   - Enable 2-Step Verification
   - Generate new App Password for "Mail"
   - Update SMTP_PASS in Render

2. **Try different port:**
   - Update SMTP_PORT to 465
   - Set SMTP_SECURE to true

3. **Allow less secure apps** (not recommended):
   - Go to https://myaccount.google.com/lesssecureapps
   - Enable access

## Current Impact

### ✅ Working Features (No Email Needed)
- User authentication (Firebase handles this)
- Browsing products
- Adding to cart
- Creating orders
- Admin panel
- All API endpoints

### ⚠️ Features Running in Simulation Mode
- Order confirmation emails (logged, not sent)
- Newsletter subscriptions (logged, not sent)
- Contact form submissions (logged, not sent)

## Recommendation

**For Production:** Use **SendGrid** (Option 1)
- Free tier is generous
- Takes 5 minutes to set up
- Works perfectly with Render
- Professional email deliverability

**For Testing:** Keep simulation mode
- No action needed
- Emails are logged in Render logs
- You can verify email content in logs

## How to Update on Render

1. Go to https://dashboard.render.com
2. Select your **almaryarostary** service
3. Go to **Environment** tab
4. Update these variables:
   - `SMTP_HOST`
   - `SMTP_PORT`
   - `SMTP_USER`
   - `SMTP_PASS`
5. Click **Save Changes**
6. Service will restart automatically

## Testing After Setup

Check Render logs after sending a test email:
```
✅ Email service verified successfully
📧 Email sent successfully to: customer@example.com
```

---

**Current Status: App is fully functional in simulation mode**
**Action Required: Optional - Set up transactional email service for production emails**

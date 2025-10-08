# Environment Variables Reference

Complete list of environment variables needed for Qahwat Al Emarat backend deployment on Render.

## Required Environment Variables

### Database Configuration
```bash
# MongoDB Connection
MONGODB_URI=***REMOVED***username:password@cluster.mongodb.net/qahwat_al_emarat?retryWrites=true&w=majority

# Database Settings
DB_NAME=qahwat_al_emarat
```

### Application Configuration
```bash
# Server Configuration
PORT=3000
NODE_ENV=production
BASE_URL=https://your-app.render.com

# Security
JWT_SECRET=your-super-secure-jwt-secret-key-minimum-32-characters
JWT_EXPIRE=7d
BCRYPT_SALT_ROUNDS=12

# Admin Configuration
ADMIN_EMAIL=admin@yourdomain.com
DEFAULT_ADMIN_PASSWORD=change-this-secure-password
```

### Firebase Configuration (Push Notifications)
```bash
# Firebase Admin SDK
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"your-project-id","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com","client_id":"...","auth_uri":"https://accounts.google.com/o/oauth2/auth","token_uri":"https://oauth2.googleapis.com/token","auth_provider_x509_cert_url":"https://www.googleapis.com/oauth2/v1/certs","client_x509_cert_url":"..."}

FIREBASE_PROJECT_ID=your-project-id
```

### Email Service Configuration
```bash
# SMTP Configuration (Choose one provider)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key

# Email Branding
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### File Upload Configuration
```bash
# Upload Limits
MAX_FILE_SIZE=10485760
UPLOAD_PATH=uploads
```

### API Rate Limiting
```bash
# Rate Limiting (requests per window)
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

## Optional Environment Variables

### Development/Debug
```bash
# Debug Logging
DEBUG=qahwat:*
LOG_LEVEL=info

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,https://yourdomain.com
```

### Analytics & Monitoring
```bash
# Analytics Keys (if using third-party services)
GOOGLE_ANALYTICS_ID=GA-XXXXX-X
MIXPANEL_TOKEN=your-mixpanel-token
```

### Payment Integration (Future)
```bash
# Stripe Configuration
STRIPE_PUBLIC_KEY=pk_live_...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# PayPal Configuration
PAYPAL_CLIENT_ID=your-paypal-client-id
PAYPAL_CLIENT_SECRET=your-paypal-client-secret
```

### Social Media Integration (Future)
```bash
# Social Login
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
```

## Provider-Specific Configurations

### Maileroo Email Setup (Recommended)
```bash
SMTP_HOST=smtp.maileroo.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-maileroo-username
SMTP_PASS=your-maileroo-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### SendGrid Email Setup
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=SG.your-sendgrid-api-key
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### Gmail SMTP Setup
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=your-email@gmail.com
```

### AWS SES Setup
```bash
SMTP_HOST=email-smtp.us-east-1.amazonaws.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your-ses-smtp-username
SMTP_PASS=your-ses-smtp-password
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

## Render Environment Variables Setup

### Method 1: Through Dashboard
1. Go to Render Dashboard → Your Service
2. Click "Environment" tab
3. Add each variable individually:
   - **Key:** Variable name (e.g., `MONGODB_URI`)
   - **Value:** Variable value
   - Click "Add" for each variable

### Method 2: Bulk Import
1. Create a `.env` file locally (DO NOT COMMIT):
```bash
MONGODB_URI=***REMOVED***...
JWT_SECRET=your-secret-key
FIREBASE_PROJECT_ID=your-project-id
# ... other variables
```

2. Copy and paste variables in Render dashboard

### Method 3: Via render.yaml
```yaml
services:
  - type: web
    name: qahwat-al-emarat-backend
    env: node
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 3000
      # Add other non-sensitive variables here
      # Use dashboard for sensitive data
```

## Security Best Practices

### 1. Sensitive Data Handling
- ✅ Use Render environment variables for sensitive data
- ❌ Never commit secrets to Git repository
- ✅ Use different secrets for different environments
- ✅ Rotate secrets regularly

### 2. JWT Secret Generation
```bash
# Generate secure JWT secret
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

### 3. Password Requirements
- Minimum 12 characters
- Include uppercase, lowercase, numbers, symbols
- Use password generators for admin accounts

### 4. Firebase Service Account
- Store complete JSON as single environment variable
- Ensure proper escaping of special characters
- Use project-specific service accounts

## Validation Checklist

### Before Deployment:
- [ ] All required variables are set
- [ ] Database connection string is valid
- [ ] JWT secret is secure (32+ characters)
- [ ] Firebase project ID matches your project
- [ ] Email SMTP credentials are tested
- [ ] Base URL matches your Render app URL
- [ ] No sensitive data in code repository

### Testing Variables:
```bash
# Test database connection
node -e "require('mongoose').connect(process.env.MONGODB_URI).then(() => console.log('DB Connected')).catch(console.error)"

# Test JWT secret
node -e "console.log('JWT Secret length:', process.env.JWT_SECRET?.length || 0)"

# Test Firebase configuration
node -e "console.log('Firebase configured:', !!process.env.FIREBASE_SERVICE_ACCOUNT_KEY)"

# Test email configuration
node -e "console.log('Email configured:', !!(process.env.SMTP_HOST && process.env.SMTP_USER))"
```

## Environment-Specific Configurations

### Development (.env.development)
```bash
NODE_ENV=development
PORT=3001
BASE_URL=http://localhost:3001
MONGODB_URI=mongodb://localhost:27017/qahwat_al_emarat_dev
LOG_LEVEL=debug
```

### Staging (.env.staging)
```bash
NODE_ENV=staging
PORT=3000
BASE_URL=https://qahwat-al-emarat-staging.render.com
MONGODB_URI=***REMOVED***...staging-cluster...
LOG_LEVEL=info
```

### Production (.env.production)
```bash
NODE_ENV=production
PORT=3000
BASE_URL=https://qahwat-al-emarat.render.com
MONGODB_URI=***REMOVED***...production-cluster...
LOG_LEVEL=warn
```

## Common Issues and Solutions

### 1. Firebase Service Account JSON Formatting
**Problem:** Invalid JSON format in environment variable
**Solution:** 
- Ensure JSON is on single line
- Properly escape quotes and newlines
- Use online JSON validators

### 2. MongoDB Connection Issues
**Problem:** Connection timeout or authentication failure
**Solution:**
- Verify connection string format
- Check network access in MongoDB Atlas
- Ensure user has proper permissions

### 3. Email Authentication Failure
**Problem:** SMTP authentication errors
**Solution:**
- Verify credentials with email provider
- Check if 2FA requires app passwords
- Test SMTP settings locally first

### 4. JWT Token Issues
**Problem:** Token validation failures
**Solution:**
- Ensure JWT_SECRET is same across all instances
- Verify secret is long enough (32+ characters)
- Check for whitespace in secret

## Environment Variables Backup

### Export Current Variables (Local Development)
```bash
# Export to file
printenv | grep -E "^(MONGODB_URI|JWT_SECRET|FIREBASE_|SMTP_)" > backup.env

# Or use this script
node -e "
const keys = ['MONGODB_URI', 'JWT_SECRET', 'FIREBASE_PROJECT_ID', 'SMTP_HOST'];
keys.forEach(key => {
  if (process.env[key]) {
    console.log(\`\${key}=\${process.env[key]}\`);
  }
});
"
```

### Render Variables Backup
- Export from Render Dashboard
- Save in secure password manager
- Document which variables are in which environment

## Next Steps

1. Set up development environment variables locally
2. Configure staging environment for testing
3. Set up production environment variables in Render
4. Test each service individually
5. Run full integration tests
6. Monitor application health after deployment

## Support

If you encounter issues with environment variables:
1. Check Render deployment logs
2. Verify variable names match exactly
3. Test variables locally first
4. Use Render support for platform-specific issues

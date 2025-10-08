# 🚀 Quick Deployment Checklist

## Pre-Deployment Checklist

- [ ] **Code is committed and pushed to GitHub**
- [ ] **MongoDB Atlas database is set up**
- [ ] **Firebase project created (for push notifications)**
- [ ] **Email service configured (SendGrid/Gmail/etc.)**
- [ ] **Environment variables are documented**
- [ ] **package.json has correct start script**
- [ ] **Health check endpoint exists**

## Render Deployment Steps

### 1. Create Render Account
- [ ] Sign up at [render.com](https://render.com)
- [ ] Connect your GitHub account

### 2. Create Web Service
- [ ] Click "New +" → "Web Service"
- [ ] Select your GitHub repository
- [ ] Set root directory to `backend`

### 3. Configure Service
```
Name: qahwat-al-emarat-api
Runtime: Node
Build Command: npm install
Start Command: npm start
```

### 4. Set Environment Variables

**Critical Configuration:**
```bash
# Database
MONGODB_URI=***REMOVED***username:password@cluster.mongodb.net/qahwat_al_emarat

# Security
JWT_SECRET=your-super-secure-32-plus-character-secret-key
JWT_EXPIRE=7d

# Application
BASE_URL=https://your-app.onrender.com
```

**Firebase Push Notifications (Required for notifications):**
```bash
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"..."}
FIREBASE_PROJECT_ID=your-firebase-project-id
```

**Email Service (Required for user verification/notifications):**
```bash
# For SendGrid (Recommended)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=SG.your-sendgrid-api-key

# Branding
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=noreply@yourdomain.com
```

**⚠️ Configuration Guides:**
- See `FIREBASE_SETUP_GUIDE.md` for Firebase setup
- See `EMAIL_SETUP_GUIDE.md` for email service setup
- See `ENVIRONMENT_VARIABLES.md` for complete reference

### 5. Deploy & Test
- [ ] Click "Create Web Service"
- [ ] Monitor logs for successful deployment
- [ ] Verify service startup messages:
  - ✅ MongoDB connected successfully
  - ✅ Firebase Admin SDK initialized successfully
  - ✅ Email service configured successfully
- [ ] Test API endpoints:
  - `GET /health` - Health check
  - `GET /` - API info
  - `POST /api/auth/register` - Test registration

### 6. Verify Service Configuration
- [ ] **Firebase:** No "simulated" messages in logs
- [ ] **Email:** No "simulated" messages in logs
- [ ] **Database:** Connection successful without errors
- [ ] **Logs:** Check for any warning messages

## Post-Deployment

### Update Flutter App
Update your API base URL in Flutter:

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://your-service-name.onrender.com';
  static const String apiUrl = '$baseUrl/api';
}
```

### Monitor & Maintain
- [ ] Set up monitoring alerts
- [ ] Monitor database performance
- [ ] Keep dependencies updated
- [ ] Monitor API usage and errors

## Useful URLs

- **Render Dashboard**: https://dashboard.render.com
- **Your API**: https://your-service-name.onrender.com
- **Health Check**: https://your-service-name.onrender.com/health
- **MongoDB Atlas**: https://cloud.mongodb.com

## Common Issues

1. **Build Fails**: Check Node.js version in package.json engines
2. **Database Connection**: Verify MongoDB URI and IP whitelist
3. **Environment Variables**: Ensure all required vars are set
4. **CORS Errors**: Configure CORS for your Flutter app domain

## Emergency Commands

```bash
# Local testing
npm install
npm start

# Check logs
# (View in Render dashboard → Service → Logs)

# Force redeploy
git commit --allow-empty -m "Force redeploy"
git push origin main
```

---

**🎉 Ready to deploy! Your backend will be live in ~5 minutes.**

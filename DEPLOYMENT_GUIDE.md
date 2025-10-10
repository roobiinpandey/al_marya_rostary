# 🚀 Deployment Guide for Qahwat Al Emarat

## 📋 Overview

This guide covers deploying your Node.js backend and Flutter app to various platforms.

## 🔧 Environment Variables Setup

### Required Environment Variables

Copy `.env.example` to `.env` and configure these variables:

#### Database Configuration
- `MONGODB_URI`: Your MongoDB Atlas connection string
- `MONGODB_ATLAS_PUBLIC_KEY`: MongoDB Atlas API public key
- `MONGODB_ATLAS_PRIVATE_KEY`: MongoDB Atlas API private key

#### Authentication
- `JWT_SECRET`: Strong JWT secret (min 32 characters)
- `JWT_EXPIRE`: JWT token expiration (e.g., "7d")
- `JWT_REFRESH_SECRET`: JWT refresh token secret
- `JWT_REFRESH_EXPIRE`: Refresh token expiration (e.g., "30d")

#### Firebase Configuration
- `FIREBASE_SERVICE_ACCOUNT_KEY`: Firebase service account JSON (single line)
- `FIREBASE_PROJECT_ID`: Your Firebase project ID

#### Application Settings
- `NODE_ENV`: production or development
- `PORT`: Server port (default: 5001)
- `BASE_URL`: Your deployed backend URL
- `FRONTEND_URL`: Your frontend URL
- `ADMIN_USERNAME`: Admin panel username
- `ADMIN_PASSWORD`: Admin panel password

#### Email Configuration (Optional)
- `EMAIL_FROM_NAME`: Sender name for emails
- `EMAIL_FROM_ADDRESS`: Sender email address
- `SMTP_HOST`: SMTP server host
- `SMTP_PORT`: SMTP server port
- `SMTP_USER`: SMTP username
- `SMTP_PASS`: SMTP password

## 🌐 Hosting Platforms

### 1. Render (Current Setup)
1. Connect your GitHub repository
2. Set environment variables in Render dashboard
3. Deploy from main branch

**Render Dashboard:** https://dashboard.render.com/

### 2. Vercel (Recommended Alternative)
```bash
npm install -g vercel
cd backend
vercel
```

### 3. Railway
```bash
npm install -g @railway/cli
railway login
railway deploy
```

### 4. Firebase Hosting + Cloud Functions
```bash
npm install -g firebase-tools
firebase init functions
firebase deploy
```

## 📱 Flutter App Deployment

### Android (Google Play Store)
1. Build release APK: `flutter build apk --release`
2. Generate app bundle: `flutter build appbundle --release`
3. Upload to Google Play Console

### iOS (App Store)
1. Build iOS app: `flutter build ios --release`
2. Open in Xcode and archive
3. Upload to App Store Connect

### Web (Netlify/Vercel/Firebase)
1. Build web app: `flutter build web`
2. Deploy `build/web` folder to hosting platform

## 🔐 Security Checklist

- [ ] Environment variables set correctly
- [ ] .env file not committed to Git
- [ ] Firebase service account secured
- [ ] MongoDB Atlas IP whitelist configured
- [ ] Strong JWT secrets used
- [ ] HTTPS enabled in production
- [ ] CORS configured properly

## 🧪 Testing Deployment

### Backend Health Check
```bash
curl https://your-backend-url.com/health
```

### API Endpoints Test
```bash
# Test coffee endpoint
curl https://your-backend-url.com/api/coffees

# Test auth endpoint
curl https://your-backend-url.com/api/auth/register
```

### Flutter App Configuration
Update `lib/core/constants/app_constants.dart`:
```dart
static const bool _useProduction = true; // Set to true for production
static const String baseUrl = 'https://your-backend-url.com';
```

## 📊 Monitoring

### Backend Logs
- Check hosting platform logs for errors
- Monitor MongoDB Atlas performance
- Track Firebase usage

### App Performance
- Use Firebase Analytics
- Monitor crash reports
- Track user engagement

## 🛠️ Troubleshooting

### Common Issues

1. **MongoDB Connection Failed**
   - Check connection string format
   - Verify IP whitelist (0.0.0.0/0 for cloud platforms)
   - Ensure database user has proper permissions

2. **Firebase Initialization Failed**
   - Verify service account key format (single line JSON)
   - Check project ID matches
   - Ensure Firebase project is active

3. **CORS Issues**
   - Update FRONTEND_URL environment variable
   - Check CORS middleware configuration
   - Verify allowed origins

4. **JWT Errors**
   - Ensure JWT_SECRET is at least 32 characters
   - Check token expiration settings
   - Verify secret consistency across deployments

## 📞 Support

For deployment issues:
1. Check hosting platform documentation
2. Review environment variables
3. Check application logs
4. Verify database connectivity

## 📚 Additional Resources

- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Express.js Production Best Practices](https://expressjs.com/en/advanced/best-practice-performance.html)

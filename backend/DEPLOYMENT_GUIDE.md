# 🚀 Render Deployment Guide for Qahwat Al Emarat Backend

## Prerequisites

1. ✅ **GitHub Account** - Your code should be in a GitHub repository
2. ✅ **Render Account** - Sign up at [render.com](https://render.com)
3. ✅ **MongoDB Atlas** - Set up a cloud MongoDB database

---

## Step 1: Prepare Your Repository

### Push Backend to GitHub

```bash
# Navigate to your backend directory
cd "/Volumes/PERSONAL/Qahwat Al Emarat APP/qahwat_al_emarat"

# Add all changes
git add .

# Commit changes
git commit -m "Prepare backend for Render deployment"

# Push to GitHub
git push origin main
```

---

## Step 2: Set Up MongoDB Atlas (if not done already)

1. Go to [MongoDB Atlas](https://cloud.mongodb.com)
2. Create a new cluster (free tier available)
3. Set up database access:
   - Create a database user with read/write permissions
   - Add your IP to the whitelist (or use 0.0.0.0/0 for all IPs)
4. Get your connection string:
   ```
   ***REMOVED***username:password@cluster.mongodb.net/database_name?retryWrites=true&w=majority
   ```

---

## Step 3: Deploy on Render

### 3.1 Create New Web Service

1. **Login to Render**: Go to [render.com](https://render.com) and sign in
2. **New Web Service**: Click "New +" → "Web Service"
3. **Connect Repository**: 
   - Connect your GitHub account
   - Select your `***REMOVED***` repository
   - Choose the `backend` folder as the root directory

### 3.2 Configure Service Settings

**Basic Settings:**
- **Name**: `qahwat-al-emarat-api`
- **Region**: Choose closest to your users
- **Branch**: `main`
- **Root Directory**: `backend`

**Build Settings:**
- **Runtime**: `Node`
- **Build Command**: `npm install`
- **Start Command**: `npm start`

**Instance Type:**
- **Plan**: `Free` (for testing) or `Starter` (for production)

### 3.3 Configure Environment Variables

Add these environment variables in Render dashboard:

| Key | Value | Notes |
|-----|--------|--------|
| `NODE_ENV` | `production` | Required |
| `MONGODB_URI` | `***REMOVED***...` | Your MongoDB Atlas connection string |
| `JWT_SECRET` | `your-super-secret-key` | Generate a strong secret |
| `JWT_EXPIRE` | `7d` | Token expiration time |
| `JWT_REFRESH_SECRET` | `another-secret-key` | Refresh token secret |
| `JWT_REFRESH_EXPIRE` | `30d` | Refresh token expiration |

**Generate Strong Secrets:**
```bash
# In your terminal, generate random secrets:
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

---

## Step 4: Deploy and Test

### 4.1 Deploy Service

1. Click **"Create Web Service"**
2. Render will automatically:
   - Clone your repository
   - Install dependencies
   - Start your application
   - Provide you with a URL like: `https://qahwat-al-emarat-api.onrender.com`

### 4.2 Monitor Deployment

- Watch the **Logs** tab for any errors
- Check the **Events** tab for deployment status
- Service should show as "Live" when ready

### 4.3 Test Your API

Test your deployed API:

```bash
# Health check
curl https://your-app-name.onrender.com/health

# Test registration (example)
curl -X POST https://your-app-name.onrender.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com", 
    "password": "password123"
  }'
```

---

## Step 5: Configure Your Flutter App

Update your Flutter app to use the Render URL:

```dart
// In your Flutter app's API configuration
class ApiConfig {
  static const String baseUrl = 'https://your-app-name.onrender.com';
  static const String apiUrl = '$baseUrl/api';
}
```

---

## Common Issues & Solutions

### Issue 1: Build Fails
**Solution**: Check the logs for missing dependencies or Node version issues.

### Issue 2: Database Connection Fails
**Solution**: 
- Verify MongoDB URI is correct
- Ensure MongoDB Atlas allows connections from all IPs (0.0.0.0/0)
- Check if environment variables are set correctly

### Issue 3: App Crashes on Startup
**Solution**:
- Check environment variables are properly set
- Ensure all required dependencies are in package.json
- Review server logs for specific error messages

### Issue 4: CORS Errors from Flutter App
**Solution**: Update CORS settings in your Express app:

```javascript
app.use(cors({
  origin: ['https://your-flutter-web-app.com', 'http://localhost:3000'],
  credentials: true
}));
```

---

## Performance Tips

1. **Free Tier Limitations**: 
   - Render free tier spins down after 15 minutes of inactivity
   - First request after spin-down will be slow (cold start)

2. **Upgrade to Starter Plan** ($7/month):
   - No spin-down
   - Faster performance
   - Custom domains
   - SSL certificates

3. **Database Optimization**:
   - Use connection pooling
   - Implement proper indexing
   - Monitor MongoDB Atlas performance metrics

---

## Security Checklist

- ✅ Strong JWT secrets
- ✅ HTTPS enabled (automatic with Render)
- ✅ Environment variables secured
- ✅ CORS properly configured
- ✅ Rate limiting implemented (recommended)
- ✅ Input validation on all endpoints

---

## Monitoring & Maintenance

1. **Logs**: Monitor Render logs for errors
2. **Uptime**: Set up monitoring services
3. **Database**: Monitor MongoDB Atlas metrics
4. **Updates**: Keep dependencies updated

---

## Auto-Deployment

Render automatically deploys when you push to your main branch:

```bash
# Make changes to your backend
git add .
git commit -m "Update API endpoints"
git push origin main
# Render automatically rebuilds and deploys!
```

---

## Useful Commands

```bash
# View logs locally
npm run dev

# Test production build locally  
NODE_ENV=production npm start

# Check for vulnerabilities
npm audit

# Update dependencies
npm update
```

---

## Support

If you encounter issues:

1. Check Render documentation: [docs.render.com](https://docs.render.com)
2. Review deployment logs in Render dashboard
3. Test API endpoints with Postman or curl
4. Check MongoDB Atlas connection and metrics

---

**🎉 Your backend is now deployed and accessible worldwide!**

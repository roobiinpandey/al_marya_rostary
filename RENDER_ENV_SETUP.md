# 🚀 Render Environment Variables Setup Guide

## Overview
This guide shows you how to configure all required environment variables in Render for the Al Marya Rostery backend.

**🔒 IMPORTANT:** Get the actual values from your local `backend/.env` file. Never commit the `.env` file to git.

---

## 📋 Required Environment Variables

### 1. Application Settings
```bash
NODE_ENV=production
PORT=5001
```

### 2. MongoDB Configuration
```bash
MONGODB_URI=<copy from your .env file>
MONGODB_ATLAS_PUBLIC_KEY=<copy from your .env file>
MONGODB_ATLAS_PRIVATE_KEY=<copy from your .env file>
```

### 3. JWT Configuration
```bash
JWT_SECRET=<copy from your .env file>
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=<copy from your .env file>
JWT_REFRESH_EXPIRE=30d
```

### 4. CORS and URLs
```bash
FRONTEND_URL=http://localhost:3000
BASE_URL=https://almaryarostery.onrender.com
```

### 5. Admin Panel
```bash
ADMIN_USERNAME=<copy from your .env file>
ADMIN_PASSWORD=<copy from your .env file>
```

### 6. Firebase Configuration
```bash
FIREBASE_PROJECT_ID=<copy from your .env file>
FIREBASE_SERVICE_ACCOUNT_KEY=<copy entire JSON from your .env file>
```

### 7. Email Configuration (SMTP)
```bash
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=<copy from your .env file>
SMTP_PASS=<copy from your .env file>
EMAIL_FROM_NAME=Al Marya Rostery
EMAIL_FROM_ADDRESS=<copy from your .env file>
```

### 8. QR Code Security
```bash
QR_SECRET=<copy from your .env file>
```

### 9. Cloudinary Configuration
```bash
CLOUDINARY_CLOUD_NAME=<copy from your .env file>
CLOUDINARY_API_KEY=<copy from your .env file>
CLOUDINARY_API_SECRET=<copy from your .env file>
```

### 10. ⚡ **STRIPE CONFIGURATION** (CRITICAL - Currently Missing in Render)
```bash
STRIPE_PUBLISHABLE_KEY=<copy from your .env file - starts with pk_test_>
STRIPE_SECRET_KEY=<copy from your .env file - starts with sk_test_>
STRIPE_WEBHOOK_SECRET=whsec_temporary_will_create_after_deployment
```

---

## 🔧 How to Add Environment Variables in Render

### Step 1: Access Your Render Dashboard
1. Go to https://dashboard.render.com
2. Navigate to your backend service
3. Click on your service name

### Step 2: Navigate to Environment Variables
1. In the left sidebar, click **"Environment"**
2. Or go to the **"Environment"** tab at the top

### Step 3: Add Missing Variables
For **EACH** variable listed above:

1. Click **"Add Environment Variable"**
2. **Key**: Enter the variable name (e.g., `STRIPE_SECRET_KEY`)
3. **Value**: Paste the corresponding value from above
4. Click **"Save Changes"**

### Step 4: Verify All Variables Are Added
Make sure you have **ALL** of these variables:

#### ✅ Checklist:
- [ ] `NODE_ENV`
- [ ] `PORT`
- [ ] `MONGODB_URI`
- [ ] `MONGODB_ATLAS_PUBLIC_KEY`
- [ ] `MONGODB_ATLAS_PRIVATE_KEY`
- [ ] `JWT_SECRET`
- [ ] `JWT_EXPIRE`
- [ ] `JWT_REFRESH_SECRET`
- [ ] `JWT_REFRESH_EXPIRE`
- [ ] `FRONTEND_URL`
- [ ] `BASE_URL`
- [ ] `ADMIN_USERNAME`
- [ ] `ADMIN_PASSWORD`
- [ ] `FIREBASE_PROJECT_ID`
- [ ] `FIREBASE_SERVICE_ACCOUNT_KEY`
- [ ] `SMTP_HOST`
- [ ] `SMTP_PORT`
- [ ] `SMTP_SECURE`
- [ ] `SMTP_USER`
- [ ] `SMTP_PASS`
- [ ] `EMAIL_FROM_NAME`
- [ ] `EMAIL_FROM_ADDRESS`
- [ ] `QR_SECRET`
- [ ] `CLOUDINARY_CLOUD_NAME`
- [ ] `CLOUDINARY_API_KEY`
- [ ] `CLOUDINARY_API_SECRET`
- [ ] **`STRIPE_PUBLISHABLE_KEY`** ⚠️ **CRITICAL - Currently Missing**
- [ ] **`STRIPE_SECRET_KEY`** ⚠️ **CRITICAL - Currently Missing**
- [ ] **`STRIPE_WEBHOOK_SECRET`** ⚠️ **CRITICAL - Currently Missing**

### Step 5: Redeploy Your Service
After adding all variables:

1. Click **"Manual Deploy"** at the top
2. Select **"Deploy latest commit"**
3. Wait for deployment to complete (3-5 minutes)

---

## 🎯 Priority Variables (Must Fix Immediately)

### **CRITICAL - Missing Stripe Variables Causing Deployment Failure:**

**Copy these from your `backend/.env` file:**

```bash
STRIPE_PUBLISHABLE_KEY=<starts with pk_test_ - copy from your .env>
STRIPE_SECRET_KEY=<starts with sk_test_ - copy from your .env>
STRIPE_WEBHOOK_SECRET=whsec_temporary_will_create_after_deployment
```

**These 3 variables are REQUIRED for:**
- Order cancellation with refunds
- Payment processing
- Stripe webhook handling

---

## 📝 Quick Copy Instructions

### How to Get Values from Your .env File:

1. Open your terminal
2. Navigate to backend directory:
   ```bash
   cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend"
   ```
3. View your .env file:
   ```bash
   cat .env
   ```
4. Copy each value carefully (including the entire JSON for Firebase)

---

## 🔍 Verify Configuration

After deployment completes, check your logs:

```bash
# Should see this in Render logs:
✅ Stripe initialized successfully
✅ Payment routes configured
```

### If You See Errors:
```bash
❌ Error: Neither apiKey nor config.authenticator provided
```

**Solution:** Double-check that `STRIPE_SECRET_KEY` is set correctly in Render environment variables.

---

## 🚨 Important Notes

1. **Never commit `.env` file to git** - It's already in `.gitignore`
2. **Use TEST keys for development** - Keys shown above are test keys
3. **Replace with LIVE keys before production** - Contact Stripe for live keys
4. **Firebase keys are JSON** - Make sure the entire JSON object is copied as one value
5. **Webhook secret will change** - Update `STRIPE_WEBHOOK_SECRET` after setting up webhooks in Stripe dashboard

---

## 🔗 Quick Links

- **Render Dashboard**: https://dashboard.render.com
- **Stripe Dashboard**: https://dashboard.stripe.com/test/apikeys
- **MongoDB Atlas**: https://cloud.mongodb.com
- **Cloudinary Console**: https://console.cloudinary.com
- **Firebase Console**: https://console.firebase.google.com

---

## 📞 Support

If deployment still fails after adding variables:
1. Check Render logs for specific error messages
2. Verify each variable has the correct value (no extra spaces)
3. Make sure JSON values (like `FIREBASE_SERVICE_ACCOUNT_KEY`) are properly formatted
4. Redeploy after making changes

---

## ✅ Expected Result

After adding all variables and redeploying, you should see:

```bash
✅ Environment validation passed!
✅ Stripe initialized successfully
✅ Firebase initialized successfully
✅ MongoDB connected successfully
✅ Email service configured
🚀 Server running on port 5001
```

Your Order Cancellation feature with Stripe refunds will now work correctly! 🎉

# Render Environment Variables Checklist

## ✅ **Required Environment Variables for Render Deployment**

### **🔒 Authentication & Security**
```
NODE_ENV=production
JWT_SECRET=qahwat_al_emarat_jwt_secret_key_2025
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=qahwat_al_emarat_refresh_secret_key_2025
JWT_REFRESH_EXPIRE=30d
```

### **🗄️ Database Configuration**
```
MONGODB_URI=***REMOVED******REMOVED***:Nepal1590@***REMOVED***.ph5cazq.mongodb.net/qahwat_al_emarat?retryWrites=true&w=majority&appName=***REMOVED***
```

### **🌐 Application URLs**
```
BASE_URL=https://***REMOVED***.onrender.com
FRONTEND_URL=http://localhost:3000
```

### **🔥 Firebase Configuration**
```
FIREBASE_PROJECT_ID=***REMOVED***
FIREBASE_SERVICE_ACCOUNT_KEY={"type":"service_account","project_id":"***REMOVED***",...} // Full JSON from .env
```

### **📧 Email Service (SMTP) - NEWLY RESTORED**
```
SMTP_HOST=in-v3.mailjet.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=bb7684ba15f7f8946cd9ffa6bd2391e5
SMTP_PASS=7d7ef8d04cbb51629cc30eb5ec4b9f46
EMAIL_FROM_NAME=Qahwat Al Emarat
EMAIL_FROM_ADDRESS=bb7684ba15f7f8946cd9ffa6bd2391e5@mailjet.com
```

### **👥 Admin Panel**
```
ADMIN_USERNAME=admin
ADMIN_PASSWORD=qahwat2024
```

## **🚀 Deployment Steps:**

1. ✅ **Code pushed to GitHub** - Auto-deployment triggered
2. ⚠️ **Verify environment variables** in Render dashboard
3. 🔍 **Monitor deployment logs** in Render
4. 🧪 **Test deployment** at https://***REMOVED***.onrender.com

## **🔧 Important Updates in This Deployment:**

### **Pricing Fix** 
- ✅ Fixed coffee product pricing display bug
- ✅ Corrected per-kg price calculation logic
- ✅ Added variant-aware pricing system

### **Email Service Restoration**
- ✅ Restored SMTP email configuration  
- ✅ Fixed email service initialization
- ✅ Enabled order confirmations and newsletters

### **Web Portal Enhancement**
- ✅ Updated admin portal homepage
- ✅ Integrated login form design
- ✅ Improved user experience

## **📋 Post-Deployment Verification:**

1. **Health Check:** `GET https://***REMOVED***.onrender.com/health`
2. **API Status:** `GET https://***REMOVED***.onrender.com/api/coffees`
3. **Admin Panel:** `https://***REMOVED***.onrender.com/admin.html`
4. **Email Test:** Check if email service shows "configured" in logs

## **🆘 Troubleshooting:**

If deployment fails:
1. Check Render build logs
2. Verify all environment variables are set
3. Ensure MongoDB URI is accessible from Render
4. Check Firebase service account JSON format

---
**Last Updated:** October 10, 2025
**Deployment Status:** ✅ Ready for production

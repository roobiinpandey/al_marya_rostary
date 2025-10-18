# 🚨 Render.com Bad Gateway - Troubleshooting Guide

**Error:** `Bad Gateway - This service is currently unavailable`  
**Request ID:** `99071704d80923e5-DXB`  
**Time:** October 18, 2025

---

## 🔍 What "Bad Gateway" Means

A 502 Bad Gateway error on Render.com means:
- ✅ Render's infrastructure is working
- ❌ Your application is NOT responding
- ⚠️ The server is either:
  - Still starting up
  - Failed to start
  - Crashed after starting
  - Not binding to the correct port

---

## 📊 Immediate Diagnostics

### Step 1: Check Deployment Status

1. **Go to Render Dashboard:**
   ```
   https://dashboard.render.com/
   ```

2. **Find your service:**
   - Service name: `al-marya-rostery-production` (or similar)
   - Should show deployment status

3. **Check deployment state:**
   - 🟢 **Live** = Good, but still getting 502
   - 🟡 **Deploying** = Wait 2-5 more minutes
   - 🔴 **Failed** = Build or start failed
   - ⚪ **Not Started** = Service not running

### Step 2: Check Logs

1. **In Render Dashboard, click your service**

2. **Click "Logs" tab**

3. **Look for these patterns:**

#### ✅ **Good Signs:**
```
✅ MongoDB Connected
✅ Server running on port 10000
✅ Health check endpoints configured
🎉 Al Marya Rostery Server Started Successfully!
```

#### ❌ **Bad Signs:**
```
❌ Error: Cannot find module
❌ MongoDB connection error
❌ FATAL: JWT_SECRET environment variable is not set
❌ Error: listen EADDRINUSE: address already in use :::10000
❌ Process exited with code 1
```

---

## 🔧 Common Issues & Fixes

### Issue 1: Service Still Starting Up ⏳

**Symptoms:**
- Deployment shows "Deploying" or just finished
- Logs show build completed
- No error messages yet

**Solution:**
- **Wait 3-5 minutes** - First deployments take longer
- Render needs to:
  1. Pull code from GitHub ✅
  2. Install dependencies (npm ci)
  3. Run build command
  4. Start the server
  5. Wait for health check to pass

**Check:**
```bash
# Monitor deployment every 30 seconds
# Refresh the Render dashboard logs
```

---

### Issue 2: Missing Environment Variables ⚠️

**Symptoms:**
```
FATAL: JWT_SECRET environment variable is not set
MongoDB connection error: Authentication failed
```

**Solution:**

1. **Go to Render Dashboard → Your Service → Environment**

2. **Verify these REQUIRED variables are set:**

```bash
# Database (CRITICAL)
MONGODB_URI=***REMOVED***qahwat_prod_user:PASSWORD@***REMOVED***.ph5cazq.mongodb.net/qahwat_al_emarat

# Security (CRITICAL)
JWT_SECRET=<64-char-secret>
JWT_REFRESH_SECRET=<64-char-secret>
ADMIN_USERNAME=admin
ADMIN_PASSWORD=<strong-password>

# URLs (CRITICAL)
BASE_URL=https://al-marya-rostary.onrender.com
FRONTEND_URL=https://your-flutter-app-url.com

# Firebase (CRITICAL)
FIREBASE_PROJECT_ID=***REMOVED***
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@***REMOVED***.iam.gserviceaccount.com

# Node Environment
NODE_ENV=production
PORT=10000
```

3. **If any are missing, add them**

4. **Click "Save" - This will trigger a new deployment**

---

### Issue 3: Port Binding Issue 🔌

**Symptoms:**
```
Error: listen EADDRINUSE: address already in use :::10000
Server failed to start on port 10000
```

**Solution:**

Check `server.js` uses Render's PORT:

```javascript
// ✅ CORRECT
const PORT = process.env.PORT || 5001;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

// ❌ WRONG
app.listen(5001, 'localhost', () => { // Don't hardcode port or localhost
  console.log('Server running');
});
```

**Render requires:**
- Port from `process.env.PORT` (they set it to 10000)
- Bind to `0.0.0.0` not `localhost` or `127.0.0.1`

---

### Issue 4: Build Failed 🛠️

**Symptoms:**
```
npm ERR! code ERESOLVE
npm ERR! ERESOLVE unable to resolve dependency tree
Build failed
```

**Solution:**

1. **Check package.json dependencies:**
   ```bash
   # All dependencies must be in "dependencies" not "devDependencies"
   # for Render's --only=production install
   ```

2. **Verify Node version:**
   ```json
   "engines": {
     "node": ">=20.0.0",
     "npm": ">=10.0.0"
   }
   ```

3. **Check render.yaml build command:**
   ```yaml
   buildCommand: |
     npm ci --only=production
     node scripts/generateSecrets.js
   ```

4. **If build fails, simplify:**
   ```yaml
   buildCommand: npm install --production
   ```

---

### Issue 5: MongoDB Connection Failed 🗄️

**Symptoms:**
```
MongoDB connection error: Authentication failed
MongoDB connection timeout
Could not connect to any servers in your MongoDB Atlas cluster
```

**Solution:**

1. **Check MongoDB Atlas Network Access:**
   - Go to: https://cloud.mongodb.com
   - Navigate: Network Access
   - **Add:** `0.0.0.0/0` (Allow from anywhere)
   - Or add Render's IPs specifically

2. **Verify Connection String:**
   ```bash
   # Should look like:
   ***REMOVED***USERNAME:PASSWORD@cluster.mongodb.net/DATABASE?retryWrites=true&w=majority
   
   # Check:
   ✅ Username is correct
   ✅ Password is URL-encoded (no special chars or encode them)
   ✅ Cluster address is correct
   ✅ Database name is correct
   ```

3. **Test Connection String:**
   ```bash
   # From your local machine:
   mongosh "***REMOVED***USER:PASS@cluster.mongodb.net/DB"
   ```

4. **URL-encode special characters in password:**
   ```bash
   # If password is: P@ssw0rd!
   # Encode to: P%40ssw0rd%21
   
   @ → %40
   ! → %21
   # → %23
   $ → %24
   ```

---

### Issue 6: Firebase Configuration Issue 🔥

**Symptoms:**
```
Firebase Admin SDK initialization failed
Could not load the default credentials
```

**Solution:**

1. **Check FIREBASE_PRIVATE_KEY format:**
   ```bash
   # Must have literal \n characters:
   -----BEGIN PRIVATE KEY-----\nMIIEv...\n-----END PRIVATE KEY-----
   
   # NOT actual newlines (in Render dashboard, enter as one line)
   ```

2. **Verify Firebase env vars:**
   ```bash
   FIREBASE_PROJECT_ID=***REMOVED***
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@***REMOVED***.iam.gserviceaccount.com
   FIREBASE_PRIVATE_KEY=<full-key-with-\n>
   ```

---

### Issue 7: Health Check Failing ❤️

**Symptoms:**
- Service shows "Live" then goes back to error
- Logs show server started but health check fails
- 502 appears shortly after deployment

**Solution:**

1. **Verify health check endpoint exists:**
   ```javascript
   // server.js or routes/health.js
   app.get('/health', (req, res) => {
     res.status(200).json({
       status: 'OK',
       timestamp: new Date().toISOString(),
       uptime: process.uptime(),
       mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
     });
   });
   ```

2. **Check render.yaml health check config:**
   ```yaml
   healthCheckPath: /health
   healthCheckTimeout: 30
   ```

3. **Test health endpoint locally:**
   ```bash
   curl http://localhost:5001/health
   ```

---

## 🚀 Quick Fix Checklist

Run through this checklist in order:

### 1. ⏱️ Wait 5 Minutes
- [ ] Check if deployment is still in progress
- [ ] Deployment just completed? Wait 2-3 more minutes
- [ ] Refresh Render dashboard to see latest status

### 2. 📋 Check Logs
- [ ] Go to Render Dashboard → Your Service → Logs
- [ ] Look for the last line of output
- [ ] Screenshot any error messages

### 3. 🔐 Verify Environment Variables
- [ ] Go to Environment tab in Render
- [ ] Check `MONGODB_URI` is set
- [ ] Check `JWT_SECRET` is set
- [ ] Check `NODE_ENV=production`
- [ ] Check `PORT=10000`

### 4. 🌐 Test MongoDB Connection
- [ ] Log into MongoDB Atlas
- [ ] Check Network Access allows 0.0.0.0/0
- [ ] Verify database user has correct permissions
- [ ] Test connection string with mongosh

### 5. 🔄 Manual Redeploy
- [ ] In Render Dashboard, click "Manual Deploy"
- [ ] Select "Clear build cache & deploy"
- [ ] Wait 5 minutes for deployment

### 6. 📊 Check Resource Usage
- [ ] In Render Dashboard, check Metrics
- [ ] Memory usage < 80%?
- [ ] CPU usage < 90%?
- [ ] If maxed out, upgrade plan

---

## 🧪 Testing Deployment

### Test 1: Check Service Status
```bash
# Once deployment completes:
curl -I https://al-marya-rostary.onrender.com/health

# Expected:
# HTTP/2 200
```

### Test 2: Check API Endpoints
```bash
# Test admin login:
curl -X POST https://al-marya-rostary.onrender.com/api/auth/admin-login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"YOUR_PASSWORD"}'

# Expected:
# {"success": true, "data": {"token": "..."}}
```

### Test 3: View Full Logs
```bash
# In Render Dashboard:
1. Go to Logs tab
2. Enable "Live tail"
3. Watch for startup messages
4. Look for any errors
```

---

## 🔍 Debugging Steps (If Still Failing)

### Step 1: Check Render Service Configuration

1. **Verify render.yaml matches service:**
   ```yaml
   type: web
   env: node
   runtime: node20
   startCommand: npm start
   ```

2. **Check package.json start script:**
   ```json
   "scripts": {
     "start": "node server.js"
   }
   ```

### Step 2: Check Server Startup Code

1. **Verify server.js uses correct port:**
   ```javascript
   const PORT = process.env.PORT || 5001;
   app.listen(PORT, '0.0.0.0', () => {
     console.log(`Server running on port ${PORT}`);
   });
   ```

2. **Check for early exits:**
   ```javascript
   // Look for these in server.js:
   process.exit(1); // Should only be in critical errors
   ```

3. **Verify MongoDB connection:**
   ```javascript
   mongoose.connect(process.env.MONGODB_URI, {
     serverSelectionTimeoutMS: 30000,
     socketTimeoutMS: 45000
   });
   ```

### Step 3: Test Locally with Production Config

1. **Create test environment:**
   ```bash
   cd backend
   cp .env .env.backup
   ```

2. **Set production-like env:**
   ```bash
   export NODE_ENV=production
   export PORT=10000
   export MONGODB_URI="your-mongodb-uri"
   export JWT_SECRET="test-secret-64-chars-long..."
   ```

3. **Start server:**
   ```bash
   npm start
   ```

4. **Test endpoints:**
   ```bash
   curl http://localhost:10000/health
   curl http://localhost:10000/api/auth/admin-login -X POST \
     -H "Content-Type: application/json" \
     -d '{"username":"admin","password":"test"}'
   ```

---

## 📞 Getting Help from Render Support

If issue persists after all checks:

1. **Collect Information:**
   - Service name: `al-marya-rostery-production`
   - Request ID: `99071704d80923e5-DXB`
   - Last 50 lines of logs (screenshot)
   - Environment variables list (without values)

2. **Contact Render Support:**
   ```
   https://render.com/support
   
   Subject: 502 Bad Gateway - Service Not Starting
   Request ID: 99071704d80923e5-DXB
   
   Include:
   - Service URL
   - Error message
   - Log screenshots
   - Steps you've tried
   ```

---

## 🎯 Most Likely Causes (In Order)

1. **⏳ Service Still Starting** (60% of cases)
   - Solution: Wait 5 minutes

2. **🔐 Missing Environment Variables** (20% of cases)
   - Solution: Add MONGODB_URI, JWT_SECRET in Render dashboard

3. **🌐 MongoDB Network Access** (10% of cases)
   - Solution: Allow 0.0.0.0/0 in MongoDB Atlas

4. **🔌 Port Binding Issue** (5% of cases)
   - Solution: Use process.env.PORT and bind to 0.0.0.0

5. **🛠️ Build/Dependency Issue** (5% of cases)
   - Solution: Check logs for npm errors

---

## ✅ Success Indicators

You'll know it's working when you see:

### In Render Dashboard:
- ✅ Status: "Live" (green)
- ✅ Last deploy: "Live" with green checkmark
- ✅ Health check: Passing

### In Logs:
```
✅ MongoDB Connected: ...
✅ Server running on port 10000
🎉 Al Marya Rostery Server Started Successfully!
✅ Health check endpoints configured
```

### In Browser:
```
https://al-marya-rostary.onrender.com/health
→ {"status":"OK","timestamp":"...","uptime":123}
```

---

## 📋 Next Steps RIGHT NOW

1. **Go to Render Dashboard NOW:**
   ```
   https://dashboard.render.com/
   ```

2. **Find your service and click on it**

3. **Look at the "Logs" tab**

4. **Take a screenshot of:**
   - Last 20 lines of logs
   - Deployment status at top
   - Any error messages in red

5. **Check Environment tab:**
   - Count how many variables are set
   - Verify MONGODB_URI exists (don't share the value)

6. **Report back with:**
   - Current status (Deploying/Live/Failed)
   - Last log line
   - Any error messages

---

**Most Likely Issue:** Service still starting up OR missing environment variables

**Quick Fix:** Wait 5 minutes, then check Render logs for specific error

**I'm here to help!** Share what you see in the Render logs and I'll help diagnose.

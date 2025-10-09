# 🚀 MongoDB Atlas Production Setup Guide

## Prerequisites
You have MongoDB Atlas API keys:
- **Public Key**: `xgjybvct`
- **Private Key**: `ae520a49-2587-4b0b-9c84-329ddbdab1b1`

## Step 1: Create Database User in MongoDB Atlas

### Manual Method (Recommended):

1. **Go to MongoDB Atlas Dashboard**
   ```
   https://cloud.mongodb.com
   ```

2. **Select Your Project**
   - Look for project named "***REMOVED***" or similar
   - Click on it to enter the project

3. **Create Database User**
   - In the left sidebar, click **"Database Access"**
   - Click **"Add New Database User"**
   - Fill in the details:
     - **Authentication Method**: Password
     - **Username**: `qahwat_user`
     - **Password**: `qahwat_secure_2025`
     - **Database User Privileges**: Select **"Read and write to any database"**
   - Click **"Add User"**

4. **Configure Network Access**
   - In the left sidebar, click **"Network Access"**
   - Click **"Add IP Address"**
   - For testing, you can add **"0.0.0.0/0"** (allows access from anywhere)
   - For production, add your specific server IP addresses
   - Click **"Confirm"**

## Step 2: Verify Connection

After creating the user, test the connection:

```bash
cd backend
node test-atlas-connection.js
```

You should see:
```
✅ Connected to MongoDB Atlas successfully!
📊 Database: qahwat_al_emarat
```

## Step 3: Start Production Backend

```bash
cd backend
node server.js
```

Expected output:
```
✅ MongoDB Connected Successfully
📊 Database: qahwat_al_emarat
🚀 Server running on port 5001
```

## Step 4: Flutter App Configuration

Your Flutter app is now configured to work with production:

**Current Setting**: Uses MongoDB Atlas backend (production mode)

To switch between environments, edit `lib/core/constants/app_constants.dart`:

```dart
// For production (MongoDB Atlas):
static const bool _useProduction = true;

// For local development:
static const bool _useProduction = false;
```

## 🔧 Configuration Summary

### Backend (.env):
```properties
NODE_ENV=production
MONGODB_URI=***REMOVED***qahwat_user:qahwat_secure_2025@***REMOVED***.ph5cazq.mongodb.net/qahwat_al_emarat?retryWrites=true&w=majority&appName=***REMOVED***
```

### Flutter (app_constants.dart):
```dart
static const bool _useProduction = true; // Uses MongoDB Atlas
```

## 🚀 Deployment Options

### Option 1: Keep using Render
- Deploy your backend to Render
- Update Flutter baseUrl to Render URL
- MongoDB Atlas will be your database

### Option 2: Local Backend + Atlas Database
- Run backend locally on port 5001
- Use MongoDB Atlas for database
- Good for development with production data

## ✅ Benefits of This Setup

- **Production Database**: MongoDB Atlas with automatic backups
- **Scalability**: Atlas scales automatically with your app
- **Security**: Proper authentication and network controls
- **Monitoring**: Atlas provides monitoring and alerting
- **Global**: Atlas has worldwide data centers

## 🔍 Troubleshooting

If connection fails:

1. **Check Database User**: Ensure user `qahwat_user` exists
2. **Check Network Access**: Ensure your IP is whitelisted
3. **Check Credentials**: Username and password must match exactly
4. **Check Cluster Status**: Ensure cluster is running (not paused)

---

**Next Step**: Create the database user in MongoDB Atlas dashboard, then run the connection test!
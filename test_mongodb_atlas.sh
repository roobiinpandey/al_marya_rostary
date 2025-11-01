#!/bin/bash

echo "🌐 MongoDB Atlas Connection Test"
echo "==============================="
echo "Project ID: 68ec058e3486383971bfe588"
echo ""

# Current configuration check
echo "1️⃣ CURRENT CONFIGURATION"
echo "========================"

cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend"

if [ -f ".env" ]; then
    CURRENT_URI=$(grep "^MONGODB_URI=" .env | cut -d'=' -f2-)
    echo "Current MongoDB URI: $CURRENT_URI"
    
    if echo "$CURRENT_URI" | grep -q "localhost"; then
        echo "🏠 Currently using: LOCAL MONGODB"
        echo "⚠️  Need to switch to MongoDB Atlas for online database"
    elif echo "$CURRENT_URI" | grep -q "mongodb+srv"; then
        echo "☁️  Currently using: MONGODB ATLAS" 
        echo "✅ Already configured for online database"
    fi
else
    echo "❌ .env file not found"
    exit 1
fi

echo ""

# Test current connection
echo "2️⃣ TESTING CURRENT CONNECTION"
echo "============================="

if lsof -i :5001 > /dev/null 2>&1; then
    echo "Testing current database connection..."
    HEALTH_RESPONSE=$(curl -s http://localhost:5001/health 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        DB_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.database.status // "unknown"' 2>/dev/null)
        DB_HOST=$(echo "$HEALTH_RESPONSE" | jq -r '.database.host // "unknown"' 2>/dev/null)
        
        echo "✅ Current connection status: $DB_STATUS"
        echo "   Host: $DB_HOST"
    else
        echo "❌ Backend not responding"
    fi
else
    echo "❌ Backend server not running on port 5001"
fi

echo ""

# MongoDB Atlas connection string from .env (commented)
echo "3️⃣ MONGODB ATLAS CONFIGURATION"
echo "=============================="

ATLAS_URI=$(grep "^# MONGODB_URI=mongodb+srv" .env | sed 's/^# //' | cut -d'=' -f2-)

if [ -n "$ATLAS_URI" ]; then
    echo "Found Atlas URI in .env (commented):"
    echo "$ATLAS_URI"
    
    # Extract cluster info
    CLUSTER_HOST=$(echo "$ATLAS_URI" | sed 's/.*@\([^/]*\).*/\1/')
    echo "Cluster host: $CLUSTER_HOST"
    
    # Test Atlas connectivity (without credentials for security)
    echo ""
    echo "Testing Atlas cluster connectivity..."
    
    # Try to resolve the hostname
    if nslookup "$CLUSTER_HOST" > /dev/null 2>&1; then
        echo "✅ Atlas cluster hostname resolved"
        echo "✅ Network connectivity to Atlas cluster available"
    else
        echo "❌ Cannot resolve Atlas cluster hostname"
        echo "   This may indicate network issues or incorrect cluster URL"
    fi
else
    echo "❌ No Atlas URI found in .env file"
fi

echo ""

# Check Atlas API credentials
echo "4️⃣ MONGODB ATLAS API CREDENTIALS"
echo "==============================="

ATLAS_PUBLIC_KEY=$(grep "^MONGODB_ATLAS_PUBLIC_KEY=" .env | cut -d'=' -f2-)
ATLAS_PRIVATE_KEY=$(grep "^MONGODB_ATLAS_PRIVATE_KEY=" .env | cut -d'=' -f2-)

if [ -n "$ATLAS_PUBLIC_KEY" ] && [ -n "$ATLAS_PRIVATE_KEY" ]; then
    echo "✅ Atlas API credentials found"
    echo "   Public Key: $ATLAS_PUBLIC_KEY"
    echo "   Private Key: [HIDDEN]"
    
    # Test Atlas API (basic check)
    echo ""
    echo "Testing Atlas API connectivity..."
    
    # Try to get project info using your project ID
    PROJECT_ID="68ec058e3486383971bfe588"
    
    ATLAS_API_RESPONSE=$(curl -s --digest \
        -u "$ATLAS_PUBLIC_KEY:$ATLAS_PRIVATE_KEY" \
        "https://cloud.mongodb.com/api/atlas/v1.0/groups/$PROJECT_ID" 2>/dev/null)
    
    if echo "$ATLAS_API_RESPONSE" | grep -q "name" 2>/dev/null; then
        PROJECT_NAME=$(echo "$ATLAS_API_RESPONSE" | jq -r '.name // "Unknown"' 2>/dev/null)
        echo "✅ Atlas API connection successful"
        echo "   Project Name: $PROJECT_NAME"
        echo "   Project ID: $PROJECT_ID"
    else
        echo "❌ Atlas API connection failed"
        echo "   Response: $ATLAS_API_RESPONSE"
    fi
else
    echo "❌ Atlas API credentials not found or incomplete"
fi

echo ""

# Recommendation
echo "5️⃣ RECOMMENDATIONS"
echo "=================="

if echo "$CURRENT_URI" | grep -q "localhost"; then
    echo "📋 TO SWITCH TO MONGODB ATLAS (ONLINE):"
    echo ""
    echo "1. Update .env file to use Atlas URI:"
    echo "   Comment out: MONGODB_URI=mongodb://localhost:27017/al_marya_rostery"
    echo "   Uncomment: MONGODB_URI=mongodb+srv://almaryarostery_db_user:..."
    echo ""
    echo "2. Restart backend server:"
    echo "   npm restart"
    echo ""
    echo "3. Verify Atlas connection:"
    echo "   curl http://localhost:5001/health"
    echo ""
    echo "💡 BENEFITS OF ATLAS (ONLINE):"
    echo "   ✅ Accessible from anywhere"
    echo "   ✅ Automatic backups"
    echo "   ✅ Production-ready scaling"
    echo "   ✅ Better security"
    echo ""
    echo "💡 CURRENT LOCAL MONGODB:"
    echo "   ✅ Fast for development"
    echo "   ❌ Only accessible locally"
    echo "   ❌ No automatic backups"
    echo "   ❌ Development only"
else
    echo "✅ Already using MongoDB Atlas (online database)"
    echo "   Your database is accessible from anywhere"
    echo "   Automatic backups and scaling available"
fi

echo ""
echo "🔧 QUICK SWITCH COMMANDS:"
echo "========================"
echo ""
echo "# To switch to Atlas (online):"
echo "cd '/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend'"
echo "cp .env .env.backup"
echo "sed -i '' 's/^MONGODB_URI=mongodb:\/\/localhost/#MONGODB_URI=mongodb:\/\/localhost/' .env"
echo "sed -i '' 's/^# MONGODB_URI=mongodb+srv/MONGODB_URI=mongodb+srv/' .env"
echo "npm restart"
echo ""
echo "# To switch back to local:"
echo "sed -i '' 's/^MONGODB_URI=mongodb+srv/#MONGODB_URI=mongodb+srv/' .env"  
echo "sed -i '' 's/^#MONGODB_URI=mongodb:\/\/localhost/MONGODB_URI=mongodb:\/\/localhost/' .env"
echo "npm restart"

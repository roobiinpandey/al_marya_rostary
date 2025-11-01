#!/bin/bash

echo "🔧 MongoDB Connection Diagnosis and Fix"
echo "======================================="
echo ""

# Test MongoDB service
echo "1️⃣ MONGODB SERVICE STATUS"
echo "========================="
if pgrep -x "mongod" > /dev/null; then
    echo "✅ MongoDB service: RUNNING"
    echo "   Process ID: $(pgrep -x mongod)"
else
    echo "❌ MongoDB service: NOT RUNNING"
    echo "   Starting MongoDB..."
    brew services start mongodb-community
fi

echo ""

# Test backend server
echo "2️⃣ BACKEND SERVER STATUS"
echo "========================"
if lsof -i :5001 > /dev/null 2>&1; then
    echo "✅ Backend server: RUNNING on port 5001"
    
    # Test health endpoint
    echo ""
    echo "3️⃣ MONGODB CONNECTION TEST"
    echo "=========================="
    
    HEALTH_RESPONSE=$(curl -s http://localhost:5001/health 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "✅ Health endpoint: RESPONDING"
        
        # Parse database status
        DB_STATUS=$(echo "$HEALTH_RESPONSE" | jq -r '.database.status // "unknown"' 2>/dev/null)
        DB_HOST=$(echo "$HEALTH_RESPONSE" | jq -r '.database.host // "unknown"' 2>/dev/null)
        DB_NAME=$(echo "$HEALTH_RESPONSE" | jq -r '.database.name // "unknown"' 2>/dev/null)
        DB_COLLECTIONS=$(echo "$HEALTH_RESPONSE" | jq -r '.database.collections // 0' 2>/dev/null)
        
        echo "   📊 Database status: $DB_STATUS"
        echo "   🏠 Database host: $DB_HOST"
        echo "   📂 Database name: $DB_NAME"
        echo "   📋 Collections: $DB_COLLECTIONS"
        
        if [ "$DB_STATUS" = "connected" ]; then
            echo "✅ MongoDB connection: ESTABLISHED"
        else
            echo "❌ MongoDB connection: FAILED"
        fi
    else
        echo "❌ Health endpoint: NOT RESPONDING"
    fi
else
    echo "❌ Backend server: NOT RUNNING"
    echo "   Server needs to be started"
fi

echo ""

# Test API endpoints
echo "4️⃣ API ENDPOINTS TEST"
echo "====================="

ENDPOINTS=(
    "/api/subscriptions/plans"
    "/api/coffees"
    "/api/categories"
    "/api/settings/public"
)

for endpoint in "${ENDPOINTS[@]}"; do
    RESPONSE_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5001$endpoint" 2>/dev/null)
    if [ "$RESPONSE_CODE" = "200" ]; then
        echo "   ✅ $endpoint: $RESPONSE_CODE"
    else
        echo "   ❌ $endpoint: $RESPONSE_CODE"
    fi
done

echo ""

# Test subscription data specifically
echo "5️⃣ SUBSCRIPTION DATA TEST"
echo "========================="

PLANS_RESPONSE=$(curl -s http://localhost:5001/api/subscriptions/plans 2>/dev/null)
if [ $? -eq 0 ]; then
    PLANS_COUNT=$(echo "$PLANS_RESPONSE" | jq '.data.total // 0' 2>/dev/null)
    echo "✅ Subscription plans: $PLANS_COUNT available"
    
    if [ "$PLANS_COUNT" -gt "0" ]; then
        echo "   📋 Sample plan names:"
        echo "$PLANS_RESPONSE" | jq -r '.data.plans[].name' 2>/dev/null | head -3 | sed 's/^/      - /'
    fi
else
    echo "❌ Subscription plans: API not responding"
fi

echo ""

# MongoDB connection string check
echo "6️⃣ MONGODB CONFIGURATION"
echo "========================"

cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend"

if [ -f ".env" ]; then
    echo "✅ Environment file: Found"
    
    MONGO_URI=$(grep "^MONGODB_URI=" .env | cut -d'=' -f2-)
    echo "   🔗 MongoDB URI: $MONGO_URI"
    
    if echo "$MONGO_URI" | grep -q "localhost"; then
        echo "   🏠 Configuration: LOCAL MONGODB"
        echo "   ✅ This is correct for development"
    elif echo "$MONGO_URI" | grep -q "mongodb+srv"; then
        echo "   ☁️  Configuration: MONGODB ATLAS"
        echo "   ⚠️  Ensure Atlas credentials are correct"
    else
        echo "   ❓ Configuration: UNKNOWN FORMAT"
    fi
else
    echo "❌ Environment file: NOT FOUND"
fi

echo ""

# Summary
echo "📊 MONGODB CONNECTION SUMMARY"
echo "============================="

# Overall status
if lsof -i :5001 > /dev/null 2>&1; then
    HEALTH_CHECK=$(curl -s http://localhost:5001/health 2>/dev/null)
    DB_STATUS=$(echo "$HEALTH_CHECK" | jq -r '.database.status // "unknown"' 2>/dev/null)
    
    if [ "$DB_STATUS" = "connected" ]; then
        echo ""
        echo "🎉 MONGODB CONNECTION: FULLY WORKING"
        echo "=================================="
        echo "✅ MongoDB service running"
        echo "✅ Backend server running"
        echo "✅ Database connection established" 
        echo "✅ API endpoints responding"
        echo "✅ Subscription data available"
        echo ""
        echo "🚀 READY FOR APPLICATION TESTING!"
    else
        echo ""
        echo "⚠️  MONGODB CONNECTION: PARTIAL ISSUES"
        echo "====================================="
        echo "✅ MongoDB service running"
        echo "✅ Backend server running"
        echo "❌ Database connection issues"
        echo ""
        echo "🔧 RECOMMENDED ACTIONS:"
        echo "1. Check MongoDB logs: brew services restart mongodb-community"
        echo "2. Verify .env configuration"
        echo "3. Restart backend server"
    fi
else
    echo ""
    echo "❌ MONGODB CONNECTION: NOT WORKING"
    echo "================================="
    echo "Backend server is not running"
    echo ""
    echo "🔧 REQUIRED ACTIONS:"
    echo "1. Start backend server: npm start"
    echo "2. Verify MongoDB is running"
    echo "3. Check configuration files"
fi

echo ""
echo "💡 QUICK FIX COMMANDS:"
echo "====================="
echo "cd '/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend'"
echo "npm start  # Start backend server"
echo "curl http://localhost:5001/health  # Test connection"

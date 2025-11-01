#!/bin/bash

echo "🔧 MongoDB Atlas Production Connection Test"
echo "=========================================="
echo ""

# Test 1: Check network connectivity to Atlas cluster
echo "1️⃣ NETWORK CONNECTIVITY TEST"
echo "============================="

CLUSTER_HOST="almaryarostery.2yel8zi.mongodb.net"
echo "Testing connection to Atlas cluster: $CLUSTER_HOST"

if nslookup "$CLUSTER_HOST" > /dev/null 2>&1; then
    echo "✅ DNS resolution successful"
else
    echo "❌ DNS resolution failed"
    exit 1
fi

# Test connection on MongoDB port
if nc -z "$CLUSTER_HOST" 27017 2>/dev/null; then
    echo "✅ Network connectivity to MongoDB port successful"
else
    echo "❌ Network connectivity to MongoDB port failed"
    echo "   This could indicate:"
    echo "   - Firewall blocking the connection"
    echo "   - IP address not whitelisted in Atlas"
fi

echo ""

# Test 2: Check IP address (for Atlas whitelist)
echo "2️⃣ IP ADDRESS CHECK"
echo "==================="

CURRENT_IP=$(curl -s http://checkip.amazonaws.com/ 2>/dev/null)
if [ -n "$CURRENT_IP" ]; then
    echo "Your current public IP: $CURRENT_IP"
    echo ""
    echo "⚠️  IMPORTANT: Ensure this IP is whitelisted in Atlas"
    echo "   Go to: Network Access in your Atlas dashboard"
    echo "   Add IP Address: $CURRENT_IP"
else
    echo "❌ Could not determine public IP address"
fi

echo ""

# Test 3: Test MongoDB connection using mongo shell (if available)
echo "3️⃣ MONGODB CONNECTION TEST"
echo "=========================="

CONNECTION_STRING="mongodb+srv://almaryarostery_db_user:4C8JU6Aao3DzW6MV@almaryarostery.2yel8zi.mongodb.net/al_marya_rostery?retryWrites=true&w=majority"

echo "Testing Atlas connection..."

# Test with Node.js if mongosh is not available
cat > test_atlas_connection.js << 'EOF'
const { MongoClient } = require('mongodb');

const uri = process.env.MONGODB_URI || 'mongodb+srv://almaryarostery_db_user:4C8JU6Aao3DzW6MV@almaryarostery.2yel8zi.mongodb.net/al_marya_rostery?retryWrites=true&w=majority';

async function testConnection() {
    const client = new MongoClient(uri);
    
    try {
        console.log('🔌 Attempting to connect to MongoDB Atlas...');
        await client.connect();
        console.log('✅ Successfully connected to MongoDB Atlas!');
        
        // Test database operations
        const db = client.db('al_marya_rostery');
        const collections = await db.listCollections().toArray();
        console.log(`📁 Found ${collections.length} collections in database`);
        
        // Test a simple query
        const testCollection = db.collection('subscriptions');
        const count = await testCollection.countDocuments();
        console.log(`📊 Test collection has ${count} documents`);
        
    } catch (error) {
        console.log('❌ Connection failed:', error.message);
        
        if (error.message.includes('authentication failed')) {
            console.log('');
            console.log('🔍 AUTHENTICATION ERROR DETAILS:');
            console.log('   - Username: almaryarostery_db_user');
            console.log('   - This usually means:');
            console.log('     1. Username is incorrect');
            console.log('     2. Password is incorrect'); 
            console.log('     3. User doesn\'t have proper database privileges');
            console.log('     4. User is not created in the correct database');
        }
        
        if (error.message.includes('IP') || error.message.includes('whitelist')) {
            console.log('');
            console.log('🌐 NETWORK ACCESS ERROR:');
            console.log('   - Your IP address may not be whitelisted');
            console.log('   - Check Network Access in Atlas dashboard');
        }
        
    } finally {
        await client.close();
    }
}

testConnection().catch(console.error);
EOF

cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery/backend"

if [ -f "package.json" ]; then
    echo "Running Atlas connection test..."
    node test_atlas_connection.js
    rm test_atlas_connection.js
else
    echo "❌ Node.js project not found"
fi

echo ""

# Test 4: Recommendations
echo "4️⃣ TROUBLESHOOTING RECOMMENDATIONS"
echo "=================================="

echo ""
echo "🔧 COMMON SOLUTIONS:"
echo ""
echo "1. **VERIFY DATABASE USER**:"
echo "   - Go to Database Access in Atlas dashboard"
echo "   - Ensure user 'almaryarostery_db_user' exists"
echo "   - Verify password is correct"
echo "   - Check user has 'Read and write to any database' privileges"
echo ""
echo "2. **CHECK NETWORK ACCESS**:"
echo "   - Go to Network Access in Atlas dashboard"
echo "   - Add current IP: $CURRENT_IP"
echo "   - Recommended: Also add these known IPs (if applicable):"
echo "       92.96.6.195/32  # local dev IP"
echo "       2.50.140.183/32  # server IP"
echo "   - Or temporarily add 0.0.0.0/0 (allow access from anywhere)"
echo ""
echo "   # Optional: Add IPs using Atlas CLI (install https://www.mongodb.com/docs/atlas/cli/stable/)
echo "   # atlas accessLists create 92.96.6.195/32 --comment 'home-ip'"
echo "   # atlas accessLists create 2.50.140.183/32 --comment 'server-ip'"
echo ""
echo "3. **VERIFY CLUSTER STATUS**:"
echo "   - Go to Clusters in Atlas dashboard"
echo "   - Ensure cluster is running and not paused"
echo "   - Check cluster name matches: almaryarostery"
echo ""
echo "4. **CONNECTION STRING FORMAT**:"
echo "   - Verify special characters in password are URL-encoded"
echo "   - Check database name is correct: al_marya_rostery"

echo ""
echo "🚀 ATLAS DASHBOARD LINKS:"
echo "========================"
echo "Database Users: https://cloud.mongodb.com/v2/68ec058e3486383971bfe588#/security/database/users"
echo "Network Access: https://cloud.mongodb.com/v2/68ec058e3486383971bfe588#/security/network/whitelist"
echo "Clusters: https://cloud.mongodb.com/v2/68ec058e3486383971bfe588#/clusters"

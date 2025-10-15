#!/bin/bash
# Quick test script to verify admin panel functionality
# Run with: bash test-admin-panel.sh

echo "🚀 Testing Admin Panel Functionality..."
echo

BASE_URL="http://localhost:5001"

# Test 1: Health Check
echo "1️⃣ Testing Health Endpoint..."
HEALTH_RESPONSE=$(curl -s "$BASE_URL/api/health")
echo "   ✅ Health Check: $(echo $HEALTH_RESPONSE | grep -o '"status":"[^"]*"' | cut -d'"' -f4)"
echo

# Test 2: Admin Login
echo "2️⃣ Testing Admin Authentication..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"almarya@admin","password":"almaryaadmin2020"}')

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -n "$TOKEN" ]; then
    echo "   ✅ Login successful - Token received"
else
    echo "   ❌ Login failed"
    exit 1
fi
echo

# Test 3: Admin Dashboard
echo "3️⃣ Testing Dashboard Data..."
DASHBOARD_RESPONSE=$(curl -s "$BASE_URL/api/analytics/admin/dashboard" \
  -H "Authorization: Bearer $TOKEN")

if echo "$DASHBOARD_RESPONSE" | grep -q '"success":true'; then
    USERS=$(echo $DASHBOARD_RESPONSE | grep -o '"totalUsers":[0-9]*' | cut -d':' -f2)
    PRODUCTS=$(echo $DASHBOARD_RESPONSE | grep -o '"totalProducts":[0-9]*' | cut -d':' -f2)
    ORDERS=$(echo $DASHBOARD_RESPONSE | grep -o '"totalOrders":[0-9]*' | cut -d':' -f2)
    REVENUE=$(echo $DASHBOARD_RESPONSE | grep -o '"totalRevenue":[0-9]*' | cut -d':' -f2)
    
    echo "   📊 Total Users: $USERS"
    echo "   📦 Total Products: $PRODUCTS"
    echo "   🛒 Total Orders: $ORDERS"
    echo "   💰 Total Revenue: \$$REVENUE"
else
    echo "   ❌ Dashboard test failed"
fi
echo

echo "🎉 Admin panel tests completed!"
echo
echo "💡 To access admin panel:"
echo "   📱 URL: http://localhost:5001"
echo "   📧 Email: almarya@admin"
echo "   🔒 Password: almaryaadmin2020"
echo

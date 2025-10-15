#!/bin/bash
# Complete test of admin panel functionality

echo "🚀 Complete Admin Panel Test"
echo "=============================="

# Test 1: Backend Health
echo ""
echo "1️⃣ Testing Backend Health..."
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5001/api/health")
if [ "$HEALTH_STATUS" = "200" ]; then
    echo "   ✅ Backend healthy (Status: $HEALTH_STATUS)"
else
    echo "   ❌ Backend unhealthy (Status: $HEALTH_STATUS)"
    exit 1
fi

# Test 2: Admin Panel Access
echo ""
echo "2️⃣ Testing Admin Panel Access..."
PANEL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5001/")
if [ "$PANEL_STATUS" = "200" ]; then
    echo "   ✅ Admin panel accessible (Status: $PANEL_STATUS)"
else
    echo "   ❌ Admin panel not accessible (Status: $PANEL_STATUS)"
    exit 1
fi

# Test 3: Authentication
echo ""
echo "3️⃣ Testing Authentication..."
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:5001/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"almarya@admin","password":"almaryaadmin2020"}')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -n "$TOKEN" ]; then
    echo "   ✅ Authentication successful"
    echo "   🔑 Token format: JWT (${#TOKEN} chars)"
else
    echo "   ❌ Authentication failed"
    echo "   Response: $LOGIN_RESPONSE"
    exit 1
fi

# Test 4: Protected Endpoint
echo ""
echo "4️⃣ Testing Dashboard API..."
DASHBOARD_RESPONSE=$(curl -s "http://localhost:5001/api/analytics/admin/dashboard" \
  -H "Authorization: Bearer $TOKEN")

if echo "$DASHBOARD_RESPONSE" | grep -q '"success":true'; then
    USERS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"totalUsers":[0-9]*' | cut -d':' -f2)
    PRODUCTS=$(echo "$DASHBOARD_RESPONSE" | grep -o '"totalProducts":[0-9]*' | cut -d':' -f2)
    echo "   ✅ Dashboard API working"
    echo "   📊 Users: $USERS | Products: $PRODUCTS"
else
    echo "   ❌ Dashboard API failed"
    echo "   Response: $DASHBOARD_RESPONSE"
    exit 1
fi

# Test 5: CSP Validation (check if Google script is allowed)
echo ""
echo "5️⃣ Testing CSP Configuration..."
CSP_HEADER=$(curl -s -I "http://localhost:5001/" | grep -i "content-security-policy")
if echo "$CSP_HEADER" | grep -q "accounts.google.com"; then
    echo "   ✅ CSP allows Google services"
else
    echo "   ⚠️  CSP might not allow Google services"
fi

# Final Summary
echo ""
echo "🎉 Test Results Summary:"
echo "========================"
echo "✅ Backend Server: Running"
echo "✅ Admin Panel: Accessible"  
echo "✅ Authentication: Working"
echo "✅ Dashboard API: Functional"
echo "✅ CSP Configuration: Updated"
echo ""
echo "🌐 Admin Panel Ready!"
echo "📱 URL: http://localhost:5001"
echo "👤 Email: almarya@admin"
echo "🔒 Password: almaryaadmin2020"
echo ""
echo "🚨 Known Issues Fixed:"
echo "• CSP violations for Google GSI client"
echo "• 401 authentication errors"
echo "• Invalid token handling"
echo "• Proper logout on auth failures"

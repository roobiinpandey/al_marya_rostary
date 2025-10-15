#!/bin/bash
# Test admin login and get valid token

echo "🔐 Testing Admin Login..."

# Login and get token
LOGIN_RESPONSE=$(curl -s -X POST "http://localhost:5001/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"almarya@admin","password":"almaryaadmin2020"}')

# Extract token
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo "✅ Login successful!"
    echo "🔑 Token: ${TOKEN:0:20}..."
    
    # Test dashboard with token
    echo ""
    echo "📊 Testing Dashboard API..."
    DASHBOARD_RESPONSE=$(curl -s "http://localhost:5001/api/analytics/admin/dashboard" \
      -H "Authorization: Bearer $TOKEN")
    
    if echo "$DASHBOARD_RESPONSE" | grep -q '"success":true'; then
        echo "✅ Dashboard API working!"
        echo "📈 Response: $(echo "$DASHBOARD_RESPONSE" | head -c 100)..."
    else
        echo "❌ Dashboard API failed"
        echo "Response: $DASHBOARD_RESPONSE"
    fi
    
    # Save token for browser testing
    echo ""
    echo "💡 To test in browser:"
    echo "1. Open http://localhost:5001"
    echo "2. Login with: almarya@admin / almaryaadmin2020"
    echo "3. Or manually set token in localStorage:"
    echo "   localStorage.setItem('adminToken', '$TOKEN')"
    echo "   localStorage.setItem('adminUser', '{\"name\":\"Al Marya Admin\",\"email\":\"almarya@admin\",\"roles\":[\"admin\"]}')"
    
else
    echo "❌ Login failed"
    echo "Response: $LOGIN_RESPONSE"
fi

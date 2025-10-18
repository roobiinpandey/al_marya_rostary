#!/bin/bash

echo "🔍 DEBUGGING FIREBASE USERS LOADING ISSUE"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_URL="http://localhost:5001"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="almarya2024"

echo "${BLUE}1. Testing Backend Server Health${NC}"
echo "-----------------------------------"
HEALTH_RESPONSE=$(curl -s "${BACKEND_URL}/health")
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend is reachable${NC}"
    echo "Response: $HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Backend is NOT reachable${NC}"
    echo "Please make sure backend is running: cd backend && npm start"
    exit 1
fi
echo ""

echo "${BLUE}2. Testing Admin Login${NC}"
echo "----------------------"
LOGIN_RESPONSE=$(curl -s -X POST "${BACKEND_URL}/api/auth/admin-login" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${ADMIN_USERNAME}\",\"password\":\"${ADMIN_PASSWORD}\"}")

echo "Response: $LOGIN_RESPONSE"

# Extract token using grep and sed (macOS compatible)
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Failed to get admin token${NC}"
    echo "Check admin credentials in backend .env file"
    exit 1
else
    echo -e "${GREEN}✅ Admin login successful${NC}"
    echo "Token: ${TOKEN:0:50}..."
fi
echo ""

echo "${BLUE}3. Testing Firebase Users Endpoint${NC}"
echo "------------------------------------"
USERS_RESPONSE=$(curl -s -X GET "${BACKEND_URL}/api/admin/firebase-users?page=1&limit=5" \
  -H "Authorization: Bearer ${TOKEN}")

echo "Response:"
echo "$USERS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$USERS_RESPONSE"
echo ""

# Check response structure
if echo "$USERS_RESPONSE" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ API returned success${NC}"
    
    # Count users
    USER_COUNT=$(echo "$USERS_RESPONSE" | grep -o '"uid"' | wc -l | tr -d ' ')
    echo "Users returned: $USER_COUNT"
    
    if [ "$USER_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ Users data is present${NC}"
    else
        echo -e "${YELLOW}⚠️  No users in response${NC}"
    fi
else
    echo -e "${RED}❌ API returned error${NC}"
fi
echo ""

echo "${BLUE}4. Checking Response Structure${NC}"
echo "-------------------------------"
# Check if data is nested
if echo "$USERS_RESPONSE" | grep -q '"data":{'; then
    echo -e "${GREEN}✅ Response has nested 'data' object${NC}"
    echo "Structure: { success: true, data: { users: [...], pagination: {...} } }"
elif echo "$USERS_RESPONSE" | grep -q '"users":\['; then
    echo -e "${YELLOW}⚠️  Response has flat 'users' array${NC}"
    echo "Structure: { success: true, users: [...] }"
else
    echo -e "${RED}❌ Unexpected response structure${NC}"
fi
echo ""

echo "${BLUE}5. Testing with Detailed Error Info${NC}"
echo "-------------------------------------"
VERBOSE_RESPONSE=$(curl -v -X GET "${BACKEND_URL}/api/admin/firebase-users?page=1&limit=5" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json" 2>&1)

HTTP_CODE=$(echo "$VERBOSE_RESPONSE" | grep "< HTTP" | tail -1)
echo "HTTP Status: $HTTP_CODE"

if echo "$HTTP_CODE" | grep -q "200"; then
    echo -e "${GREEN}✅ HTTP 200 OK${NC}"
elif echo "$HTTP_CODE" | grep -q "401"; then
    echo -e "${RED}❌ HTTP 401 Unauthorized - Token issue${NC}"
elif echo "$HTTP_CODE" | grep -q "500"; then
    echo -e "${RED}❌ HTTP 500 Internal Server Error${NC}"
    echo "Check backend logs for errors"
else
    echo -e "${YELLOW}⚠️  HTTP Status: $HTTP_CODE${NC}"
fi
echo ""

echo "${BLUE}6. Checking Backend Logs${NC}"
echo "------------------------"
echo "Last 10 lines of backend console:"
echo "(Look for errors or 'Fetching Firebase users' messages)"
echo ""
# Note: This won't work unless you're capturing logs to a file
# For now, just show a message
echo -e "${YELLOW}💡 Check your terminal where 'npm start' is running${NC}"
echo "Look for:"
echo "  - 🔥 Fetching Firebase users"
echo "  - ✅ Firebase users fetched successfully"
echo "  - ❌ Any error messages"
echo ""

echo "${BLUE}7. Testing MongoDB Connection${NC}"
echo "-------------------------------"
# This is a simple test - just check if any endpoint works
COFFEES_TEST=$(curl -s "${BACKEND_URL}/api/coffees?limit=1")
if echo "$COFFEES_TEST" | grep -q '"success":true'; then
    echo -e "${GREEN}✅ MongoDB connection working (tested with /api/coffees)${NC}"
else
    echo -e "${RED}❌ MongoDB might be disconnected${NC}"
fi
echo ""

echo "${BLUE}8. Testing Firebase Admin SDK${NC}"
echo "-------------------------------"
# Test if Firebase is initialized by trying to fetch users
if echo "$USERS_RESPONSE" | grep -q '"uid"'; then
    echo -e "${GREEN}✅ Firebase Admin SDK working (UIDs found in response)${NC}"
elif echo "$USERS_RESPONSE" | grep -qi "firebase"; then
    echo -e "${RED}❌ Firebase error in response${NC}"
    echo "$USERS_RESPONSE" | grep -i firebase
else
    echo -e "${YELLOW}⚠️  Cannot determine Firebase SDK status${NC}"
fi
echo ""

echo "${BLUE}9. Summary & Recommendations${NC}"
echo "=============================="

ISSUES_FOUND=0

# Check 1: Backend reachable
if ! echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    echo -e "${RED}❌ Issue: Backend not healthy${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 2: Token obtained
if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Issue: Cannot get admin token${NC}"
    echo "   Solution: Check ADMIN_USERNAME and ADMIN_PASSWORD in backend/.env"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 3: Users returned
if [ "$USER_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ Issue: No users returned from API${NC}"
    echo "   Possible causes:"
    echo "   - Firebase Admin SDK not initialized"
    echo "   - No users in Firebase Auth"
    echo "   - Firebase credentials incorrect in backend/.env"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Check 4: Response structure
if ! echo "$USERS_RESPONSE" | grep -q '"users":\['; then
    echo -e "${RED}❌ Issue: Response doesn't contain 'users' array${NC}"
    echo "   Solution: Check backend controller response format"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Backend API is working correctly."
    echo "If Flutter app still shows loading:"
    echo "  1. Hot restart Flutter app (R in terminal)"
    echo "  2. Check Flutter console for errors"
    echo "  3. Verify auth token is being stored in Flutter"
    echo "  4. Check app_constants.dart baseUrl matches backend"
else
    echo -e "${RED}Found $ISSUES_FOUND issue(s)${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Fix the issues listed above"
    echo "  2. Restart backend: cd backend && npm start"
    echo "  3. Rerun this test: bash test_firebase_users.sh"
fi

echo ""
echo "=================================="
echo "Test completed at $(date)"

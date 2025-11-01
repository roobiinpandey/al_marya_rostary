#!/bin/bash

# Get admin token
echo "🔐 Getting admin token..."
RESPONSE=$(curl -s -X POST "http://localhost:5001/api/auth/admin-login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "almarya2024"}')

echo "Response: $RESPONSE"

# Extract token using basic text processing
TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Token: $TOKEN"

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  exit 1
fi

echo ""
echo "🧪 Testing subscription APIs with admin token..."
echo "=================================================="

# Test 1: Get subscription plans
echo ""
echo "1️⃣ Testing GET /api/subscriptions/plans"
curl -s "http://localhost:5001/api/subscriptions/plans" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/json" | jq '.' || echo "❌ Failed"

# Test 2: Create subscription plan
echo ""
echo "2️⃣ Testing POST /api/subscriptions/plans"
curl -s -X POST "http://localhost:5001/api/subscriptions/plans" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "planId": "premium-monthly-001",
    "name": "Premium Coffee Monthly", 
    "description": "Premium coffee selection delivered monthly",
    "frequency": "monthly",
    "discountPercentage": 15,
    "minCommitmentMonths": 3,
    "benefits": [
      "Premium coffee beans",
      "Monthly delivery", 
      "Free shipping",
      "Coffee brewing guide"
    ],
    "isActive": true,
    "sortOrder": 1
  }' | jq '.' || echo "❌ Failed"

echo ""
echo "🎉 Testing complete!"

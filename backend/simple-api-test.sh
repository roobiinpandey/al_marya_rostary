#!/bin/bash

# Simple API Test - Run with server already started
# Usage: ./backend/simple-api-test.sh

BASE_URL="http://localhost:5001"

echo "🧪 Testing Dynamic Attribute APIs"
echo "=================================="
echo ""
echo "Note: Make sure server is running (npm start in backend/)"
echo ""

echo "1️⃣  Testing Attribute Groups..."
curl -s "$BASE_URL/api/attributes/groups" | head -c 200
echo ""
echo ""

echo "2️⃣  Testing Origin Countries (hierarchical)..."
curl -s "$BASE_URL/api/attributes/origin_countries/values?hierarchical=true" | head -c 200
echo ""
echo ""

echo "3️⃣  Testing Roast Levels..."
curl -s "$BASE_URL/api/attributes/roast_levels/values" | head -c 200
echo ""
echo ""

echo "4️⃣  Testing Processing Methods..."
curl -s "$BASE_URL/api/attributes/processing_methods/values" | head -c 200
echo ""
echo ""

echo "5️⃣  Testing Flavor Profiles..."
curl -s "$BASE_URL/api/attributes/flavor_profiles/values" | head -c 200
echo ""
echo ""

echo "✅ If you see JSON data above, APIs are working!"
echo "📝 Next: Test in browser at http://localhost:5001"

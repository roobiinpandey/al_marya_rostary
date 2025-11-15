#!/bin/bash

# 🚀 SIMPLE GUIDE: How to Test API Connectivity
# ============================================================

echo ""
echo "🧪 API CONNECTIVITY TEST - SIMPLE GUIDE"
echo "========================================"
echo ""

# Step 1: Check if backend is running
echo "📍 STEP 1: Checking if backend is running..."
if curl -s http://localhost:5001/health > /dev/null 2>&1; then
    echo "   ✅ Backend is running on port 5001"
    BACKEND_RUNNING=true
else
    echo "   ❌ Backend is NOT running"
    echo ""
    echo "   👉 TO FIX: Open a terminal and run:"
    echo "      cd backend"
    echo "      npm start"
    echo ""
    echo "   Then come back and run this script again"
    exit 1
fi

echo ""

# Step 2: Check if test users exist
echo "📍 STEP 2: Setting up test users..."
echo "   Creating test accounts for Customer, Staff, and Driver..."
node setup-test-users.js

echo ""

# Step 3: Run the connectivity test
echo "📍 STEP 3: Running API connectivity test..."
echo ""
node api_connectivity_check.js

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! All apps are connected to the backend!"
    echo ""
    echo "📁 Check detailed logs in: logs/api_test.log"
    echo "📊 JSON results saved in: logs/test_results_*.json"
    echo ""
else
    echo ""
    echo "⚠️ Some tests failed. Check the output above for details."
    echo ""
    echo "💡 TIPS:"
    echo "   - Make sure backend is running (npm start)"
    echo "   - Check if test users were created successfully"
    echo "   - Review logs/api_test.log for error details"
    echo ""
fi

#!/bin/bash

# Quick API Connectivity Test
# Tests all endpoints and prints summary

echo "🚀 Starting API Connectivity Check..."
echo ""

# Check if backend is running
if ! curl -s http://localhost:5001/health > /dev/null 2>&1; then
    echo "❌ Backend is not running on port 5001"
    echo "Please start the backend first: npm start"
    exit 1
fi

echo "✅ Backend is running"
echo ""

# Run the connectivity check
node api_connectivity_check.js

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
    exit 0
else
    echo ""
    echo "❌ Some tests failed. Check logs/api_test.log for details"
    exit 1
fi

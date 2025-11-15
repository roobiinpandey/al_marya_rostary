#!/bin/bash

# Al Marya Rostery - Backend Startup Script
# This script ensures the backend stays running and Flutter can connect

echo "🚀 Al Marya Rostery Backend Startup"
echo "==================================="

# Change to backend directory
cd "$(dirname "$0")"

# Kill any existing processes on port 5001
echo "🔍 Checking for existing processes on port 5001..."
PID=$(lsof -ti:5001)
if [ ! -z "$PID" ]; then
    echo "💀 Killing existing process on port 5001 (PID: $PID)"
    kill -9 $PID
    sleep 2
fi

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing npm dependencies..."
    npm install
fi

# Start the backend server
echo "🚀 Starting Al Marya Rostery Backend Server..."
echo "📱 Flutter app will connect to: http://localhost:5001"
echo "🌐 Admin panel will be available at: http://localhost:5001"
echo ""
echo "⏹️  Press Ctrl+C to stop the server"
echo ""

# Start with proper environment
NODE_ENV=development PORT=5001 npm run dev

#!/bin/bash

# Script to kill any process using port 5001 and start the server fresh

PORT=5001

echo "🔍 Checking for processes using port $PORT..."

# Find process using the port
PID=$(lsof -ti:$PORT)

if [ -n "$PID" ]; then
    echo "💀 Found process $PID using port $PORT. Killing it..."
    kill -9 $PID
    sleep 2
    
    # Verify it's killed
    NEW_PID=$(lsof -ti:$PORT)
    if [ -n "$NEW_PID" ]; then
        echo "❌ Failed to kill process. Trying force kill..."
        sudo kill -9 $NEW_PID
    else
        echo "✅ Successfully killed process using port $PORT"
    fi
else
    echo "✅ No process found using port $PORT"
fi

echo "🚀 Port $PORT is now free. You can start the server!"

#!/bin/bash

# Render Deployment Startup Script
# This script ensures proper deployment on Render.com

echo "🚀 Starting Al Marya Rostery Backend Deployment..."

# Set default environment values if not provided
export NODE_ENV=${NODE_ENV:-production}
export PORT=${PORT:-10000}

# Validate critical environment variables
if [ -z "$MONGODB_URI" ]; then
    echo "❌ ERROR: MONGODB_URI is required"
    exit 1
fi

if [ -z "$JWT_SECRET" ]; then
    echo "❌ ERROR: JWT_SECRET is required"
    exit 1
fi

# Show deployment configuration
echo "📋 Deployment Configuration:"
echo "   - NODE_ENV: $NODE_ENV"
echo "   - PORT: $PORT"
echo "   - Database: ${MONGODB_URI:0:20}..."
echo "   - JWT configured: $([ -n "$JWT_SECRET" ] && echo "✅" || echo "❌")"
echo "   - Firebase configured: $([ -n "$FIREBASE_PROJECT_ID" ] && echo "✅" || echo "⚠️  Optional")"
echo "   - SMTP configured: $([ -n "$SMTP_HOST" ] && echo "✅" || echo "⚠️  Optional")"

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
    echo "✅ Dependencies installed successfully"
else
    echo "✅ Dependencies already installed"
fi

# Run the application
echo "🚀 Starting server..."
node server.js
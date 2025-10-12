#!/bin/bash

# Qahwat Al Emarat Production Deployment Script
# This script helps you deploy your app to Render.com with proper security

set -e

echo "🚀 Qahwat Al Emarat - Production Deployment Setup"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Error: This script must be run from the backend directory${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Pre-deployment Checklist${NC}"
echo "================================"

# Generate secure secrets
echo -e "${YELLOW}🔐 Generating secure secrets...${NC}"
node scripts/generateSecrets.js > deployment-secrets.txt
echo -e "${GREEN}✅ Secrets generated and saved to deployment-secrets.txt${NC}"

# Check dependencies
echo -e "${YELLOW}📦 Checking dependencies...${NC}"
npm audit --audit-level moderate
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ No critical vulnerabilities found${NC}"
else
    echo -e "${RED}⚠️  Security vulnerabilities detected. Fix them before deploying.${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check environment variables
echo -e "${YELLOW}🔧 Checking environment configuration...${NC}"
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ .env file exists${NC}"
    
    # Check for sensitive data in .env
    if grep -q "Nepal1590\|qahwat2024\|your_" .env; then
        echo -e "${RED}❌ Found default/insecure values in .env file${NC}"
        echo -e "${YELLOW}⚠️  Update your .env file with secure values before deploying${NC}"
    else
        echo -e "${GREEN}✅ .env file appears secure${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No .env file found (this is OK for production)${NC}"
fi

# MongoDB Atlas checklist
echo -e "\n${BLUE}🗄️  MongoDB Atlas Security Checklist${NC}"
echo "====================================="
echo "1. ✓ Create new production database user"
echo "2. ✓ Use strong password (generated in deployment-secrets.txt)"
echo "3. ✓ Restrict user to qahwat_al_emarat database only"
echo "4. ✓ Enable IP whitelist (remove 0.0.0.0/0)"
echo "5. ✓ Add Render.com IP ranges to whitelist"
echo ""
read -p "Have you completed MongoDB Atlas security setup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please complete MongoDB Atlas setup before continuing${NC}"
    echo "MongoDB Atlas Dashboard: https://cloud.mongodb.com/"
    exit 1
fi

# Render.com deployment checklist
echo -e "\n${BLUE}🌐 Render.com Deployment Checklist${NC}"
echo "=================================="
echo "1. ✓ Create new Web Service on Render.com"
echo "2. ✓ Connect your GitHub repository"
echo "3. ✓ Set Build Command: 'npm ci --only=production'"
echo "4. ✓ Set Start Command: 'npm start'"
echo "5. ✓ Choose Standard plan ($7/month) for production"
echo "6. ✓ Set health check path: '/health'"
echo "7. ✓ Configure environment variables from deployment-secrets.txt"
echo ""

# Display environment variables to set
echo -e "${YELLOW}🔑 Environment Variables for Render.com Dashboard:${NC}"
echo "=============================================="
echo "Copy the values from 'deployment-secrets.txt' to Render.com environment variables:"
echo ""
cat deployment-secrets.txt
echo ""
echo -e "${YELLOW}Additional variables to set manually:${NC}"
echo "MONGODB_URI=<your_secure_connection_string>"
echo "FIREBASE_PRIVATE_KEY=<your_firebase_private_key>"
echo "FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@***REMOVED***.iam.gserviceaccount.com"
echo "FIREBASE_PROJECT_ID=***REMOVED***"
echo "BASE_URL=https://your-app-name.onrender.com"
echo "SMTP_USER=<your_email_provider_user>"
echo "SMTP_PASS=<your_email_provider_password>"
echo ""

read -p "Have you set all environment variables in Render.com? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please set environment variables in Render.com dashboard before deploying${NC}"
    echo "Render.com Dashboard: https://dashboard.render.com/"
    exit 1
fi

# Git preparation
echo -e "\n${YELLOW}📚 Preparing Git repository...${NC}"

# Check if git repo exists
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    git add .
    git commit -m "Initial commit - Qahwat Al Emarat backend"
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}You have uncommitted changes. Committing them...${NC}"
    git add .
    git commit -m "Pre-deployment updates - security and performance optimizations"
fi

# Security check - ensure no secrets in git
echo -e "${YELLOW}🔍 Performing security check...${NC}"
if git log --all --grep="password\|secret\|key" --oneline | grep -i "password\|secret\|key"; then
    echo -e "${RED}⚠️  Found potential secrets in git history${NC}"
    echo -e "${YELLOW}Review your git history for exposed secrets${NC}"
fi

# Check .gitignore
if [ ! -f ".gitignore" ]; then
    echo -e "${YELLOW}Creating .gitignore file...${NC}"
    cat > .gitignore << EOF
# Dependencies
node_modules/
npm-debug.log*

# Environment files
.env
.env.local
.env.production
deployment-secrets.txt

# Runtime
*.log
*.pid

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Uploads
uploads/*
!uploads/.gitkeep

# Cache
.cache/
.tmp/
EOF
    git add .gitignore
    git commit -m "Add .gitignore for security"
fi

# Performance test
echo -e "\n${YELLOW}⚡ Running performance test...${NC}"
if command -v npm &> /dev/null; then
    echo "Testing application startup..."
    timeout 30s npm start &
    sleep 5
    if curl -s http://localhost:10000/health > /dev/null; then
        echo -e "${GREEN}✅ Application starts successfully${NC}"
        pkill -f "node.*server.js" 2>/dev/null || true
    else
        echo -e "${RED}❌ Application failed to start properly${NC}"
        pkill -f "node.*server.js" 2>/dev/null || true
        exit 1
    fi
fi

# Final instructions
echo -e "\n${GREEN}🎉 Pre-deployment checks completed successfully!${NC}"
echo "=============================================="
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "1. Push your code to GitHub: git push origin main"
echo "2. Go to Render.com dashboard: https://dashboard.render.com/"
echo "3. Create new Web Service from your GitHub repo"
echo "4. Set environment variables from deployment-secrets.txt"
echo "5. Deploy and monitor the deployment logs"
echo ""
echo -e "${BLUE}🔍 Post-deployment verification:${NC}"
echo "1. Check health endpoint: https://your-app.onrender.com/health"
echo "2. Test API endpoints: https://your-app.onrender.com/api/"
echo "3. Monitor application logs in Render dashboard"
echo "4. Test admin panel: https://your-app.onrender.com/admin.html"
echo ""
echo -e "${YELLOW}⚠️  Important Security Notes:${NC}"
echo "1. Never commit deployment-secrets.txt to git"
echo "2. Regularly rotate your JWT secrets and passwords"
echo "3. Monitor application logs for security issues"
echo "4. Keep dependencies updated"
echo ""
echo -e "${RED}🔥 Remember to delete deployment-secrets.txt after setting environment variables!${NC}"

# Cleanup option
read -p "Delete deployment-secrets.txt now? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    rm -f deployment-secrets.txt
    echo -e "${GREEN}✅ deployment-secrets.txt deleted${NC}"
else
    echo -e "${YELLOW}⚠️  Remember to delete deployment-secrets.txt manually${NC}"
fi

echo -e "\n${GREEN}🚀 Ready for production deployment!${NC}"

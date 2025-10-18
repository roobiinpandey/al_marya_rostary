#!/bin/bash

# 🔐 OAuth Setup Helper Script
# This script helps you set up Google and Facebook authentication

echo "🔐 OAuth Authentication Setup Helper"
echo "===================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found${NC}"
    echo "Please run this script from the Flutter project root directory"
    exit 1
fi

echo -e "${BLUE}📱 Checking Flutter packages...${NC}"

# Check if google_sign_in is installed
if grep -q "google_sign_in:" pubspec.yaml; then
    echo -e "${GREEN}✅ google_sign_in package found${NC}"
else
    echo -e "${RED}❌ google_sign_in package not found${NC}"
    exit 1
fi

# Check if firebase_auth is installed
if grep -q "firebase_auth:" pubspec.yaml; then
    echo -e "${GREEN}✅ firebase_auth package found${NC}"
else
    echo -e "${RED}❌ firebase_auth package not found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔧 Checking Firebase configuration files...${NC}"

# Check for iOS GoogleService-Info.plist
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo -e "${GREEN}✅ iOS GoogleService-Info.plist found${NC}"
else
    echo -e "${YELLOW}⚠️  iOS GoogleService-Info.plist not found${NC}"
    echo "   Download from Firebase Console and place in ios/Runner/"
fi

# Check for Android google-services.json
if [ -f "android/app/google-services.json" ]; then
    echo -e "${GREEN}✅ Android google-services.json found${NC}"
else
    echo -e "${YELLOW}⚠️  Android google-services.json not found${NC}"
    echo "   Download from Firebase Console and place in android/app/"
fi

echo ""
echo -e "${BLUE}🖥️  Checking Backend setup...${NC}"

# Check if oauthController exists
if [ -f "backend/controllers/oauthController.js" ]; then
    echo -e "${GREEN}✅ OAuth controller found${NC}"
else
    echo -e "${RED}❌ OAuth controller not found${NC}"
    echo "   The controller has been created. Check backend/controllers/oauthController.js"
fi

# Check if OAuth routes are added
if grep -q "googleAuth" backend/routes/auth.js 2>/dev/null; then
    echo -e "${GREEN}✅ OAuth routes configured${NC}"
else
    echo -e "${YELLOW}⚠️  OAuth routes not found in auth.js${NC}"
fi

echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo ""
echo "1️⃣  Firebase Console Setup:"
echo "   • Go to https://console.firebase.google.com/"
echo "   • Enable Google & Facebook authentication"
echo "   • Download config files if missing"
echo ""
echo "2️⃣  Google Cloud Console:"
echo "   • Go to https://console.cloud.google.com/"
echo "   • Create OAuth 2.0 Client IDs (Android, iOS, Web)"
echo "   • Add SHA-1 fingerprint for Android"
echo ""
echo "3️⃣  Facebook Developers:"
echo "   • Go to https://developers.facebook.com/"
echo "   • Create app and enable Facebook Login"
echo "   • Configure platforms (iOS, Android, Web)"
echo ""
echo "4️⃣  Backend Environment Variables:"
echo "   Check that backend/.env has:"
echo "   • JWT_SECRET=<your-secret>"
echo "   • FIREBASE_PROJECT_ID=<your-project-id>"
echo ""
echo "5️⃣  Test the setup:"
echo "   • Start backend: cd backend && npm start"
echo "   • Run Flutter: flutter run"
echo "   • Try Google login"
echo ""
echo -e "${GREEN}📖 For detailed instructions, see:${NC}"
echo "   COMPLETE_OAUTH_SETUP_GUIDE.md"
echo ""

# Ask if user wants to get SHA-1 fingerprint
echo -e "${YELLOW}Do you want to get your Android SHA-1 fingerprint now? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}🔐 Getting SHA-1 fingerprint...${NC}"
    
    if [ -f "android/gradlew" ]; then
        cd android || exit
        ./gradlew signingReport | grep "SHA1:" | head -1
        cd ..
    else
        echo -e "${YELLOW}⚠️  gradlew not found. Run manually:${NC}"
        echo "   cd android && ./gradlew signingReport"
    fi
fi

echo ""
echo -e "${GREEN}✅ Setup check complete!${NC}"
echo ""

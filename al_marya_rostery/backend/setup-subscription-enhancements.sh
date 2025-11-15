#!/bin/bash

# Al Marya Rostery - Subscription Enhancement Installation
# This script installs required dependencies and sets up the subscription system

echo "🚀 Al Marya Rostery - Subscription Enhancement Setup"
echo "=================================================="
echo ""

# Check if we're in the backend directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Must be run from the backend directory"
    echo "   cd backend && ./setup-subscription-enhancements.sh"
    exit 1
fi

echo "📦 Step 1: Installing npm dependencies..."
echo "Installing node-cron for automated tasks..."
npm install node-cron@^3.0.3

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed successfully"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found"
    echo "   Creating from .env.example..."
    cp .env.example .env
    echo "   ⚠️  Please update .env with your Stripe credentials"
else
    echo "✅ .env file found"
fi

echo ""
echo "🔑 Step 2: Checking Stripe configuration..."

# Check if Stripe keys are set
if grep -q "STRIPE_SECRET_KEY=your_stripe_secret_key" .env 2>/dev/null || \
   ! grep -q "STRIPE_SECRET_KEY=" .env 2>/dev/null; then
    echo "⚠️  Stripe credentials not configured"
    echo ""
    echo "   Please add to .env:"
    echo "   STRIPE_SECRET_KEY=sk_test_..."
    echo "   STRIPE_WEBHOOK_SECRET=whsec_..."
    echo "   STRIPE_PUBLISHABLE_KEY=pk_test_..."
else
    echo "✅ Stripe credentials found in .env"
fi

echo ""
echo "🗄️  Step 3: Checking MongoDB connection..."

# Check if MongoDB URI is set
if grep -q "MONGODB_URI=your_mongodb_uri_here" .env 2>/dev/null || \
   ! grep -q "MONGODB_URI=" .env 2>/dev/null; then
    echo "⚠️  MongoDB URI not configured"
else
    echo "✅ MongoDB URI found"
fi

echo ""
echo "📝 Step 4: Verifying file structure..."

REQUIRED_FILES=(
    "config/stripe.js"
    "services/stripeSubscriptionService.js"
    "services/subscriptionCronService.js"
    "services/notificationService.js"
    "routes/stripe-webhooks.js"
    "routes/subscription-analytics.js"
    "models/ReferralCode.js"
)

ALL_FILES_EXIST=true

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ Missing: $file"
        ALL_FILES_EXIST=false
    fi
done

if [ "$ALL_FILES_EXIST" = false ]; then
    echo ""
    echo "⚠️  Some files are missing. Please check the implementation."
fi

echo ""
echo "=================================================="
echo "🎉 Setup Complete!"
echo ""
echo "📚 Next Steps:"
echo ""
echo "1. Configure Stripe (if not done):"
echo "   - Get API keys from https://dashboard.stripe.com/test/apikeys"
echo "   - Add keys to .env file"
echo "   - Setup webhook endpoint at /api/stripe/webhook"
echo ""
echo "2. Enable subscription cron jobs:"
echo "   - Set ENABLE_SUBSCRIPTION_CRON=true in .env"
echo ""
echo "3. Test the setup:"
echo "   npm start"
echo ""
echo "4. View documentation:"
echo "   cat ../SUBSCRIPTION_ENHANCEMENT_GUIDE.md"
echo ""
echo "5. Test Stripe integration:"
echo "   - Use test card: 4242 4242 4242 4242"
echo "   - Create a subscription via API"
echo ""
echo "=================================================="
echo ""
echo "For issues or questions, see the documentation at:"
echo "../SUBSCRIPTION_ENHANCEMENT_GUIDE.md"
echo ""

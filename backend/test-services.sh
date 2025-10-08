#!/bin/bash

# Complete Service Configuration Test
echo "🚀 Testing All Service Configurations..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}📋 Testing: $test_name${NC}"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ $test_name: PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ $test_name: FAILED${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Create comprehensive test file
cat > test-all-services.js << 'EOF'
const mongoose = require('mongoose');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Colors for console output
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m'
};

function log(color, message) {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testMongoDB() {
    try {
        log('blue', '🗄️  Testing MongoDB connection...');
        
        if (!process.env.MONGODB_URI) {
            throw new Error('MONGODB_URI not set');
        }
        
        await mongoose.connect(process.env.MONGODB_URI);
        log('green', '✅ MongoDB connected successfully');
        
        // Test database operations
        const collections = await mongoose.connection.db.listCollections().toArray();
        log('blue', `📊 Found ${collections.length} collections`);
        
        await mongoose.disconnect();
        return true;
        
    } catch (error) {
        log('red', `❌ MongoDB test failed: ${error.message}`);
        return false;
    }
}

async function testFirebase() {
    try {
        log('blue', '🔥 Testing Firebase configuration...');
        
        const serviceAccountKey = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
        const projectId = process.env.FIREBASE_PROJECT_ID;
        
        if (!serviceAccountKey) {
            throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY not set');
        }
        
        if (!projectId) {
            throw new Error('FIREBASE_PROJECT_ID not set');
        }
        
        // Parse and validate service account
        const serviceAccount = JSON.parse(serviceAccountKey);
        
        if (!serviceAccount.project_id) {
            throw new Error('Invalid service account: missing project_id');
        }
        
        // Initialize Firebase (if not already initialized)
        if (admin.apps.length === 0) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
                projectId: projectId
            });
        }
        
        log('green', '✅ Firebase initialized successfully');
        log('blue', `📱 Project ID: ${projectId}`);
        
        return true;
        
    } catch (error) {
        log('red', `❌ Firebase test failed: ${error.message}`);
        return false;
    }
}

async function testEmail() {
    try {
        log('blue', '📧 Testing email configuration...');
        
        const requiredVars = ['SMTP_HOST', 'SMTP_USER', 'SMTP_PASS'];
        for (const varName of requiredVars) {
            if (!process.env[varName]) {
                throw new Error(`${varName} not set`);
            }
        }
        
        const emailConfig = {
            host: process.env.SMTP_HOST,
            port: parseInt(process.env.SMTP_PORT) || 587,
            secure: process.env.SMTP_SECURE === 'true',
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        };
        
        const transporter = nodemailer.createTransporter(emailConfig);
        
        // Verify SMTP connection
        await transporter.verify();
        log('green', '✅ Email service configured successfully');
        
        return true;
        
    } catch (error) {
        log('red', `❌ Email test failed: ${error.message}`);
        return false;
    }
}

async function testJWT() {
    try {
        log('blue', '🔐 Testing JWT configuration...');
        
        const jwtSecret = process.env.JWT_SECRET;
        
        if (!jwtSecret) {
            throw new Error('JWT_SECRET not set');
        }
        
        if (jwtSecret.length < 32) {
            throw new Error('JWT_SECRET should be at least 32 characters long');
        }
        
        log('green', '✅ JWT configuration valid');
        log('blue', `🔑 Secret length: ${jwtSecret.length} characters`);
        
        return true;
        
    } catch (error) {
        log('red', `❌ JWT test failed: ${error.message}`);
        return false;
    }
}

async function testEnvironmentVariables() {
    try {
        log('blue', '⚙️  Testing environment variables...');
        
        const requiredVars = [
            'NODE_ENV',
            'MONGODB_URI',
            'JWT_SECRET',
            'BASE_URL'
        ];
        
        const missingVars = [];
        
        for (const varName of requiredVars) {
            if (!process.env[varName]) {
                missingVars.push(varName);
            }
        }
        
        if (missingVars.length > 0) {
            throw new Error(`Missing required variables: ${missingVars.join(', ')}`);
        }
        
        log('green', '✅ All required environment variables are set');
        log('blue', `🌍 Environment: ${process.env.NODE_ENV}`);
        log('blue', `🔗 Base URL: ${process.env.BASE_URL}`);
        
        return true;
        
    } catch (error) {
        log('red', `❌ Environment variables test failed: ${error.message}`);
        return false;
    }
}

async function runAllTests() {
    log('blue', '🚀 Starting comprehensive service configuration test...\n');
    
    const tests = [
        { name: 'Environment Variables', fn: testEnvironmentVariables },
        { name: 'JWT Configuration', fn: testJWT },
        { name: 'MongoDB Connection', fn: testMongoDB },
        { name: 'Firebase Configuration', fn: testFirebase },
        { name: 'Email Service', fn: testEmail }
    ];
    
    let passed = 0;
    let failed = 0;
    
    for (const test of tests) {
        try {
            const result = await test.fn();
            if (result) {
                passed++;
            } else {
                failed++;
            }
        } catch (error) {
            log('red', `❌ ${test.name} test crashed: ${error.message}`);
            failed++;
        }
        console.log(''); // Add spacing
    }
    
    // Summary
    log('blue', '📊 Test Summary:');
    log('green', `✅ Passed: ${passed}`);
    if (failed > 0) {
        log('red', `❌ Failed: ${failed}`);
    }
    
    const totalTests = tests.length;
    const successRate = Math.round((passed / totalTests) * 100);
    
    if (failed === 0) {
        log('green', `🎉 All tests passed! Success rate: ${successRate}%`);
        log('green', '🚀 Your application is ready for production deployment!');
    } else {
        log('yellow', `⚠️  Some tests failed. Success rate: ${successRate}%`);
        log('yellow', '🔧 Please fix the failing configurations before deploying to production.');
    }
    
    process.exit(failed > 0 ? 1 : 0);
}

runAllTests().catch(error => {
    log('red', `💥 Test suite crashed: ${error.message}`);
    process.exit(1);
});
EOF

# Run comprehensive test
echo -e "${BLUE}🧪 Running comprehensive service test...${NC}"
node test-all-services.js

TEST_EXIT_CODE=$?

# Cleanup
rm -f test-all-services.js

# Final summary
echo ""
echo -e "${BLUE}📋 Service Configuration Test Complete${NC}"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}🎉 All services are properly configured!${NC}"
    echo -e "${GREEN}✅ Your backend is ready for production deployment.${NC}"
    echo ""
    echo -e "${BLUE}🚀 Next steps:${NC}"
    echo "1. Deploy to Render using the configured environment variables"
    echo "2. Monitor deployment logs for successful service initialization"
    echo "3. Test API endpoints after deployment"
    echo "4. Update Flutter app with production API URL"
else
    echo -e "${RED}❌ Some service configurations failed.${NC}"
    echo -e "${YELLOW}🔧 Please review the error messages above and fix the issues.${NC}"
    echo ""
    echo -e "${BLUE}📚 Configuration guides:${NC}"
    echo "• FIREBASE_SETUP_GUIDE.md - Firebase push notifications"
    echo "• EMAIL_SETUP_GUIDE.md - Email service configuration"
    echo "• ENVIRONMENT_VARIABLES.md - Complete variable reference"
fi

exit $TEST_EXIT_CODE

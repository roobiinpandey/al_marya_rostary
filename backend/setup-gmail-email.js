#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(prompt) {
  return new Promise(resolve => rl.question(prompt, resolve));
}

async function setupGmailConfig() {
  console.log('\n📧 Gmail Email Configuration Setup');
  console.log('=====================================');
  console.log('\nThis will help you configure Gmail SMTP for development.');
  console.log('\n⚠️  Requirements:');
  console.log('1. Gmail account with 2-factor authentication enabled');
  console.log('2. App-specific password generated (not your regular Gmail password)');
  console.log('\n💡 To create an app password:');
  console.log('   1. Go to Google Account settings');
  console.log('   2. Security → 2-Step Verification → App passwords');
  console.log('   3. Generate password for "Mail"');
  console.log('   4. Use that password below (not your regular password)');
  
  const proceed = await question('\nReady to proceed? (y/n): ');
  if (proceed.toLowerCase() !== 'y') {
    console.log('Setup cancelled.');
    rl.close();
    return;
  }
  
  console.log('\n📝 Enter your Gmail configuration:');
  
  const email = await question('Gmail address: ');
  const appPassword = await question('App-specific password (not regular password): ');
  const fromName = await question('Sender name (default: Qahwat Al Emarat): ') || 'Qahwat Al Emarat';
  const baseUrl = await question('Base URL (e.g., https://yourapp.render.com or http://localhost:3000): ');
  
  if (!email || !appPassword || !baseUrl) {
    console.log('\n❌ All fields are required. Setup cancelled.');
    rl.close();
    return;
  }
  
  // Create environment variables
  const envContent = `
# Gmail SMTP Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=${email}
SMTP_PASS=${appPassword}
EMAIL_FROM_NAME=${fromName}
EMAIL_FROM_ADDRESS=${email}

# Application Configuration
BASE_URL=${baseUrl}
NODE_ENV=development

# Add other environment variables here
# JWT_SECRET=your-jwt-secret
# MONGODB_URI=your-mongodb-connection-string
`;

  // Write to .env file
  const envPath = path.join(__dirname, '.env');
  try {
    // Check if .env already exists
    if (fs.existsSync(envPath)) {
      const backup = await question('\n.env file already exists. Create backup? (y/n): ');
      if (backup.toLowerCase() === 'y') {
        fs.copyFileSync(envPath, `${envPath}.backup.${Date.now()}`);
        console.log('✅ Backup created');
      }
    }
    
    fs.writeFileSync(envPath, envContent.trim());
    console.log('\n✅ Email configuration saved to .env file');
    
    // Test the configuration
    console.log('\n🧪 Testing email configuration...');
    
    // Load the new environment variables
    require('dotenv').config();
    
    // Wait a moment for the config to load
    setTimeout(async () => {
      try {
        const testEmail = await question('Enter test email address (or press Enter to skip): ');
        if (testEmail) {
          console.log('\n🚀 Running email test...');
          const { spawn } = require('child_process');
          const test = spawn('node', ['test-email-config.js', testEmail], {
            stdio: 'inherit',
            cwd: __dirname
          });
          
          test.on('close', (code) => {
            console.log('\n📋 Next Steps:');
            console.log('1. Check your email for the test message');
            console.log('2. If successful, your app can now send emails!');
            console.log('3. For production, consider using SendGrid or AWS SES');
            console.log('\n💡 To update Render with these settings:');
            console.log('   1. Go to Render Dashboard → Your Service → Environment');
            console.log('   2. Add the email environment variables');
            console.log('   3. Deploy your service');
            rl.close();
          });
        } else {
          console.log('\n📋 Configuration complete! Test skipped.');
          console.log('\n💡 To test later, run: node test-email-config.js your-email@example.com');
          rl.close();
        }
      } catch (error) {
        console.log('\n❌ Error during test:', error.message);
        rl.close();
      }
    }, 1000);
    
  } catch (error) {
    console.log('\n❌ Error saving configuration:', error.message);
    rl.close();
  }
}

// Run the setup
setupGmailConfig().catch(error => {
  console.error('💥 Setup error:', error);
  rl.close();
  process.exit(1);
});

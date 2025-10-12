console.log('=== RENDER ENVIRONMENT VARIABLES - COPY AND PASTE ===');
console.log('');
console.log('🚀 COPY THE FOLLOWING VARIABLES TO RENDER DASHBOARD:');
console.log('');

console.log('🔐 REQUIRED - JWT Configuration:');
console.log('JWT_SECRET=[GENERATED-JWT-SECRET-FROM-GENERATE-JWT-SECRETS.JS]');
console.log('JWT_REFRESH_SECRET=[GENERATED-REFRESH-SECRET-FROM-GENERATE-JWT-SECRETS.JS]');
console.log('JWT_EXPIRE=7d');
console.log('');

console.log('🗄️  REQUIRED - Database:');
console.log('MONGODB_URI=[YOUR-MONGODB-ATLAS-CONNECTION-STRING]');
console.log('');

console.log('🌐 REQUIRED - App Configuration:');
console.log('NODE_ENV=production');
console.log('PORT=3000');
console.log('BASE_URL=https://al-marya-rostary.onrender.com');
console.log('');

console.log('📧 REQUIRED - Email Configuration:');
console.log('EMAIL_FROM_ADDRESS=[YOUR-EMAIL-ADDRESS]');
console.log('EMAIL_FROM_NAME=Qahwat Al Emarat');
console.log('');

console.log('👤 REQUIRED - Admin Configuration:');
console.log('ADMIN_USERNAME=admin');
console.log('ADMIN_PASSWORD=qahwat2024');
console.log('');

console.log('🔥 REQUIRED - Firebase Configuration:');
console.log('FIREBASE_PROJECT=qahwatapp');
console.log('');
console.log('FIREBASE_SERVICE_ACCOUNT_KEY=[YOUR-FIREBASE-SERVICE-ACCOUNT-JSON-STRING]');
console.log('');
console.log('ℹ️  To get Firebase Service Account Key:');
console.log('   1. Go to Firebase Console → Project Settings → Service Accounts');
console.log('   2. Generate new private key');
console.log('   3. Copy entire JSON and stringify it for environment variable');
console.log('');

console.log('📧 OPTIONAL - SMTP Fallback (skip if using only Firebase):');
console.log('SMTP_HOST=smtp.gmail.com');
console.log('SMTP_PORT=587');
console.log('SMTP_SECURE=false');
console.log('SMTP_USER=[YOUR-SMTP-EMAIL]');
console.log('SMTP_PASS=[YOUR-SMTP-APP-PASSWORD]');
console.log('');

console.log('🚀 DEPLOYMENT STEPS:');
console.log('1. Go to Render Dashboard → qahwatapp service → Environment');
console.log('2. Copy and paste EACH variable above (one per line)');
console.log('3. Click "Save Changes" - this will trigger automatic deployment');
console.log('4. Wait for deployment to complete (green checkmark)');
console.log('');

console.log('🔥 FIREBASE CONSOLE SETUP (Required!):');
console.log('1. Go to: https://console.firebase.google.com/project/qahwatapp');
console.log('2. Navigate to: Authentication → Settings → Authorized domains');
console.log('3. Add domain: al-marya-rostary.onrender.com');
console.log('4. Save changes');
console.log('');

console.log('✅ TEST YOUR ADMIN LOGIN:');
console.log('URL: https://al-marya-rostary.onrender.com/admin.html');
console.log('Username: admin');
console.log('Password: qahwat2024');
console.log('');
console.log('🎉 Everything should work perfectly now!');

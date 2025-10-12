const crypto = require('crypto');

/**
 * Generate secure secrets for production environment
 */
const generateSecrets = () => {
  console.log('🔐 Generating secure secrets for production...\n');
  
  // Generate JWT secrets
  const jwtSecret = crypto.randomBytes(64).toString('hex');
  const jwtRefreshSecret = crypto.randomBytes(64).toString('hex');
  
  // Generate admin password
  const adminPassword = crypto.randomBytes(16).toString('base64').replace(/[^a-zA-Z0-9]/g, 'X');
  
  // Generate database password
  const dbPassword = crypto.randomBytes(24).toString('base64').replace(/[^a-zA-Z0-9]/g, 'Q');
  
  console.log('Copy these values to your Render.com environment variables:\n');
  console.log('JWT_SECRET=' + jwtSecret);
  console.log('JWT_REFRESH_SECRET=' + jwtRefreshSecret);
  console.log('ADMIN_PASSWORD=' + adminPassword);
  console.log('DB_PASSWORD=' + dbPassword);
  
  console.log('\n📋 For MongoDB Atlas:');
  console.log('1. Go to Database Access in MongoDB Atlas');
  console.log('2. Create new user: qahwat_prod_user');
  console.log('3. Use password:', dbPassword);
  console.log('4. Assign role: Read and write to qahwat_al_emarat database only');
  
  console.log('\n🔒 For Render.com:');
  console.log('1. Go to your service settings');
  console.log('2. Add each environment variable above');
  console.log('3. Never commit these values to Git!');
  
  return {
    jwtSecret,
    jwtRefreshSecret,
    adminPassword,
    dbPassword
  };
};

if (require.main === module) {
  generateSecrets();
}

module.exports = generateSecrets;

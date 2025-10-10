#!/usr/bin/env node

/**
 * MongoDB Atlas Database User Setup Script
 * 
 * This script creates a database user for your MongoDB Atlas cluster
 * using the Atlas Management API with your provided API keys.
 */

require('dotenv').config();
const https = require('https');

// Atlas API configuration
const PROJECT_ID = '***REMOVED***'; // This might need to be adjusted based on your actual project ID
const CLUSTER_NAME = '***REMOVED***';
const PUBLIC_KEY = process.env.MONGODB_ATLAS_PUBLIC_KEY;
const PRIVATE_KEY = process.env.MONGODB_ATLAS_PRIVATE_KEY;

// Database user configuration
const DB_USER = {
  username: 'qahwat_user',
  password: 'qahwat_secure_2025',
  roles: [
    {
      roleName: 'readWrite',
      databaseName: 'qahwat_al_emarat'
    }
  ],
  scopes: [
    {
      name: CLUSTER_NAME,
      type: 'CLUSTER'
    }
  ]
};

/**
 * Create a database user in MongoDB Atlas
 */
async function createDatabaseUser() {
  const auth = Buffer.from(`${PUBLIC_KEY}:${PRIVATE_KEY}`).toString('base64');
  
  const postData = JSON.stringify(DB_USER);
  
  const options = {
    hostname: 'cloud.mongodb.com',
    port: 443,
    path: `/api/atlas/v1.0/groups/${PROJECT_ID}/databaseUsers`,
    method: 'POST',
    headers: {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (res.statusCode === 201) {
            console.log('✅ Database user created successfully!');
            console.log(`Username: ${DB_USER.username}`);
            console.log(`Password: ${DB_USER.password}`);
            console.log('\n📋 Connection String:');
            console.log(`***REMOVED***${DB_USER.username}:${DB_USER.password}@***REMOVED***.ph5cazq.mongodb.net/qahwat_al_emarat?retryWrites=true&w=majority&appName=***REMOVED***`);
            resolve(response);
          } else {
            console.error('❌ Failed to create database user:', response);
            reject(new Error(`HTTP ${res.statusCode}: ${response.message || 'Unknown error'}`));
          }
        } catch (error) {
          console.error('❌ Error parsing response:', error.message);
          console.error('Raw response:', data);
          reject(error);
        }
      });
    });

    req.on('error', (error) => {
      console.error('❌ Request error:', error.message);
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Get project information to verify access
 */
async function getProjectInfo() {
  const auth = Buffer.from(`${PUBLIC_KEY}:${PRIVATE_KEY}`).toString('base64');
  
  const options = {
    hostname: 'cloud.mongodb.com',
    port: 443,
    path: `/api/atlas/v1.0/groups/${PROJECT_ID}`,
    method: 'GET',
    headers: {
      'Authorization': `Basic ${auth}`,
      'Content-Type': 'application/json'
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          if (res.statusCode === 200) {
            console.log('✅ Project access verified!');
            console.log(`Project Name: ${response.name}`);
            console.log(`Project ID: ${response.id}`);
            resolve(response);
          } else {
            console.error('❌ Failed to get project info:', response);
            reject(new Error(`HTTP ${res.statusCode}: ${response.message || 'Unknown error'}`));
          }
        } catch (error) {
          console.error('❌ Error parsing response:', error.message);
          console.error('Raw response:', data);
          reject(error);
        }
      });
    });

    req.on('error', (error) => {
      console.error('❌ Request error:', error.message);
      reject(error);
    });

    req.end();
  });
}

// Main execution
async function main() {
  console.log('🚀 Setting up MongoDB Atlas database user...\n');
  
  if (!PUBLIC_KEY || !PRIVATE_KEY) {
    console.error('❌ MongoDB Atlas API keys not found in environment variables');
    console.error('Make sure MONGODB_ATLAS_PUBLIC_KEY and MONGODB_ATLAS_PRIVATE_KEY are set in .env');
    process.exit(1);
  }

  try {
    // First, verify we can access the project
    console.log('🔍 Verifying project access...');
    await getProjectInfo();
    
    console.log('\n👤 Creating database user...');
    await createDatabaseUser();
    
    console.log('\n✅ Setup complete! You can now update your .env file with the connection string above.');
    
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
    
    console.log('\n💡 Manual Setup Instructions:');
    console.log('1. Go to https://cloud.mongodb.com');
    console.log('2. Select your "***REMOVED***" project');
    console.log('3. Go to "Database Access" in the left sidebar');
    console.log('4. Click "Add New Database User"');
    console.log('5. Create a user with these details:');
    console.log(`   - Username: ${DB_USER.username}`);
    console.log(`   - Password: ${DB_USER.password}`);
    console.log('   - Database User Privileges: Read and write to any database');
    console.log('6. Click "Add User"');
    console.log('\n📋 Then use this connection string:');
    console.log(`***REMOVED***${DB_USER.username}:${DB_USER.password}@***REMOVED***.ph5cazq.mongodb.net/qahwat_al_emarat?retryWrites=true&w=majority&appName=***REMOVED***`);
    
    process.exit(1);
  }
}

main();

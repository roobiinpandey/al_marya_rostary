#!/usr/bin/env node

/**
 * MongoDB Atlas Connection Test
 * 
 * This script tests the connection to MongoDB Atlas using the configured connection string.
 */

require('dotenv').config();
const mongoose = require('mongoose');

async function testConnection() {
  try {
    console.log('🚀 Testing MongoDB Atlas connection...\n');
    
    const mongoURI = process.env.MONGODB_URI;
    console.log('📋 Connection URI:', mongoURI.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@'));
    
    // Connect to MongoDB
    await mongoose.connect(mongoURI);
    
    console.log('✅ Connected to MongoDB Atlas successfully!');
    
    // Test basic operations
    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    
    console.log('📊 Database:', db.databaseName);
    console.log('📁 Collections:', collections.length > 0 ? collections.map(c => c.name) : 'None yet');
    
    // Test a simple query
    const admin = db.admin();
    const serverStatus = await admin.serverStatus();
    console.log('🌐 MongoDB Version:', serverStatus.version);
    console.log('🏠 Host:', serverStatus.host);
    
    // Close connection
    await mongoose.connection.close();
    console.log('\n✅ Connection test completed successfully!');
    
    console.log('\n💡 Next steps:');
    console.log('1. Your MongoDB Atlas is ready to use');
    console.log('2. Start your backend server with: node server.js');
    console.log('3. Your app will now use MongoDB Atlas for data storage');
    
  } catch (error) {
    console.error('\n❌ Connection failed:', error.message);
    
    if (error.message.includes('bad auth')) {
      console.log('\n💡 Authentication Error - Please check:');
      console.log('1. Database user exists in MongoDB Atlas');
      console.log('2. Username and password are correct');
      console.log('3. User has proper permissions (readWrite)');
      console.log('\n📋 Manual Setup Steps:');
      console.log('1. Go to https://cloud.mongodb.com');
      console.log('2. Select your project');
      console.log('3. Go to "Database Access"');
      console.log('4. Add user: qahwat_user / qahwat_secure_2025');
      console.log('5. Role: Read and write to any database');
    } else if (error.message.includes('IP')) {
      console.log('\n💡 IP Access Error - Please check:');
      console.log('1. Go to MongoDB Atlas → Network Access');
      console.log('2. Add your IP address or 0.0.0.0/0 for any IP');
    } else {
      console.log('\n💡 General connection error. Please verify:');
      console.log('1. Internet connection');
      console.log('2. MongoDB Atlas cluster is running');
      console.log('3. Connection string format is correct');
    }
    
    process.exit(1);
  }
}

testConnection();
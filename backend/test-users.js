const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ MongoDB Connected');
  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error.message);
    process.exit(1);
  }
};

const testUsers = async () => {
  await connectDB();
  
  const User = require('./models/User');
  
  try {
    console.log('\n📊 Testing User Database...');
    
    // Get total user count
    const totalUsers = await User.countDocuments();
    console.log(`📈 Total users in database: ${totalUsers}`);
    
    // Get all users (without password)
    const users = await User.find({}).select('-password').limit(10);
    console.log(`\n👥 Users found:`);
    
    if (users.length === 0) {
      console.log('❌ No users found in database');
      
      // Let's create a test user to verify registration works
      console.log('\n🔧 Creating test user...');
      const testUser = await User.create({
        name: 'Test User Registration',
        email: 'testregistration@example.com',
        password: 'password123',
        phone: '+971501234567',
        roles: ['customer'],
        isEmailVerified: true,
        isActive: true
      });
      
      console.log('✅ Test user created:', {
        id: testUser._id,
        name: testUser.name,
        email: testUser.email,
        roles: testUser.roles
      });
    } else {
      users.forEach((user, index) => {
        console.log(`${index + 1}. ${user.name} (${user.email}) - Roles: ${user.roles.join(', ')} - Active: ${user.isActive}`);
      });
    }
    
    // Test API endpoint locally
    console.log('\n🔗 Testing API endpoint...');
    const http = require('http');
    
    const req = http.request({
      hostname: 'localhost',
      port: 5001,
      path: '/api/admin/users',
      method: 'GET'
    }, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        console.log('📡 API Response Status:', res.statusCode);
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          console.log('✅ API working! Users returned:', response.pagination?.total || response.data?.length || 'Unknown');
        } else {
          console.log('❌ API Error:', data);
        }
        process.exit(0);
      });
    });
    
    req.on('error', (error) => {
      console.log('❌ API Request failed:', error.message);
      process.exit(0);
    });
    
    req.end();
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
};

testUsers();

const mongoose = require('mongoose');
const bcryptjs = require('bcryptjs');
const User = require('./models/User');
require('dotenv').config();

async function createTestUser() {
  try {
    // Connect to MongoDB
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      throw new Error('MONGODB_URI environment variable is not set');
    }

    await mongoose.connect(mongoURI);
    console.log('✅ Connected to MongoDB');

    // Hash password
    const hashedPassword = await bcryptjs.hash('password123', 12);

    // Create test users
    const testUsers = [
      {
        name: 'Ahmed Al-Rashid',
        email: 'ahmed@qahwat.com',
        password: hashedPassword,
        phone: '+971501234567',
        roles: ['customer'],
        isActive: true,
        preferences: {
          language: 'ar',
          notifications: {
            email: true,
            push: true,
            orderUpdates: true,
            promotions: true
          }
        },
        addresses: [{
          type: 'home',
          street: '123 Sheikh Zayed Road',
          city: 'Dubai',
          state: 'Dubai',
          zipCode: '12345',
          country: 'UAE',
          isDefault: true
        }]
      },
      {
        name: 'Sarah Johnson',
        email: 'sarah@example.com',
        password: hashedPassword,
        phone: '+971509876543',
        roles: ['customer'],
        isActive: true,
        preferences: {
          language: 'en',
          notifications: {
            email: true,
            push: true,
            orderUpdates: true,
            promotions: false
          }
        },
        addresses: [{
          type: 'work',
          street: '456 Marina Walk',
          city: 'Dubai',
          state: 'Dubai',
          zipCode: '54321',
          country: 'UAE',
          isDefault: true
        }]
      },
      {
        name: 'Admin User',
        email: 'admin@qahwat.com',
        password: hashedPassword,
        phone: '+971502345678',
        roles: ['admin'],
        isActive: true,
        preferences: {
          language: 'en',
          notifications: {
            email: true,
            push: true,
            orderUpdates: true,
            promotions: true
          }
        }
      }
    ];

    // Clear existing users and insert new ones
    await User.deleteMany({});
    const insertedUsers = await User.insertMany(testUsers);
    
    console.log(`✅ Created ${insertedUsers.length} test users`);
    console.log('👥 Test Users:');
    insertedUsers.forEach(user => {
      console.log(`   - ${user.name} (${user.email}) - Roles: ${user.roles.join(', ')}`);
    });

  } catch (error) {
    console.error('❌ Error creating test users:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

createTestUser();

const mongoose = require('mongoose');
const Category = require('./models/Category');
const Coffee = require('./models/Coffee');
require('dotenv').config();

const sampleCategories = [
  {
    name: 'Hot Coffee',
    description: 'Traditional hot coffee beverages',
    color: '#8B4513',
    displayOrder: 1
  },
  {
    name: 'Cold Coffee',
    description: 'Refreshing cold coffee drinks',
    color: '#4682B4',
    displayOrder: 2
  },
  {
    name: 'Espresso',
    description: 'Strong espresso-based drinks',
    color: '#2F1B14',
    displayOrder: 3
  },
  {
    name: 'Latte',
    description: 'Creamy latte variations',
    color: '#D2B48C',
    displayOrder: 4
  },
  {
    name: 'Specialty',
    description: 'Unique and seasonal coffee blends',
    color: '#CD853F',
    displayOrder: 5
  }
];

const sampleCoffees = [
  {
    name: 'Arabian Mocha',
    description: 'Rich and bold coffee with chocolate undertones, sourced from the finest Arabian beans.',
    price: 15.99,
    image: '/uploads/coffee-sample-1.jpg',
    origin: 'Yemen',
    roastLevel: 'Medium-Dark',
    stock: 50,
    categories: ['Hot Coffee', 'Specialty'],
    isActive: true
  },
  {
    name: 'Iced Caramel Latte',
    description: 'Smooth espresso blended with caramel syrup and chilled milk over ice.',
    price: 12.99,
    image: '/uploads/coffee-sample-2.jpg',
    origin: 'Colombia',
    roastLevel: 'Medium',
    stock: 75,
    categories: ['Cold Coffee', 'Latte'],
    isActive: true
  },
  {
    name: 'Double Espresso',
    description: 'Two shots of rich, concentrated espresso for the true coffee enthusiast.',
    price: 8.99,
    image: '/uploads/coffee-sample-3.jpg',
    origin: 'Italy',
    roastLevel: 'Dark',
    stock: 100,
    categories: ['Espresso', 'Hot Coffee'],
    isActive: true
  },
  {
    name: 'Vanilla Bean Latte',
    description: 'Creamy latte infused with real vanilla beans and steamed milk.',
    price: 13.99,
    image: '/uploads/coffee-sample-4.jpg',
    origin: 'Ethiopia',
    roastLevel: 'Medium',
    stock: 60,
    categories: ['Latte', 'Hot Coffee'],
    isActive: true
  },
  {
    name: 'Cold Brew Coffee',
    description: 'Smooth, low-acid coffee brewed cold for 12 hours for maximum flavor.',
    price: 11.99,
    image: '/uploads/coffee-sample-5.jpg',
    origin: 'Brazil',
    roastLevel: 'Medium',
    stock: 80,
    categories: ['Cold Coffee'],
    isActive: true
  }
];

async function seedDatabase() {
  try {
    // Connect to MongoDB
    const mongoURI = process.env.MONGODB_URI;
    if (!mongoURI) {
      throw new Error('MONGODB_URI environment variable is not set');
    }

    await mongoose.connect(mongoURI);
    console.log('✅ Connected to MongoDB');

    // Clear existing data
    await Category.deleteMany({});
    await Coffee.deleteMany({});
    console.log('🧹 Cleared existing data');

    // Insert categories
    const insertedCategories = await Category.insertMany(sampleCategories);
    console.log(`✅ Inserted ${insertedCategories.length} categories`);

    // Insert coffees
    const insertedCoffees = await Coffee.insertMany(sampleCoffees);
    console.log(`✅ Inserted ${insertedCoffees.length} coffees`);

    console.log('🎉 Database seeded successfully!');
    console.log('\n📊 Sample Data Summary:');
    console.log(`   Categories: ${insertedCategories.length}`);
    console.log(`   Coffees: ${insertedCoffees.length}`);

  } catch (error) {
    console.error('❌ Error seeding database:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

// Run the seed function
seedDatabase();

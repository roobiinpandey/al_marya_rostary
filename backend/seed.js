const mongoose = require('mongoose');
const Category = require('./models/Category');
const Coffee = require('./models/Coffee');
require('dotenv').config();

const sampleCategories = [
  {
    name: {
      en: 'Hot Coffee',
      ar: 'القهوة الساخنة'
    },
    description: {
      en: 'Traditional hot coffee beverages',
      ar: 'مشروبات القهوة الساخنة التقليدية'
    },
    color: '#8B4513',
    displayOrder: 1
  },
  {
    name: {
      en: 'Cold Coffee',
      ar: 'القهوة الباردة'
    },
    description: {
      en: 'Refreshing cold coffee drinks',
      ar: 'مشروبات القهوة الباردة المنعشة'
    },
    color: '#4682B4',
    displayOrder: 2
  },
  {
    name: {
      en: 'Espresso',
      ar: 'الإسبريسو'
    },
    description: {
      en: 'Strong espresso-based drinks',
      ar: 'مشروبات الإسبريسو القوية'
    },
    color: '#2F1B14',
    displayOrder: 3
  },
  {
    name: {
      en: 'Latte',
      ar: 'اللاتيه'
    },
    description: {
      en: 'Creamy latte variations',
      ar: 'أنواع اللاتيه الكريمية'
    },
    color: '#D2B48C',
    displayOrder: 4
  },
  {
    name: {
      en: 'Specialty',
      ar: 'التخصصية'
    },
    description: {
      en: 'Unique and seasonal coffee blends',
      ar: 'خلطات القهوة الفريدة والموسمية'
    },
    color: '#CD853F',
    displayOrder: 5
  }
];

const sampleCoffees = [
  {
    name: {
      en: 'Arabian Mocha',
      ar: 'الموكا العربية'
    },
    description: {
      en: 'Rich and bold coffee with chocolate undertones, sourced from the finest Arabian beans.',
      ar: 'قهوة غنية وجريئة مع نكهات الشوكولاتة، مصدرها أفضل حبوب القهوة العربية.'
    },
    price: 15.99,
    image: '/uploads/coffee-sample-1.jpg',
    origin: 'Yemen',
    roastLevel: 'Medium-Dark',
    stock: 50,
    categories: ['Hot Coffee', 'Specialty'],
    isActive: true
  },
  {
    name: {
      en: 'Iced Caramel Latte',
      ar: 'لاتيه الكراميل المثلج'
    },
    description: {
      en: 'Smooth espresso blended with caramel syrup and chilled milk over ice.',
      ar: 'إسبريسو ناعم ممزوج مع شراب الكراميل والحليب المثلج على الثلج.'
    },
    price: 12.99,
    image: '/uploads/coffee-sample-2.jpg',
    origin: 'Colombia',
    roastLevel: 'Medium',
    stock: 75,
    categories: ['Cold Coffee', 'Latte'],
    isActive: true
  },
  {
    name: {
      en: 'Double Espresso',
      ar: 'إسبريسو مضاعف'
    },
    description: {
      en: 'Two shots of rich, concentrated espresso for the true coffee enthusiast.',
      ar: 'جرعتان من الإسبريسو الغني والمركز لعشاق القهوة الحقيقيين.'
    },
    price: 8.99,
    image: '/uploads/coffee-sample-3.jpg',
    origin: 'Italy',
    roastLevel: 'Dark',
    stock: 100,
    categories: ['Espresso', 'Hot Coffee'],
    isActive: true
  },
  {
    name: {
      en: 'Vanilla Bean Latte',
      ar: 'لاتيه حبوب الفانيليا'
    },
    description: {
      en: 'Creamy latte infused with real vanilla beans and steamed milk.',
      ar: 'لاتيه كريمي منقوع بحبوب الفانيليا الحقيقية والحليب المبخر.'
    },
    price: 13.99,
    image: '/uploads/coffee-sample-4.jpg',
    origin: 'Ethiopia',
    roastLevel: 'Medium',
    stock: 60,
    categories: ['Latte', 'Hot Coffee'],
    isActive: true
  },
  {
    name: {
      en: 'Cold Brew Coffee',
      ar: 'قهوة باردة التحضير'
    },
    description: {
      en: 'Smooth, low-acid coffee brewed cold for 12 hours for maximum flavor.',
      ar: 'قهوة ناعمة قليلة الحموضة تُحضر باردة لمدة 12 ساعة للحصول على أقصى نكهة.'
    },
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

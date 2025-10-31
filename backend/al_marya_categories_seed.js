const mongoose = require('mongoose');
const Category = require('./models/Category');
const Coffee = require('./models/Coffee');
require('dotenv').config();

/**
 * Al Marya Rostery Categories Setup
 * Categories based on bean origins, roast levels, and premium selection
 */

const alMaryaCategories = [
  // ===== ORIGIN-BASED CATEGORIES =====
  {
    name: {
      en: 'Asia',
      ar: 'آسيا'
    },
    description: {
      en: 'Premium coffee beans from Asian coffee-growing regions including Indonesia, Vietnam, India, and Papua New Guinea',
      ar: 'حبوب قهوة فاخرة من مناطق زراعة القهوة الآسيوية بما في ذلك إندونيسيا وفيتنام والهند وبابوا غينيا الجديدة'
    },
    color: '#8B4513', // Saddle Brown
    icon: 'public',
    displayOrder: 1,
    isActive: true,
    seo: {
      metaTitle: 'Asian Coffee Beans - Al Marya Rostery',
      metaDescription: 'Discover premium coffee beans from Asia at Al Marya Rostery',
      slug: 'asia-coffee-beans'
    }
  },
  {
    name: {
      en: 'Africa',
      ar: 'أفريقيا'
    },
    description: {
      en: 'Exceptional coffee beans from the birthplace of coffee - Ethiopia, Kenya, Tanzania, and other African highlands',
      ar: 'حبوب قهوة استثنائية من موطن القهوة - إثيوبيا وكينيا وتنزانيا والمرتفعات الأفريقية الأخرى'
    },
    color: '#CD853F', // Peru
    icon: 'terrain',
    displayOrder: 2,
    isActive: true,
    seo: {
      metaTitle: 'African Coffee Beans - Al Marya Rostery',
      metaDescription: 'Authentic African coffee beans from the birthplace of coffee',
      slug: 'africa-coffee-beans'
    }
  },
  {
    name: {
      en: 'Latin America',
      ar: 'أمريكا اللاتينية'
    },
    description: {
      en: 'Rich and diverse coffee beans from Central and South America including Colombia, Brazil, Guatemala, and Costa Rica',
      ar: 'حبوب قهوة غنية ومتنوعة من أمريكا الوسطى والجنوبية بما في ذلك كولومبيا والبرازيل وغواتيمالا وكوستاريكا'
    },
    color: '#A0522D', // Sienna
    icon: 'language',
    displayOrder: 3,
    isActive: true,
    seo: {
      metaTitle: 'Latin American Coffee Beans - Al Marya Rostery',
      metaDescription: 'Premium Latin American coffee beans with rich and diverse flavors',
      slug: 'latin-america-coffee-beans'
    }
  },

  // ===== ROAST LEVEL CATEGORIES =====
  {
    name: {
      en: 'Dark Roast',
      ar: 'التحميص الداكن'
    },
    description: {
      en: 'Bold, intense coffee with rich, smoky flavors and low acidity. Perfect for espresso and strong coffee lovers',
      ar: 'قهوة جريئة وقوية مع نكهات غنية ودخانية وحموضة منخفضة. مثالية لعشاق الإسبريسو والقهوة القوية'
    },
    color: '#2F1B14', // Very Dark Brown
    icon: 'nights_stay',
    displayOrder: 5,
    isActive: true,
    seo: {
      metaTitle: 'Dark Roast Coffee - Al Marya Rostery',
      metaDescription: 'Bold and intense dark roast coffee beans with rich, smoky flavors',
      slug: 'dark-roast-coffee'
    }
  },
  {
    name: {
      en: 'Medium Dark Roast',
      ar: 'التحميص المتوسط الداكن'
    },
    description: {
      en: 'Balanced coffee with slightly bittersweet aftertaste, fuller body, and reduced acidity',
      ar: 'قهوة متوازنة مع طعم مر حلو قليلاً وجسم أكمل وحموضة مخفضة'
    },
    color: '#5D4037', // Brown 700
    icon: 'wb_twilight',
    displayOrder: 6,
    isActive: true,
    seo: {
      metaTitle: 'Medium Dark Roast Coffee - Al Marya Rostery',
      metaDescription: 'Perfectly balanced medium dark roast coffee with fuller body',
      slug: 'medium-dark-roast-coffee'
    }
  },
  {
    name: {
      en: 'Medium Roast',
      ar: 'التحميص المتوسط'
    },
    description: {
      en: 'Well-balanced coffee with moderate acidity and body, preserving original flavors while developing roasted characteristics',
      ar: 'قهوة متوازنة جيداً مع حموضة وجسم معتدل، تحافظ على النكهات الأصلية مع تطوير خصائص التحميص'
    },
    color: '#8D6E63', // Brown 400
    icon: 'wb_sunny',
    displayOrder: 7,
    isActive: true,
    seo: {
      metaTitle: 'Medium Roast Coffee - Al Marya Rostery',
      metaDescription: 'Well-balanced medium roast coffee preserving original bean flavors',
      slug: 'medium-roast-coffee'
    }
  },

  // ===== COMPLEMENTARY CATEGORIES =====
  {
    name: {
      en: 'Single Origin',
      ar: 'منشأ واحد'
    },
    description: {
      en: 'Coffee beans from a single farm, region, or country, showcasing unique terroir and flavor profiles',
      ar: 'حبوب قهوة من مزرعة أو منطقة أو بلد واحد، تعرض تربة ونكهات فريدة'
    },
    color: '#795548', // Brown 500
    icon: 'place',
    displayOrder: 8,
    isActive: true,
    seo: {
      metaTitle: 'Single Origin Coffee - Al Marya Rostery',
      metaDescription: 'Single origin coffee beans showcasing unique terroir and flavor profiles',
      slug: 'single-origin-coffee'
    }
  },
  {
    name: {
      en: 'Blends',
      ar: 'الخلطات'
    },
    description: {
      en: 'Expertly crafted coffee blends combining beans from different origins for complex, balanced flavors',
      ar: 'خلطات قهوة مصممة بخبرة تجمع بين حبوب من أصول مختلفة لنكهات معقدة ومتوازنة'
    },
    color: '#6D4C41', // Brown 600
    icon: 'grain',
    displayOrder: 9,
    isActive: true,
    seo: {
      metaTitle: 'Coffee Blends - Al Marya Rostery',
      metaDescription: 'Expertly crafted coffee blends for complex, balanced flavors',
      slug: 'coffee-blends'
    }
  },
  {
    name: {
      en: 'Organic',
      ar: 'عضوي'
    },
    description: {
      en: 'Certified organic coffee beans grown without synthetic pesticides, herbicides, or fertilizers',
      ar: 'حبوب قهوة عضوية معتمدة تُزرع بدون مبيدات حشرية أو عشبية أو أسمدة صناعية'
    },
    color: '#689F38', // Light Green 700
    icon: 'eco',
    displayOrder: 10,
    isActive: true,
    seo: {
      metaTitle: 'Organic Coffee Beans - Al Marya Rostery',
      metaDescription: 'Certified organic coffee beans grown sustainably without chemicals',
      slug: 'organic-coffee-beans'
    }
  }
];

/**
 * Sample coffee products for the new categories
 */
const alMaryaCoffees = [
  // ASIA ORIGIN COFFEES
  {
    name: {
      en: 'Java Estate Arabica',
      ar: 'أرابيكا جاوة إستيت'
    },
    description: {
      en: 'Full-bodied Indonesian coffee with earthy undertones and low acidity. Grown in the volcanic soils of Java.',
      ar: 'قهوة إندونيسية كاملة الجسم مع نكهات ترابية وحموضة منخفضة. تُزرع في التربة البركانية لجاوة.'
    },
    price: 48.99,
    image: '/uploads/asia-java-arabica.jpg',
    origin: 'Indonesia',
    roastLevel: 'Medium-Dark',
    stock: 85,
    categories: ['Asia', 'Medium Dark Roast', 'Single Origin'],
    variants: [
      { size: '250gm', weight: 250, price: 48.99, stock: 30 },
      { size: '500gm', weight: 500, price: 92.99, stock: 30 },
      { size: '1kg', weight: 1000, price: 175.99, stock: 25 }
    ],
    isActive: true,
    isFeatured: true
  },
  {
    name: {
      en: 'Malabar Monsoon Premium',
      ar: 'مالابار مونسون بريميوم'
    },
    description: {
      en: 'Unique Indian coffee exposed to monsoon winds, creating a distinctive mellow flavor with reduced acidity.',
      ar: 'قهوة هندية فريدة معرضة لرياح الرياح الموسمية، تخلق نكهة ناعمة مميزة مع حموضة مخفضة.'
    },
    price: 52.99,
    image: '/uploads/asia-malabar-monsoon.jpg',
    origin: 'India',
    roastLevel: 'Medium',
    stock: 60,
    categories: ['Asia', 'Medium Roast', 'Single Origin'],
    variants: [
      { size: '250gm', weight: 250, price: 52.99, stock: 20 },
      { size: '500gm', weight: 500, price: 99.99, stock: 25 },
      { size: '1kg', weight: 1000, price: 189.99, stock: 15 }
    ],
    isActive: true,
    isFeatured: true,
    isPremium: true
  },

  // AFRICA ORIGIN COFFEES
  {
    name: {
      en: 'Ethiopian Yirgacheffe',
      ar: 'يرجاتشيف الإثيوبية'
    },
    description: {
      en: 'Bright, wine-like Ethiopian coffee with floral and citrus notes. From the birthplace of coffee.',
      ar: 'قهوة إثيوبية مشرقة تشبه النبيذ مع نكهات زهرية وحمضيات. من موطن القهوة.'
    },
    price: 45.99,
    image: '/uploads/africa-ethiopian-yirgacheffe.jpg',
    origin: 'Ethiopia',
    roastLevel: 'Medium',
    stock: 95,
    categories: ['Africa', 'Medium Roast', 'Single Origin'],
    variants: [
      { size: '250gm', weight: 250, price: 45.99, stock: 35 },
      { size: '500gm', weight: 500, price: 87.99, stock: 35 },
      { size: '1kg', weight: 1000, price: 165.99, stock: 25 }
    ],
    isActive: true,
    isFeatured: true
  },
  {
    name: {
      en: 'Kenyan AA Premium',
      ar: 'كينيا AA بريميوم'
    },
    description: {
      en: 'Full-bodied Kenyan coffee with bright acidity, black currant flavors, and wine-like characteristics.',
      ar: 'قهوة كينية كاملة الجسم مع حموضة مشرقة ونكهات الكشمش الأسود وخصائص تشبه النبيذ.'
    },
    price: 49.99,
    image: '/uploads/africa-kenyan-aa.jpg',
    origin: 'Kenya',
    roastLevel: 'Medium-Dark',
    stock: 70,
    categories: ['Africa', 'Medium Dark Roast', 'Single Origin'],
    variants: [
      { size: '250gm', weight: 250, price: 49.99, stock: 25 },
      { size: '500gm', weight: 500, price: 94.99, stock: 25 },
      { size: '1kg', weight: 1000, price: 179.99, stock: 20 }
    ],
    isActive: true,
    isFeatured: true,
    isPremium: true
  },

  // LATIN AMERICA ORIGIN COFFEES
  {
    name: {
      en: 'Colombian Supremo',
      ar: 'كولومبيا سوبريمو'
    },
    description: {
      en: 'Classic Colombian coffee with balanced acidity, medium body, and notes of chocolate and caramel.',
      ar: 'قهوة كولومبية كلاسيكية مع حموضة متوازنة وجسم متوسط ونكهات الشوكولاتة والكراميل.'
    },
    price: 42.99,
    image: '/uploads/latin-america-colombian-supremo.jpg',
    origin: 'Colombia',
    roastLevel: 'Medium',
    stock: 110,
    categories: ['Latin America', 'Medium Roast', 'Single Origin'],
    variants: [
      { size: '250gm', weight: 250, price: 42.99, stock: 40 },
      { size: '500gm', weight: 500, price: 81.99, stock: 40 },
      { size: '1kg', weight: 1000, price: 154.99, stock: 30 }
    ],
    isActive: true,
    isFeatured: true
  },
  {
    name: {
      en: 'Guatemala Antigua Premium',
      ar: 'غواتيمالا أنتيغوا بريميوم'
    },
    description: {
      en: 'Complex Guatemalan coffee with smoky, spicy notes and full body from volcanic soil highlands.',
      ar: 'قهوة غواتيمالية معقدة مع نكهات دخانية وحارة وجسم كامل من مرتفعات التربة البركانية.'
    },
    price: 47.99,
    image: '/uploads/latin-america-guatemala-antigua.jpg',
    origin: 'Guatemala',
    roastLevel: 'Dark',
    stock: 80,
    categories: ['Latin America', 'Dark Roast', 'Single Origin'],
    variants: [
      { size: '250gm', weight: 250, price: 47.99, stock: 30 },
      { size: '500gm', weight: 500, price: 91.99, stock: 30 },
      { size: '1kg', weight: 1000, price: 173.99, stock: 20 }
    ],
    isActive: true,
    isFeatured: true,
    isPremium: true
  },

  // PREMIUM BLENDS
  {
    name: {
      en: 'Al Marya Reserve Blend',
      ar: 'خلطة المرية الاحتياطية'
    },
    description: {
      en: 'Our signature premium blend combining the finest beans from Asia, Africa, and Latin America.',
      ar: 'خلطتنا المميزة الفاخرة التي تجمع أفضل الحبوب من آسيا وأفريقيا وأمريكا اللاتينية.'
    },
    price: 55.99,
    image: '/uploads/premium-al-marya-reserve.jpg',
    origin: 'Multi-Origin',
    roastLevel: 'Medium-Dark',
    stock: 50,
    categories: ['Medium Dark Roast', 'Blends'],
    variants: [
      { size: '250gm', weight: 250, price: 55.99, stock: 20 },
      { size: '500gm', weight: 500, price: 106.99, stock: 20 },
      { size: '1kg', weight: 1000, price: 199.99, stock: 10 }
    ],
    isActive: true,
    isFeatured: true,
    isPremium: true
  },
  {
    name: {
      en: 'Heritage Organic Blend',
      ar: 'خلطة التراث العضوية'
    },
    description: {
      en: 'Certified organic blend with traditional Middle Eastern coffee characteristics and modern roasting techniques.',
      ar: 'خلطة عضوية معتمدة مع خصائص القهوة الشرق أوسطية التقليدية وتقنيات التحميص الحديثة.'
    },
    price: 51.99,
    image: '/uploads/premium-heritage-organic.jpg',
    origin: 'Multi-Origin',
    roastLevel: 'Dark',
    stock: 65,
    categories: ['Organic', 'Dark Roast', 'Blends'],
    variants: [
      { size: '250gm', weight: 250, price: 51.99, stock: 25 },
      { size: '500gm', weight: 500, price: 98.99, stock: 25 },
      { size: '1kg', weight: 1000, price: 185.99, stock: 15 }
    ],
    isActive: true,
    isFeatured: true,
    isPremium: true
  }
];

async function seedAlMaryaCategories() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/al_marya_rostery');
    console.log('✅ Connected to MongoDB');

    // Clear existing categories and coffee data
    console.log('🗑️ Clearing existing categories...');
    await Category.deleteMany({});
    
    console.log('🗑️ Clearing existing coffee products...');
    await Coffee.deleteMany({});

    // Insert new categories
    console.log('📦 Inserting Al Marya Rostery categories...');
    const insertedCategories = await Category.insertMany(alMaryaCategories);
    console.log(`✅ Created ${insertedCategories.length} categories`);

    // Insert sample coffee products
    console.log('☕ Inserting sample coffee products...');
    const insertedCoffees = await Coffee.insertMany(alMaryaCoffees);
    console.log(`✅ Created ${insertedCoffees.length} coffee products`);

    // Display created categories
    console.log('\n🏷️ Created Categories:');
    insertedCategories.forEach((category, index) => {
      console.log(`${index + 1}. ${category.name.en} (${category.name.ar})`);
      console.log(`   - Order: ${category.displayOrder}`);
      console.log(`   - Color: ${category.color}`);
      console.log(`   - Slug: ${category.seo?.slug || 'auto-generated'}`);
      console.log('');
    });

    // Display created coffee products
    console.log('☕ Created Coffee Products:');
    insertedCoffees.forEach((coffee, index) => {
      console.log(`${index + 1}. ${coffee.name.en} (${coffee.name.ar})`);
      console.log(`   - Origin: ${coffee.origin}`);
      console.log(`   - Roast: ${coffee.roastLevel}`);
      console.log(`   - Price: $${coffee.price}`);
      console.log(`   - Categories: ${coffee.categories.join(', ')}`);
      console.log('');
    });

    console.log('🎉 Al Marya Rostery categories and products setup completed successfully!');

  } catch (error) {
    console.error('❌ Error setting up categories:', error);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Export for use in other files
module.exports = { alMaryaCategories, alMaryaCoffees, seedAlMaryaCategories };

// Run if called directly
if (require.main === module) {
  seedAlMaryaCategories();
}

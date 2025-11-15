const mongoose = require('mongoose');
const Accessory = require('./models/Accessory');
const GiftSet = require('./models/GiftSet');
const ContactInquiry = require('./models/ContactInquiry');
require('dotenv').config();

// Connect to MongoDB
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Sample Accessories Data
const sampleAccessories = [
  {
    name: {
      en: "Professional Coffee Grinder",
      ar: "طاحونة قهوة احترافية"
    },
    description: {
      en: "High-quality burr grinder for consistent coffee grounds",
      ar: "طاحونة حبيبات عالية الجودة للحصول على طحن قهوة متجانس"
    },
    type: "grinder",
    category: "Electric Grinders",
    brand: "BrewMaster",
    price: {
      regular: 299,
      currency: "AED"
    },
    specifications: {
      material: ["Stainless Steel", "Ceramic Burr"],
      features: [
        {
          name: { en: "15 Grind Settings", ar: "15 إعداد طحن" },
          description: { en: "From espresso to French press", ar: "من الإسبريسو إلى الفرنش بريس" }
        }
      ]
    },
    stock: {
      quantity: 25,
      lowStockThreshold: 5,
      isInStock: true
    },
    isActive: true,
    isFeatured: true
  },
  {
    name: {
      en: "Ceramic Coffee Mug Set",
      ar: "طقم أكواب قهوة سيراميك"
    },
    description: {
      en: "Set of 4 elegant ceramic mugs perfect for coffee lovers",
      ar: "طقم من 4 أكواب سيراميك أنيقة مثالية لعشاق القهوة"
    },
    type: "mug",
    category: "Drinkware",
    brand: "CoffeeCraft",
    price: {
      regular: 89,
      sale: 69,
      currency: "AED"
    },
    specifications: {
      material: ["Ceramic"],
      capacity: {
        value: 350,
        unit: "ml"
      }
    },
    stock: {
      quantity: 50,
      lowStockThreshold: 10,
      isInStock: true
    },
    isActive: true,
    isFeatured: false
  },
  {
    name: {
      en: "V60 Paper Filters (100 pack)",
      ar: "فلاتر ورقية V60 (عبوة 100 قطعة)"
    },
    description: {
      en: "Premium paper filters for V60 pour-over brewing",
      ar: "فلاتر ورقية فاخرة لتحضير القهوة بطريقة V60"
    },
    type: "filter",
    category: "Brewing Accessories",
    brand: "Hario",
    price: {
      regular: 25,
      currency: "AED"
    },
    specifications: {
      material: ["Paper"]
    },
    stock: {
      quantity: 100,
      lowStockThreshold: 20,
      isInStock: true
    },
    isActive: true,
    isFeatured: false
  }
];

// Sample Gift Sets Data
const sampleGiftSets = [
  {
    name: {
      en: "Coffee Lover's Starter Kit",
      ar: "طقم المبتدئين لعشاق القهوة"
    },
    description: {
      en: "Perfect gift set for someone starting their coffee journey",
      ar: "طقم هدايا مثالي لمن يبدأ رحلته مع القهوة"
    },
    occasion: "birthday",
    targetAudience: "beginner",
    price: {
      regular: 199,
      currency: "AED"
    },
    contents: [
      {
        item: {
          itemType: "custom",
          customItem: {
            name: { en: "Premium Coffee Beans", ar: "حبوب قهوة فاخرة" },
            description: { en: "250g of medium roast beans", ar: "250 جرام من حبوب القهوة متوسطة التحميص" }
          }
        },
        quantity: 2,
        isHighlight: true
      },
      {
        item: {
          itemType: "custom",
          customItem: {
            name: { en: "French Press", ar: "فرنش بريس" },
            description: { en: "350ml glass French press", ar: "فرنش بريس زجاجي 350 مل" }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: "box",
      material: "Cardboard",
      color: "Brown"
    },
    availability: {
      isAvailable: true
    },
    isActive: true,
    isFeatured: true,
    isPopular: false
  },
  {
    name: {
      en: "Corporate Executive Gift Set",
      ar: "طقم هدايا تنفيذي للشركات"
    },
    description: {
      en: "Premium gift set suitable for corporate gifting",
      ar: "طقم هدايا فاخر مناسب للهدايا المؤسسية"
    },
    occasion: "corporate",
    targetAudience: "professional",
    price: {
      regular: 399,
      currency: "AED"
    },
    contents: [
      {
        item: {
          itemType: "custom",
          customItem: {
            name: { en: "Premium Coffee Selection", ar: "مجموعة قهوة فاخرة" },
            description: { en: "3 different origin coffees", ar: "3 أنواع قهوة من أصول مختلفة" }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: "custom",
          customItem: {
            name: { en: "Stainless Steel Travel Mug", ar: "كوب سفر من الستانلس ستيل" },
            description: { en: "Insulated 500ml travel mug", ar: "كوب سفر معزول 500 مل" }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: "box",
      material: "Wood",
      color: "Dark Brown"
    },
    availability: {
      isAvailable: true
    },
    isActive: true,
    isFeatured: true,
    isPopular: true
  }
];

// Sample Contact Inquiries Data
const sampleContactInquiries = [
  {
    contactInfo: {
      name: "Ahmed Al-Mahmoud",
      email: "ahmed.mahmoud@example.com",
      phone: "+971501234567",
      company: "Emirates Coffee Trading"
    },
    inquiry: {
      type: "bulk-order",
      subject: "Bulk Order Inquiry for 500kg Coffee Beans",
      message: "We are interested in placing a bulk order for 500kg of your premium Arabica coffee beans. Could you please provide pricing and delivery information?",
      priority: "high",
      language: "en"
    },
    status: {
      current: "new"
    },
    metadata: {
      source: "website"
    }
  },
  {
    contactInfo: {
      name: "Sarah Johnson",
      email: "sarah.j@coffeelovers.com",
      company: "Coffee Lovers Café"
    },
    inquiry: {
      type: "partnership",
      subject: "Partnership Opportunity",
      message: "Hello, we run a chain of coffee shops in Dubai and would like to explore a partnership opportunity with Al Marya Rostery. We are interested in serving your premium coffee in our locations.",
      priority: "medium",
      language: "en"
    },
    status: {
      current: "new"
    },
    metadata: {
      source: "website"
    }
  },
  {
    contactInfo: {
      name: "محمد العلي",
      email: "mohammed.ali@example.ae",
      phone: "+971507654321"
    },
    inquiry: {
      type: "product-inquiry",
      subject: "استفسار عن طرق التحميص",
      message: "أريد معرفة المزيد عن طرق التحميص المختلفة المتوفرة لديكم وأيها الأنسب للقهوة العربية التقليدية.",
      priority: "low",
      language: "ar"
    },
    status: {
      current: "new"
    },
    metadata: {
      source: "website"
    }
  }
];

// Function to seed data
const seedData = async () => {
  try {
    await connectDB();

    console.log('🧹 Clearing existing data...');
    await Accessory.deleteMany({});
    await GiftSet.deleteMany({});
    await ContactInquiry.deleteMany({});

    console.log('🌱 Seeding accessories...');
    await Accessory.insertMany(sampleAccessories);

    console.log('🎁 Seeding gift sets...');
    await GiftSet.insertMany(sampleGiftSets);

    console.log('📧 Seeding contact inquiries...');
    await ContactInquiry.insertMany(sampleContactInquiries);

    console.log('✅ Sample data seeded successfully!');
    console.log(`📊 Created ${sampleAccessories.length} accessories`);
    console.log(`🎁 Created ${sampleGiftSets.length} gift sets`);
    console.log(`📧 Created ${sampleContactInquiries.length} contact inquiries`);

  } catch (error) {
    console.error('❌ Error seeding data:', error);
  } finally {
    mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
};

// Run the seeding
if (require.main === module) {
  seedData();
}

module.exports = { seedData };

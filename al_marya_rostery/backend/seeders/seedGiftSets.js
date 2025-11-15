const mongoose = require('mongoose');
const GiftSet = require('../models/GiftSet');
require('dotenv').config();

// MongoDB connection
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/al_marya_rostery');
    console.log('✅ MongoDB connected successfully');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Sample Gift Sets Data
const giftSetsData = [
  // 1. Premium Coffee Lover's Collection
  {
    name: {
      en: "Premium Coffee Lover's Collection",
      ar: "مجموعة عشاق القهوة المميزة"
    },
    description: {
      en: "A curated selection of our finest single-origin coffees, perfect for the discerning coffee enthusiast. Includes premium brewing accessories and a personalized gift card.",
      ar: "تشكيلة مختارة من أجود أنواع القهوة أحادية المصدر، مثالية لعشاق القهوة المميزين. تشمل إكسسوارات تحضير فاخرة وبطاقة هدايا مخصصة."
    },
    occasion: 'general',
    targetAudience: 'enthusiast',
    price: {
      regular: 450,
      sale: 399,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Ethiopian Yirgacheffe 250g', ar: 'إثيوبيا يرجاشيف 250 جرام' },
            description: { en: 'Floral and fruity notes', ar: 'نكهات زهرية وفاكهية' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Colombian Supremo 250g', ar: 'كولومبيا سوبريمو 250 جرام' },
            description: { en: 'Rich and balanced', ar: 'غنية ومتوازنة' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Premium Coffee Grinder', ar: 'مطحنة قهوة فاخرة' },
            description: { en: 'Manual ceramic burr grinder', ar: 'مطحنة سيراميك يدوية' }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: 'box',
      material: 'Premium wooden box',
      color: 'Natural wood with gold accents',
      customization: {
        allowPersonalization: true,
        personalizationOptions: ['Gift message', 'Name engraving']
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=800',
        alt: { en: 'Premium Coffee Collection', ar: 'مجموعة القهوة المميزة' },
        isPrimary: true,
        showsContents: true
      }
    ],
    availability: {
      isAvailable: true
    },
    isActive: true,
    isFeatured: true,
    isPopular: true,
    displayOrder: 1,
    tags: ['premium', 'single-origin', 'gourmet', 'coffee-lover'],
    marketingMessages: {
      shortDescription: {
        en: 'Perfect for coffee enthusiasts',
        ar: 'مثالية لعشاق القهوة'
      },
      highlights: [
        { en: 'Two premium single-origin coffees', ar: 'قهوتان مميزتان أحادية المصدر' },
        { en: 'Professional-grade grinder included', ar: 'تشمل مطحنة احترافية' },
        { en: 'Elegant wooden gift box', ar: 'صندوق خشبي أنيق' }
      ],
      giftMessage: {
        en: 'For those who appreciate the finer things in life',
        ar: 'لمن يقدر الأشياء الفاخرة في الحياة'
      }
    }
  },

  // 2. Morning Ritual Starter Set
  {
    name: {
      en: 'Morning Ritual Starter Set',
      ar: 'طقم طقوس الصباح للمبتدئين'
    },
    description: {
      en: 'Everything needed to start your coffee journey. Perfect for beginners with easy-to-follow brewing guides and quality essentials.',
      ar: 'كل ما تحتاجه لبدء رحلتك مع القهوة. مثالي للمبتدئين مع أدلة تحضير سهلة ومستلزمات عالية الجودة.'
    },
    occasion: 'general',
    targetAudience: 'beginner',
    price: {
      regular: 250,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'House Blend Coffee 500g', ar: 'خلطة المنزل 500 جرام' },
            description: { en: 'Smooth and approachable', ar: 'ناعمة وسهلة' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'French Press', ar: 'فرنش بريس' },
            description: { en: '350ml capacity', ar: 'سعة 350 مل' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Coffee Mug', ar: 'كوب قهوة' },
            description: { en: 'Ceramic mug with logo', ar: 'كوب سيراميك مع الشعار' }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: 'box',
      material: 'Cardboard gift box',
      color: 'Brown with cream ribbon',
      customization: {
        allowPersonalization: false
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800',
        alt: { en: 'Morning Ritual Set', ar: 'طقم طقوس الصباح' },
        isPrimary: true,
        showsContents: true
      }
    ],
    availability: {
      isAvailable: true
    },
    isActive: true,
    isFeatured: false,
    isPopular: true,
    displayOrder: 2,
    tags: ['beginner', 'starter', 'morning', 'easy-brew'],
    marketingMessages: {
      shortDescription: {
        en: 'Start your coffee journey right',
        ar: 'ابدأ رحلتك مع القهوة بشكل صحيح'
      },
      highlights: [
        { en: 'Complete brewing kit', ar: 'طقم تحضير كامل' },
        { en: 'Beginner-friendly guide included', ar: 'دليل سهل للمبتدئين' },
        { en: 'Great value for money', ar: 'قيمة رائعة مقابل المال' }
      ]
    }
  },

  // 3. Corporate Thank You Collection
  {
    name: {
      en: 'Corporate Thank You Collection',
      ar: 'مجموعة شكر الشركات'
    },
    description: {
      en: 'An elegant corporate gift set featuring premium coffee selections and professional accessories. Perfect for client appreciation or employee recognition.',
      ar: 'طقم هدايا شركات أنيق يحتوي على تشكيلة قهوة فاخرة وإكسسوارات احترافية. مثالي لتقدير العملاء أو تكريم الموظفين.'
    },
    occasion: 'corporate',
    targetAudience: 'corporate',
    price: {
      regular: 350,
      sale: 315,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Premium Arabica Blend 250g', ar: 'خلطة أرابيكا فاخرة 250 جرام' },
            description: { en: 'Smooth corporate blend', ar: 'خلطة شركات ناعمة' }
          }
        },
        quantity: 2,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Insulated Travel Mug', ar: 'كوب سفر معزول' },
            description: { en: 'Stainless steel 400ml', ar: 'ستانلس ستيل 400 مل' }
          }
        },
        quantity: 1,
        isHighlight: true
      }
    ],
    packaging: {
      type: 'box',
      material: 'Premium black box',
      color: 'Matte black with silver logo',
      customization: {
        allowPersonalization: true,
        personalizationOptions: ['Company logo', 'Custom message card']
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=800',
        alt: { en: 'Corporate Gift Set', ar: 'طقم هدايا شركات' },
        isPrimary: true,
        showsContents: false
      }
    ],
    availability: {
      isAvailable: true
    },
    isActive: true,
    isFeatured: true,
    isPopular: false,
    displayOrder: 3,
    tags: ['corporate', 'business', 'professional', 'thank-you'],
    marketingMessages: {
      shortDescription: {
        en: 'Professional corporate gifting',
        ar: 'هدايا شركات احترافية'
      },
      highlights: [
        { en: 'Bulk discounts available', ar: 'خصومات للطلبات الكبيرة' },
        { en: 'Custom branding options', ar: 'خيارات وضع العلامة التجارية' },
        { en: 'Premium presentation', ar: 'تقديم فاخر' }
      ]
    }
  },

  // 4. Wedding Celebration Set
  {
    name: {
      en: 'Wedding Celebration Coffee Set',
      ar: 'طقم قهوة احتفال الزفاف'
    },
    description: {
      en: 'Celebrate new beginnings with this romantic coffee gift set. Perfect for newlyweds or as wedding favors, featuring premium blends and elegant accessories.',
      ar: 'احتفل بالبدايات الجديدة مع طقم القهوة الرومانسي هذا. مثالي للعرسان الجدد أو كهدايا الزفاف، يحتوي على خلطات فاخرة وإكسسوارات أنيقة.'
    },
    occasion: 'wedding',
    targetAudience: 'couple',
    price: {
      regular: 550,
      sale: 495,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Love Blend Coffee 500g', ar: 'خلطة الحب 500 جرام' },
            description: { en: 'Sweet and harmonious', ar: 'حلوة ومتناغمة' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'His & Hers Mugs Set', ar: 'طقم أكواب للعروسين' },
            description: { en: 'Matching ceramic mugs', ar: 'أكواب سيراميك متطابقة' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Pour Over Dripper', ar: 'أداة صب القهوة' },
            description: { en: 'Glass pour over set', ar: 'طقم صب زجاجي' }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: 'box',
      material: 'White premium box',
      color: 'White with gold ribbon',
      customization: {
        allowPersonalization: true,
        personalizationOptions: ['Names and date', 'Wedding message']
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1518057111178-44a106bad636?w=800',
        alt: { en: 'Wedding Coffee Set', ar: 'طقم قهوة الزفاف' },
        isPrimary: true,
        showsContents: true
      }
    ],
    availability: {
      isAvailable: true,
      seasonalAvailability: {
        startDate: new Date('2025-01-01'),
        endDate: new Date('2025-12-31')
      }
    },
    isActive: true,
    isFeatured: true,
    isPopular: false,
    displayOrder: 4,
    tags: ['wedding', 'romantic', 'couple', 'celebration'],
    marketingMessages: {
      shortDescription: {
        en: 'Start your journey together',
        ar: 'ابدأوا رحلتكم معاً'
      },
      highlights: [
        { en: 'Personalized with names', ar: 'مخصص بالأسماء' },
        { en: 'Beautiful wedding packaging', ar: 'تغليف زفاف جميل' },
        { en: 'Perfect wedding favor', ar: 'هدية زفاف مثالية' }
      ]
    }
  },

  // 5. Birthday Surprise Box
  {
    name: {
      en: 'Birthday Surprise Coffee Box',
      ar: 'صندوق مفاجأة عيد الميلاد'
    },
    description: {
      en: 'Make their birthday special with this delightful coffee surprise box. Includes birthday-themed treats and premium coffee selections.',
      ar: 'اجعل عيد ميلادهم مميزاً مع صندوق مفاجأة القهوة الرائع هذا. يشمل حلويات بثيمة عيد الميلاد وتشكيلة قهوة فاخرة.'
    },
    occasion: 'birthday',
    targetAudience: 'individual',
    price: {
      regular: 199,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Birthday Blend Coffee 250g', ar: 'خلطة عيد الميلاد 250 جرام' },
            description: { en: 'Festive coffee blend', ar: 'خلطة قهوة احتفالية' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Birthday Mug', ar: 'كوب عيد ميلاد' },
            description: { en: 'Festive design mug', ar: 'كوب بتصميم احتفالي' }
          }
        },
        quantity: 1,
        isHighlight: false
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Chocolate Treats', ar: 'حلويات الشوكولاتة' },
            description: { en: 'Artisan chocolates', ar: 'شوكولاتة حرفية' }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: 'box',
      material: 'Colorful gift box',
      color: 'Multi-color festive design',
      customization: {
        allowPersonalization: true,
        personalizationOptions: ['Birthday message', 'Age number']
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800',
        alt: { en: 'Birthday Gift Box', ar: 'صندوق هدية عيد الميلاد' },
        isPrimary: true,
        showsContents: true
      }
    ],
    availability: {
      isAvailable: true
    },
    isActive: true,
    isFeatured: false,
    isPopular: true,
    displayOrder: 5,
    tags: ['birthday', 'celebration', 'fun', 'colorful'],
    marketingMessages: {
      shortDescription: {
        en: 'Celebrate with coffee!',
        ar: 'احتفل مع القهوة!'
      },
      highlights: [
        { en: 'Festive birthday packaging', ar: 'تغليف احتفالي' },
        { en: 'Sweet treats included', ar: 'يشمل حلويات' },
        { en: 'Affordable birthday gift', ar: 'هدية عيد ميلاد ميسورة' }
      ]
    }
  },

  // 6. Professional Barista Kit
  {
    name: {
      en: 'Professional Barista Kit',
      ar: 'طقم باريستا محترف'
    },
    description: {
      en: 'Everything a professional barista needs. Premium tools, specialty beans, and expert guides for creating café-quality drinks at home.',
      ar: 'كل ما يحتاجه الباريستا المحترف. أدوات فاخرة وحبوب متخصصة وأدلة خبراء لصنع مشروبات بجودة المقاهي في المنزل.'
    },
    occasion: 'general',
    targetAudience: 'professional',
    price: {
      regular: 850,
      sale: 765,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Espresso Blend 1kg', ar: 'خلطة إسبريسو 1 كجم' },
            description: { en: 'Professional-grade espresso', ar: 'إسبريسو احترافي' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Professional Tamper', ar: 'مدك احترافي' },
            description: { en: 'Stainless steel 58mm', ar: 'ستانلس ستيل 58 مم' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Milk Frothing Pitcher', ar: 'إبريق رغوة الحليب' },
            description: { en: '600ml professional pitcher', ar: 'إبريق احترافي 600 مل' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Digital Scale', ar: 'ميزان رقمي' },
            description: { en: 'Precision coffee scale', ar: 'ميزان قهوة دقيق' }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: 'box',
      material: 'Professional black case',
      color: 'Matte black with foam insert',
      customization: {
        allowPersonalization: false
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1442512595331-e89e73853f31?w=800',
        alt: { en: 'Barista Kit', ar: 'طقم باريستا' },
        isPrimary: true,
        showsContents: true
      }
    ],
    availability: {
      isAvailable: true,
      limitedQuantity: {
        total: 50,
        remaining: 50
      }
    },
    isActive: true,
    isFeatured: true,
    isPopular: false,
    displayOrder: 6,
    tags: ['professional', 'barista', 'espresso', 'advanced'],
    marketingMessages: {
      shortDescription: {
        en: 'Pro-level coffee mastery',
        ar: 'إتقان القهوة الاحترافي'
      },
      highlights: [
        { en: 'Professional-grade tools', ar: 'أدوات احترافية' },
        { en: 'Complete barista setup', ar: 'إعداد باريستا كامل' },
        { en: 'Limited edition kit', ar: 'طقم إصدار محدود' }
      ]
    }
  },

  // 7. Holiday Special Collection
  {
    name: {
      en: 'Holiday Special Collection',
      ar: 'مجموعة العطلات الخاصة'
    },
    description: {
      en: 'Celebrate the festive season with our special holiday collection. Features seasonal blends and festive packaging perfect for gift-giving.',
      ar: 'احتفل بموسم الأعياد مع مجموعتنا الخاصة. تحتوي على خلطات موسمية وتغليف احتفالي مثالي للهدايا.'
    },
    occasion: 'holiday',
    targetAudience: 'family',
    price: {
      regular: 325,
      sale: 275,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Holiday Spice Blend 500g', ar: 'خلطة التوابل الاحتفالية 500 جرام' },
            description: { en: 'Cinnamon and nutmeg notes', ar: 'نكهات القرفة وجوزة الطيب' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Festive Mugs Set (4)', ar: 'طقم أكواب احتفالية (4)' },
            description: { en: 'Holiday-themed ceramic mugs', ar: 'أكواب سيراميك بثيمة العطلات' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Cinnamon Sticks Bundle', ar: 'حزمة عيدان القرفة' },
            description: { en: 'Natural cinnamon sticks', ar: 'عيدان قرفة طبيعية' }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: 'basket',
      material: 'Wicker basket',
      color: 'Natural with red ribbon',
      customization: {
        allowPersonalization: true,
        personalizationOptions: ['Holiday greeting card']
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1512568400610-62da28bc8a13?w=800',
        alt: { en: 'Holiday Gift Set', ar: 'طقم هدايا العطلات' },
        isPrimary: true,
        showsContents: true
      }
    ],
    availability: {
      isAvailable: true,
      seasonalAvailability: {
        startDate: new Date('2025-11-01'),
        endDate: new Date('2026-01-15')
      }
    },
    isActive: true,
    isFeatured: true,
    isPopular: true,
    displayOrder: 7,
    tags: ['holiday', 'seasonal', 'festive', 'family'],
    marketingMessages: {
      shortDescription: {
        en: 'Seasonal festive delight',
        ar: 'بهجة احتفالية موسمية'
      },
      highlights: [
        { en: 'Limited seasonal availability', ar: 'توفر موسمي محدود' },
        { en: 'Family-sized portions', ar: 'حصص عائلية' },
        { en: 'Beautiful holiday packaging', ar: 'تغليف احتفالي جميل' }
      ]
    }
  },

  // 8. Graduation Achievement Set
  {
    name: {
      en: 'Graduation Achievement Set',
      ar: 'طقم إنجاز التخرج'
    },
    description: {
      en: "Celebrate academic success with this inspiring coffee gift set. Perfect for graduates embarking on their next journey, featuring energizing blends and motivational accessories.",
      ar: 'احتفل بالنجاح الأكاديمي مع طقم القهوة الملهم هذا. مثالي للخريجين الذين يبدأون رحلتهم التالية، يحتوي على خلطات منشطة وإكسسوارات تحفيزية.'
    },
    occasion: 'graduation',
    targetAudience: 'individual',
    price: {
      regular: 220,
      currency: 'AED'
    },
    contents: [
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Success Blend Coffee 350g', ar: 'خلطة النجاح 350 جرام' },
            description: { en: 'Bold and energizing', ar: 'جريئة ومنشطة' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Motivational Travel Mug', ar: 'كوب سفر تحفيزي' },
            description: { en: 'With inspirational quote', ar: 'مع اقتباس ملهم' }
          }
        },
        quantity: 1,
        isHighlight: true
      },
      {
        item: {
          itemType: 'custom',
          customItem: {
            name: { en: 'Study Snack Mix', ar: 'خليط وجبات خفيفة' },
            description: { en: 'Energy-boosting nuts', ar: 'مكسرات منشطة للطاقة' }
          }
        },
        quantity: 1,
        isHighlight: false
      }
    ],
    packaging: {
      type: 'bag',
      material: 'Premium gift bag',
      color: 'Navy blue with gold accents',
      customization: {
        allowPersonalization: true,
        personalizationOptions: ['Graduate name', 'Congratulations message']
      }
    },
    images: [
      {
        url: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=800',
        alt: { en: 'Graduation Gift Set', ar: 'طقم هدية التخرج' },
        isPrimary: true,
        showsContents: false
      }
    ],
    availability: {
      isAvailable: true
    },
    isActive: true,
    isFeatured: false,
    isPopular: false,
    displayOrder: 8,
    tags: ['graduation', 'achievement', 'student', 'motivational'],
    marketingMessages: {
      shortDescription: {
        en: 'Fuel your future success',
        ar: 'وقود لنجاحك المستقبلي'
      },
      highlights: [
        { en: 'Personalized for graduate', ar: 'مخصص للخريج' },
        { en: 'Inspirational packaging', ar: 'تغليف ملهم' },
        { en: 'Perfect graduation gift', ar: 'هدية تخرج مثالية' }
      ]
    }
  }
];

// Seed function
const seedGiftSets = async () => {
  try {
    console.log('🌱 Starting Gift Sets seeding...\n');

    // Clear existing gift sets
    const deleteResult = await GiftSet.deleteMany({});
    console.log(`🗑️  Cleared ${deleteResult.deletedCount} existing gift sets\n`);

    // Insert new gift sets
    const insertedGiftSets = await GiftSet.insertMany(giftSetsData);
    console.log(`✅ Successfully seeded ${insertedGiftSets.length} gift sets:\n`);

    insertedGiftSets.forEach((giftSet, index) => {
      console.log(`${index + 1}. ${giftSet.name.en} (${giftSet.name.ar})`);
      console.log(`   - Price: ${giftSet.price.regular} ${giftSet.price.currency}${giftSet.price.sale ? ` (Sale: ${giftSet.price.sale})` : ''}`);
      console.log(`   - Occasion: ${giftSet.occasion}`);
      console.log(`   - Target: ${giftSet.targetAudience}`);
      console.log(`   - Featured: ${giftSet.isFeatured ? '⭐' : '❌'}`);
      console.log(`   - Popular: ${giftSet.isPopular ? '🔥' : '❌'}`);
      console.log('');
    });

    console.log('\n🎉 Gift Sets seeding completed successfully!');
    console.log(`\n📊 Summary:`);
    console.log(`   - Total gift sets: ${insertedGiftSets.length}`);
    console.log(`   - Featured: ${insertedGiftSets.filter(g => g.isFeatured).length}`);
    console.log(`   - Popular: ${insertedGiftSets.filter(g => g.isPopular).length}`);
    console.log(`   - Price range: ${Math.min(...insertedGiftSets.map(g => g.price.regular))} - ${Math.max(...insertedGiftSets.map(g => g.price.regular))} AED`);

  } catch (error) {
    console.error('❌ Error seeding gift sets:', error);
    throw error;
  }
};

// Run seeder
const runSeeder = async () => {
  try {
    await connectDB();
    await seedGiftSets();
    console.log('\n✅ Seeding process completed. Closing connection...');
    await mongoose.connection.close();
    console.log('👋 Database connection closed');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error);
    process.exit(1);
  }
};

// Execute if run directly
if (require.main === module) {
  runSeeder();
}

module.exports = { seedGiftSets, giftSetsData };

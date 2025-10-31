/**
 * Seed Brewing Methods Data
 * Al Marya Rostery - Brewing Methods Collection
 */

require('dotenv').config();
const mongoose = require('mongoose');
const BrewingMethod = require('./models/BrewingMethod');

// Sample brewing methods data
const brewingMethodsData = [
  {
    name: {
      en: "Pour Over V60",
      ar: "تقطير في 60"
    },
    description: {
      en: "A clean, bright brewing method that highlights the coffee's unique characteristics and origin flavors.",
      ar: "طريقة تحضير نظيفة ومشرقة تبرز خصائص القهوة الفريدة ونكهات المنشأ."
    },
    instructions: {
      en: "1. Heat water to 92-96°C\n2. Rinse the V60 filter with hot water\n3. Add ground coffee (medium-fine grind)\n4. Create a small well in the center\n5. Start with a 30-second bloom using twice the coffee weight in water\n6. Pour in slow, circular motions\n7. Total brew time: 2:30-3:30 minutes",
      ar: "1. سخن الماء إلى 92-96 درجة مئوية\n2. اشطف مرشح V60 بالماء الساخن\n3. أضف القهوة المطحونة (طحن متوسط ناعم)\n4. اصنع حفرة صغيرة في المنتصف\n5. ابدأ بالازدهار لمدة 30 ثانية باستخدام ضعف وزن القهوة من الماء\n6. اسكب بحركات دائرية بطيئة\n7. إجمالي وقت التحضير: 2:30-3:30 دقيقة"
    },
    equipment: [
      {
        name: { en: "Hario V60 Dripper", ar: "قطارة هاريو في 60" },
        required: true,
        description: { en: "Cone-shaped dripper with spiral ribs", ar: "قطارة مخروطية الشكل مع أضلاع حلزونية" }
      },
      {
        name: { en: "V60 Paper Filters", ar: "مرشحات ورقية في 60" },
        required: true,
        description: { en: "Specially designed filters for V60", ar: "مرشحات مصممة خصيصاً لـ في 60" }
      },
      {
        name: { en: "Gooseneck Kettle", ar: "إبريق رقبة الأوز" },
        required: true,
        description: { en: "For precise water pouring control", ar: "للتحكم الدقيق في صب الماء" }
      },
      {
        name: { en: "Coffee Scale", ar: "ميزان القهوة" },
        required: true,
        description: { en: "For accurate measurements", ar: "للقياسات الدقيقة" }
      }
    ],
    parameters: {
      grindSize: "Medium-Fine",
      coffeeToWaterRatio: "1:15 to 1:17",
      waterTemperature: {
        celsius: 94,
        fahrenheit: 201
      },
      brewTime: {
        minutes: 3,
        description: {
          en: "Total brew time including bloom",
          ar: "إجمالي وقت التحضير بما في ذلك الازدهار"
        }
      }
    },
    image: "/uploads/brewing-methods/v60-pour-over.jpg",
    icon: "fas fa-tint",
    color: "#8B4513",
    difficulty: "Intermediate",
    totalTime: 5,
    servings: 1,
    categories: ["Pour Over", "Manual Brewing", "Filter Coffee"],
    tags: ["clean", "bright", "precise", "manual"],
    isActive: true,
    displayOrder: 1,
    isPopular: true,
    tips: [
      {
        tip: {
          en: "Use a consistent pouring technique for even extraction",
          ar: "استخدم تقنية صب ثابتة للاستخراج المتساوي"
        },
        importance: "High"
      },
      {
        tip: {
          en: "Experiment with different grind sizes to find your preference",
          ar: "جرب أحجام طحن مختلفة للعثور على تفضيلك"
        },
        importance: "Medium"
      }
    ],
    seo: {
      metaTitle: {
        en: "V60 Pour Over Coffee Brewing Guide",
        ar: "دليل تحضير قهوة في 60 بالتقطير"
      },
      metaDescription: {
        en: "Learn how to brew perfect pour over coffee with V60 dripper",
        ar: "تعلم كيفية تحضير قهوة التقطير المثالية باستخدام قطارة في 60"
      },
      slug: "v60-pour-over",
      keywords: ["V60", "pour over", "coffee brewing", "manual brewing"]
    }
  },
  {
    name: {
      en: "French Press",
      ar: "الكبس الفرنسي"
    },
    description: {
      en: "Full-bodied brewing method that produces rich, aromatic coffee with oils and sediments for maximum flavor.",
      ar: "طريقة تحضير كاملة القوام تنتج قهوة غنية وعطرة مع الزيوت والرواسب للحصول على أقصى نكهة."
    },
    instructions: {
      en: "1. Heat water to 93-96°C\n2. Add coarse ground coffee to French Press\n3. Pour hot water over coffee grounds\n4. Stir gently to ensure all grounds are saturated\n5. Place lid with plunger up\n6. Steep for 4 minutes\n7. Press plunger down slowly and steadily\n8. Serve immediately",
      ar: "1. سخن الماء إلى 93-96 درجة مئوية\n2. أضف القهوة المطحونة الخشنة إلى الكبس الفرنسي\n3. اسكب الماء الساخن فوق مسحوق القهوة\n4. حرك برفق للتأكد من تشبع جميع المسحوق\n5. ضع الغطاء مع المكبس لأعلى\n6. انقع لمدة 4 دقائق\n7. اضغط المكبس لأسفل ببطء وثبات\n8. قدم فوراً"
    },
    equipment: [
      {
        name: { en: "French Press", ar: "الكبس الفرنسي" },
        required: true,
        description: { en: "Glass or metal brewing vessel with plunger", ar: "إناء تحضير زجاجي أو معدني مع مكبس" }
      },
      {
        name: { en: "Coffee Grinder", ar: "مطحنة القهوة" },
        required: true,
        description: { en: "For coarse grind coffee", ar: "للقهوة مطحونة خشن" }
      },
      {
        name: { en: "Kettle", ar: "إبريق" },
        required: true,
        description: { en: "For heating water", ar: "لتسخين الماء" }
      }
    ],
    parameters: {
      grindSize: "Coarse",
      coffeeToWaterRatio: "1:12 to 1:15",
      waterTemperature: {
        celsius: 94,
        fahrenheit: 201
      },
      brewTime: {
        minutes: 4,
        description: {
          en: "Steeping time before pressing",
          ar: "وقت النقع قبل الضغط"
        }
      }
    },
    image: "/uploads/brewing-methods/french-press.jpg",
    icon: "fas fa-weight",
    color: "#654321",
    difficulty: "Beginner",
    totalTime: 6,
    servings: 3,
    categories: ["Immersion", "Full Body", "Easy Brewing"],
    tags: ["full-body", "rich", "easy", "beginner-friendly"],
    isActive: true,
    displayOrder: 2,
    isPopular: true,
    tips: [
      {
        tip: {
          en: "Use coarse grind to prevent over-extraction",
          ar: "استخدم طحن خشن لمنع الاستخراج المفرط"
        },
        importance: "High"
      },
      {
        tip: {
          en: "Don't leave coffee in the press too long after brewing",
          ar: "لا تترك القهوة في الكبس طويلاً بعد التحضير"
        },
        importance: "Medium"
      }
    ],
    seo: {
      metaTitle: {
        en: "French Press Coffee Brewing Guide",
        ar: "دليل تحضير قهوة الكبس الفرنسي"
      },
      metaDescription: {
        en: "Master the art of French Press coffee brewing with our step-by-step guide",
        ar: "اتقن فن تحضير قهوة الكبس الفرنسي مع دليلنا خطوة بخطوة"
      },
      slug: "french-press",
      keywords: ["French Press", "immersion brewing", "full body coffee"]
    }
  },
  {
    name: {
      en: "Espresso",
      ar: "الإسبريسو"
    },
    description: {
      en: "Concentrated coffee brewing method using pressure to extract intense, rich flavors in a small serving.",
      ar: "طريقة تحضير قهوة مركزة باستخدام الضغط لاستخراج نكهات مكثفة وغنية في حجم صغير."
    },
    instructions: {
      en: "1. Preheat espresso machine and portafilter\n2. Grind coffee beans fine\n3. Dose 18-20g of coffee into portafilter\n4. Level and tamp grounds with 30lbs pressure\n5. Lock portafilter into group head\n6. Start extraction immediately\n7. Aim for 25-30 second extraction time\n8. Stop at 25-30ml volume (1:2 ratio)",
      ar: "1. سخن آلة الإسبريسو والبورتافيلتر مسبقاً\n2. اطحن حبوب القهوة ناعماً\n3. ضع 18-20 جرام من القهوة في البورتافيلتر\n4. استوِ واضغط المسحوق بضغط 30 رطل\n5. أدخل البورتافيلتر في رأس المجموعة\n6. ابدأ الاستخراج فوراً\n7. استهدف وقت استخراج 25-30 ثانية\n8. توقف عند حجم 25-30 مل (نسبة 1:2)"
    },
    equipment: [
      {
        name: { en: "Espresso Machine", ar: "آلة الإسبريسو" },
        required: true,
        description: { en: "Professional or semi-automatic espresso machine", ar: "آلة إسبريسو احترافية أو شبه أوتوماتيكية" }
      },
      {
        name: { en: "Coffee Grinder", ar: "مطحنة القهوة" },
        required: true,
        description: { en: "Burr grinder for fine, consistent grind", ar: "مطحنة أزيز للطحن الناعم والمتسق" }
      },
      {
        name: { en: "Tamper", ar: "الضاغط" },
        required: true,
        description: { en: "For compacting coffee grounds", ar: "لضغط مسحوق القهوة" }
      },
      {
        name: { en: "Scale", ar: "الميزان" },
        required: true,
        description: { en: "For precise dosing", ar: "للجرعات الدقيقة" }
      }
    ],
    parameters: {
      grindSize: "Fine",
      coffeeToWaterRatio: "1:2",
      waterTemperature: {
        celsius: 93,
        fahrenheit: 199
      },
      brewTime: {
        minutes: 0.5,
        description: {
          en: "Extraction time: 25-30 seconds",
          ar: "وقت الاستخراج: 25-30 ثانية"
        }
      }
    },
    image: "/uploads/brewing-methods/espresso.jpg",
    icon: "fas fa-coffee",
    color: "#3C1810",
    difficulty: "Expert",
    totalTime: 2,
    servings: 1,
    categories: ["Pressure Brewing", "Concentrated", "Professional"],
    tags: ["concentrated", "intense", "pressure", "professional"],
    isActive: true,
    displayOrder: 3,
    isPopular: true,
    tips: [
      {
        tip: {
          en: "Consistency in grind size is crucial for even extraction",
          ar: "الثبات في حجم الطحن أمر بالغ الأهمية للاستخراج المتساوي"
        },
        importance: "High"
      },
      {
        tip: {
          en: "Tamp with level pressure to avoid channeling",
          ar: "اضغط بضغط مستوٍ لتجنب التشقق"
        },
        importance: "High"
      },
      {
        tip: {
          en: "Fresh beans are essential for good crema",
          ar: "الحبوب الطازجة ضرورية للكريمة الجيدة"
        },
        importance: "Medium"
      }
    ],
    seo: {
      metaTitle: {
        en: "Perfect Espresso Brewing Guide",
        ar: "دليل تحضير الإسبريسو المثالي"
      },
      metaDescription: {
        en: "Learn to pull perfect espresso shots with our detailed brewing guide",
        ar: "تعلم سحب جرعات الإسبريسو المثالية مع دليل التحضير المفصل"
      },
      slug: "espresso",
      keywords: ["espresso", "pressure brewing", "coffee extraction", "barista"]
    }
  },
  {
    name: {
      en: "Chemex",
      ar: "الكيميكس"
    },
    description: {
      en: "Elegant pour-over method using thick filters for exceptionally clean, smooth coffee with minimal sediment.",
      ar: "طريقة تقطير أنيقة تستخدم مرشحات سميكة للحصول على قهوة نظيفة وناعمة استثنائياً مع الحد الأدنى من الرواسب."
    },
    instructions: {
      en: "1. Place Chemex filter in brewer (3 layers on spout side)\n2. Rinse filter with hot water to remove papery taste\n3. Add medium-coarse ground coffee\n4. Create a small well in center\n5. Start with bloom: pour 2x coffee weight in water\n6. Wait 30-45 seconds for bloom\n7. Pour in slow, steady spirals\n8. Total brew time: 4-6 minutes",
      ar: "1. ضع مرشح الكيميكس في المحضر (3 طبقات على جانب الصنبور)\n2. اشطف المرشح بالماء الساخن لإزالة طعم الورق\n3. أضف القهوة المطحونة متوسطة الخشونة\n4. اصنع حفرة صغيرة في المنتصف\n5. ابدأ بالازدهار: اسكب ضعف وزن القهوة من الماء\n6. انتظر 30-45 ثانية للازدهار\n7. اسكب بحلزونات بطيئة وثابتة\n8. إجمالي وقت التحضير: 4-6 دقائق"
    },
    equipment: [
      {
        name: { en: "Chemex Brewer", ar: "محضر الكيميكس" },
        required: true,
        description: { en: "Glass pour-over brewer with wooden collar", ar: "محضر تقطير زجاجي مع طوق خشبي" }
      },
      {
        name: { en: "Chemex Filters", ar: "مرشحات الكيميكس" },
        required: true,
        description: { en: "Thick paper filters for Chemex", ar: "مرشحات ورقية سميكة للكيميكس" }
      },
      {
        name: { en: "Gooseneck Kettle", ar: "إبريق رقبة الأوز" },
        required: true,
        description: { en: "For controlled pouring", ar: "للصب المتحكم فيه" }
      }
    ],
    parameters: {
      grindSize: "Medium-Coarse",
      coffeeToWaterRatio: "1:15 to 1:17",
      waterTemperature: {
        celsius: 93,
        fahrenheit: 199
      },
      brewTime: {
        minutes: 5,
        description: {
          en: "Total brewing time including bloom",
          ar: "إجمالي وقت التحضير بما في ذلك الازدهار"
        }
      }
    },
    image: "/uploads/brewing-methods/chemex.jpg",
    icon: "fas fa-flask",
    color: "#B8860B",
    difficulty: "Intermediate",
    totalTime: 7,
    servings: 2,
    categories: ["Pour Over", "Clean Cup", "Filter Coffee"],
    tags: ["clean", "smooth", "elegant", "minimal-sediment"],
    isActive: true,
    displayOrder: 4,
    isPopular: false,
    tips: [
      {
        tip: {
          en: "Rinse the filter thoroughly to remove paper taste",
          ar: "اشطف المرشح جيداً لإزالة طعم الورق"
        },
        importance: "High"
      },
      {
        tip: {
          en: "Pour in the center and work outward in spirals",
          ar: "اسكب في المنتصف واعمل للخارج بحركات حلزونية"
        },
        importance: "Medium"
      }
    ],
    seo: {
      metaTitle: {
        en: "Chemex Coffee Brewing Guide",
        ar: "دليل تحضير قهوة الكيميكس"
      },
      metaDescription: {
        en: "Brew clean, smooth coffee with Chemex pour-over method",
        ar: "حضر قهوة نظيفة وناعمة بطريقة تقطير الكيميكس"
      },
      slug: "chemex",
      keywords: ["Chemex", "pour over", "clean coffee", "filter coffee"]
    }
  },
  {
    name: {
      en: "Cold Brew",
      ar: "القهوة الباردة"
    },
    description: {
      en: "Slow extraction method using cold water over extended time, resulting in smooth, low-acid coffee concentrate.",
      ar: "طريقة استخراج بطيئة باستخدام الماء البارد لفترة طويلة، مما ينتج عنه مركز قهوة ناعم ومنخفض الحموضة."
    },
    instructions: {
      en: "1. Coarsely grind coffee beans\n2. Combine coffee and cold water in container\n3. Stir to ensure all grounds are saturated\n4. Cover and refrigerate for 12-24 hours\n5. Strain through fine mesh or filter\n6. Dilute concentrate with water or milk\n7. Serve over ice\n8. Store concentrate for up to 2 weeks",
      ar: "1. اطحن حبوب القهوة خشناً\n2. اخلط القهوة والماء البارد في إناء\n3. حرك للتأكد من تشبع جميع المسحوق\n4. غطِ وضع في الثلاجة لمدة 12-24 ساعة\n5. اصفِ من خلال شبكة ناعمة أو مرشح\n6. خفف المركز بالماء أو الحليب\n7. قدم على الثلج\n8. احفظ المركز لمدة تصل إلى أسبوعين"
    },
    equipment: [
      {
        name: { en: "Large Jar or Container", ar: "برطمان أو إناء كبير" },
        required: true,
        description: { en: "For steeping coffee", ar: "لنقع القهوة" }
      },
      {
        name: { en: "Fine Mesh Strainer", ar: "مصفاة ناعمة" },
        required: true,
        description: { en: "For filtering grounds", ar: "لتصفية المسحوق" }
      },
      {
        name: { en: "Coffee Filter", ar: "مرشح القهوة" },
        required: false,
        description: { en: "For extra filtration", ar: "للتصفية الإضافية" }
      }
    ],
    parameters: {
      grindSize: "Coarse",
      coffeeToWaterRatio: "1:4 to 1:8",
      waterTemperature: {
        celsius: 20,
        fahrenheit: 68
      },
      brewTime: {
        minutes: 720,
        description: {
          en: "12-24 hours steeping time",
          ar: "وقت نقع 12-24 ساعة"
        }
      }
    },
    image: "/uploads/brewing-methods/cold-brew.jpg",
    icon: "fas fa-snowflake",
    color: "#4682B4",
    difficulty: "Beginner",
    totalTime: 720,
    servings: 4,
    categories: ["Cold Brewing", "Concentrate", "Low Acid"],
    tags: ["cold", "smooth", "low-acid", "concentrate"],
    isActive: true,
    displayOrder: 5,
    isPopular: true,
    tips: [
      {
        tip: {
          en: "Use coarse grind to prevent over-extraction",
          ar: "استخدم طحن خشن لمنع الاستخراج المفرط"
        },
        importance: "High"
      },
      {
        tip: {
          en: "Longer steeping time doesn't always mean stronger coffee",
          ar: "وقت النقع الأطول لا يعني دائماً قهوة أقوى"
        },
        importance: "Medium"
      },
      {
        tip: {
          en: "Store concentrate in refrigerator for best quality",
          ar: "احفظ المركز في الثلاجة للحصول على أفضل جودة"
        },
        importance: "Medium"
      }
    ],
    seo: {
      metaTitle: {
        en: "Cold Brew Coffee Guide",
        ar: "دليل القهوة الباردة"
      },
      metaDescription: {
        en: "Learn to make smooth, refreshing cold brew coffee at home",
        ar: "تعلم صنع قهوة باردة ناعمة ومنعشة في المنزل"
      },
      slug: "cold-brew",
      keywords: ["cold brew", "cold coffee", "low acid coffee", "coffee concentrate"]
    }
  }
];

// Connect to MongoDB
const connectDB = async () => {
  try {
    const mongoUri = process.env.MONGODB_URI || process.env.MONGO_URI;
    if (!mongoUri) {
      throw new Error('MongoDB URI not found in environment variables');
    }
    const conn = await mongoose.connect(mongoUri);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error('Error connecting to MongoDB:', error);
    process.exit(1);
  }
};

// Seed brewing methods
const seedBrewingMethods = async () => {
  try {
    console.log('🍵 Starting to seed brewing methods...');
    
    // Clear existing brewing methods
    await BrewingMethod.deleteMany({});
    console.log('✅ Cleared existing brewing methods');
    
    // Insert sample brewing methods
    const insertedMethods = await BrewingMethod.insertMany(brewingMethodsData);
    console.log(`✅ Inserted ${insertedMethods.length} brewing methods`);
    
    // Log created methods
    insertedMethods.forEach(method => {
      console.log(`  - ${method.name.en} (${method.difficulty})`);
    });
    
    console.log('🎉 Brewing methods seeding completed successfully!');
    
  } catch (error) {
    console.error('❌ Error seeding brewing methods:', error);
    throw error;
  }
};

// Main execution
const main = async () => {
  try {
    await connectDB();
    await seedBrewingMethods();
    
    console.log('\n🚀 All done! You can now:');
    console.log('1. View brewing methods in admin panel at http://localhost:5001/');
    console.log('2. Access API at http://localhost:5001/api/brewing-methods');
    console.log('3. Check individual method at http://localhost:5001/api/brewing-methods/{id}');
    
  } catch (error) {
    console.error('❌ Fatal error:', error);
  } finally {
    process.exit(0);
  }
};

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = {
  brewingMethodsData,
  seedBrewingMethods
};

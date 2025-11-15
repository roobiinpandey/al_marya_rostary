/**
 * Attribute Seed Script
 * Migrates all hardcoded product attributes to the dynamic AttributeGroup and AttributeValue system
 * Run this script once to populate the database with initial attribute data
 * 
 * Usage: node backend/scripts/seed-attributes.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const AttributeGroup = require('../models/AttributeGroup');
const AttributeValue = require('../models/AttributeValue');

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/al_marya_rostery';

console.log('🌱 Starting Attribute Seeding...');
console.log(`📍 Connecting to: ${MONGODB_URI.replace(/\/\/.*:.*@/, '//***:***@')}`);

// ============================================================================
// ATTRIBUTE DATA DEFINITIONS
// ============================================================================

const attributeGroups = [
  {
    key: 'origin_countries',
    name: { en: 'Origin Countries', ar: 'بلد المنشأ' },
    description: {
      en: 'Coffee growing countries and regions',
      ar: 'البلدان والمناطق المنتجة للقهوة'
    },
    type: 'single-select',
    scope: 'product-attribute',
    isRequired: true,
    usedInSKU: true,
    displayOrder: 1,
    icon: '🌍',
    color: '#4CAF50',
    helpText: {
      en: 'Select the country where the coffee beans are grown',
      ar: 'اختر البلد الذي تزرع فيه حبوب القهوة'
    },
    placeholder: {
      en: 'Select origin country...',
      ar: 'اختر بلد المنشأ...'
    }
  },
  {
    key: 'roast_levels',
    name: { en: 'Roast Levels', ar: 'مستويات التحميص' },
    description: {
      en: 'Coffee roast intensities from light to dark',
      ar: 'شدة تحميص القهوة من الفاتح إلى الداكن'
    },
    type: 'single-select',
    scope: 'product-attribute',
    isRequired: true,
    usedInSKU: true,
    displayOrder: 2,
    icon: '☀️',
    color: '#8D6E63',
    helpText: {
      en: 'Select how dark the coffee beans are roasted',
      ar: 'اختر درجة تحميص حبوب القهوة'
    },
    placeholder: {
      en: 'Select roast level...',
      ar: 'اختر مستوى التحميص...'
    }
  },
  {
    key: 'processing_methods',
    name: { en: 'Processing Methods', ar: 'طرق المعالجة' },
    description: {
      en: 'Methods used to process coffee cherries into green beans',
      ar: 'الطرق المستخدمة لمعالجة ثمار القهوة'
    },
    type: 'single-select',
    scope: 'product-attribute',
    isRequired: false,
    usedInSKU: false,
    displayOrder: 3,
    icon: '⚙️',
    color: '#FF9800',
    helpText: {
      en: 'How the coffee was processed after harvesting',
      ar: 'كيفية معالجة القهوة بعد الحصاد'
    },
    placeholder: {
      en: 'Select processing method...',
      ar: 'اختر طريقة المعالجة...'
    }
  },
  {
    key: 'flavor_profiles',
    name: { en: 'Flavor Profiles', ar: 'النكهات' },
    description: {
      en: 'Tasting notes and flavor characteristics',
      ar: 'ملاحظات التذوق وخصائص النكهة'
    },
    type: 'checkbox-group',
    scope: 'product-attribute',
    isRequired: false,
    usedInSKU: false,
    displayOrder: 4,
    icon: '🍃',
    color: '#9C27B0',
    validation: {
      minValues: 0,
      maxValues: 5
    },
    helpText: {
      en: 'Select flavor notes present in this coffee (max 5)',
      ar: 'اختر نكهات القهوة (بحد أقصى 5)'
    }
  }
];

// Origin Countries with hierarchical structure
const originValues = [
  // Africa Region
  { parent: 'Africa', parentAr: 'أفريقيا', values: [
    { value: 'ethiopia', nameEn: 'Ethiopia', nameAr: 'إثيوبيا', icon: '🇪🇹', metadata: { region: 'Africa', altitude: '1500-2200m', climate: 'Tropical' } },
    { value: 'kenya', nameEn: 'Kenya', nameAr: 'كينيا', icon: '🇰🇪', metadata: { region: 'Africa', altitude: '1400-2000m', climate: 'Tropical' } },
    { value: 'tanzania', nameEn: 'Tanzania', nameAr: 'تنزانيا', icon: '🇹🇿', metadata: { region: 'Africa', altitude: '1200-2000m', climate: 'Tropical' } },
    { value: 'rwanda', nameEn: 'Rwanda', nameAr: 'رواندا', icon: '🇷🇼', metadata: { region: 'Africa', altitude: '1700-2000m', climate: 'Tropical Highland' } },
    { value: 'burundi', nameEn: 'Burundi', nameAr: 'بوروندي', icon: '🇧🇮', metadata: { region: 'Africa', altitude: '1300-2000m', climate: 'Tropical' } }
  ]},
  // Latin America Region
  { parent: 'Latin America', parentAr: 'أمريكا اللاتينية', values: [
    { value: 'colombia', nameEn: 'Colombia', nameAr: 'كولومبيا', icon: '🇨🇴', metadata: { region: 'Latin America', altitude: '1200-2000m', climate: 'Tropical' } },
    { value: 'brazil', nameEn: 'Brazil', nameAr: 'البرازيل', icon: '🇧🇷', metadata: { region: 'Latin America', altitude: '800-1600m', climate: 'Tropical/Subtropical' } },
    { value: 'guatemala', nameEn: 'Guatemala', nameAr: 'غواتيمالا', icon: '🇬🇹', metadata: { region: 'Latin America', altitude: '1300-2000m', climate: 'Tropical' } },
    { value: 'costa-rica', nameEn: 'Costa Rica', nameAr: 'كوستاريكا', icon: '🇨🇷', metadata: { region: 'Latin America', altitude: '1200-1700m', climate: 'Tropical' } },
    { value: 'honduras', nameEn: 'Honduras', nameAr: 'هندوراس', icon: '🇭🇳', metadata: { region: 'Latin America', altitude: '1000-1500m', climate: 'Tropical' } },
    { value: 'peru', nameEn: 'Peru', nameAr: 'بيرو', icon: '🇵🇪', metadata: { region: 'Latin America', altitude: '1200-2000m', climate: 'Tropical' } },
    { value: 'el-salvador', nameEn: 'El Salvador', nameAr: 'السلفادور', icon: '🇸🇻', metadata: { region: 'Latin America', altitude: '1200-1800m', climate: 'Tropical' } }
  ]},
  // Asia & Pacific Region
  { parent: 'Asia & Pacific', parentAr: 'آسيا والمحيط الهادئ', values: [
    { value: 'indonesia', nameEn: 'Indonesia', nameAr: 'إندونيسيا', icon: '🇮🇩', metadata: { region: 'Asia', altitude: '1000-1800m', climate: 'Tropical' } },
    { value: 'india', nameEn: 'India', nameAr: 'الهند', icon: '🇮🇳', metadata: { region: 'Asia', altitude: '1000-1500m', climate: 'Tropical Monsoon' } },
    { value: 'vietnam', nameEn: 'Vietnam', nameAr: 'فيتنام', icon: '🇻🇳', metadata: { region: 'Asia', altitude: '500-1500m', climate: 'Tropical' } },
    { value: 'papua-new-guinea', nameEn: 'Papua New Guinea', nameAr: 'بابوا غينيا الجديدة', icon: '🇵🇬', metadata: { region: 'Pacific', altitude: '1200-1800m', climate: 'Tropical' } },
    { value: 'yemen', nameEn: 'Yemen', nameAr: 'اليمن', icon: '🇾🇪', metadata: { region: 'Asia', altitude: '1500-2400m', climate: 'Arid/Semi-arid' } }
  ]},
  // Other
  { parent: 'Other', parentAr: 'أخرى', values: [
    { value: 'multi-origin', nameEn: 'Multi-Origin Blend', nameAr: 'خليط متعدد المناشئ', icon: '🌐', metadata: { region: 'Multiple', description: 'Blend from multiple origins' } }
  ]}
];

// Roast Levels
const roastLevels = [
  { value: 'light', nameEn: 'Light Roast', nameAr: 'تحميص خفيف', icon: '☀️', color: '#D4A574', displayOrder: 1, description: { en: 'Light brown color, no oil on surface, bright acidity', ar: 'لون بني فاتح، لا يوجد زيت على السطح، حموضة ساطعة' } },
  { value: 'medium-light', nameEn: 'Medium-Light Roast', nameAr: 'تحميص متوسط خفيف', icon: '🌤️', color: '#C19A6B', displayOrder: 2, description: { en: 'Light-medium brown, balanced flavor', ar: 'بني فاتح متوسط، نكهة متوازنة' } },
  { value: 'medium', nameEn: 'Medium Roast', nameAr: 'تحميص متوسط', icon: '☁️', color: '#A0826D', displayOrder: 3, description: { en: 'Medium brown, balanced acidity and body', ar: 'بني متوسط، حموضة وقوام متوازن' } },
  { value: 'medium-dark', nameEn: 'Medium-Dark Roast', nameAr: 'تحميص متوسط داكن', icon: '🌥️', color: '#6F4E37', displayOrder: 4, description: { en: 'Dark brown, some oil on surface, bittersweet', ar: 'بني داكن، بعض الزيت على السطح، حلو ومر' } },
  { value: 'dark', nameEn: 'Dark Roast', nameAr: 'تحميص داكن', icon: '🌑', color: '#3E2723', displayOrder: 5, description: { en: 'Very dark brown, shiny with oil, bold flavor', ar: 'بني داكن جداً، لامع بالزيت، نكهة قوية' } }
];

// Processing Methods
const processingMethods = [
  { value: 'washed', nameEn: 'Washed (Wet Processed)', nameAr: 'مغسول (معالجة رطبة)', displayOrder: 1, description: { en: 'Clean, bright, consistent flavor', ar: 'نكهة نظيفة وساطعة ومتناسقة' } },
  { value: 'natural', nameEn: 'Natural (Dry Processed)', nameAr: 'طبيعي (معالجة جافة)', displayOrder: 2, description: { en: 'Fruity, wine-like, heavy body', ar: 'فاكهية، تشبه النبيذ، قوام ثقيل' } },
  { value: 'honey', nameEn: 'Honey Processed', nameAr: 'معالجة العسل', displayOrder: 3, description: { en: 'Sweet, balanced between washed and natural', ar: 'حلوة، متوازنة بين المغسول والطبيعي' } },
  { value: 'wet-hulled', nameEn: 'Wet-Hulled (Giling Basah)', nameAr: 'مقشر رطب', displayOrder: 4, description: { en: 'Earthy, full body, low acidity', ar: 'ترابية، قوام كامل، حموضة منخفضة' } },
  { value: 'semi-washed', nameEn: 'Semi-Washed (Pulped Natural)', nameAr: 'نصف مغسول', displayOrder: 5, description: { en: 'Sweet with some fruit notes', ar: 'حلوة مع بعض نكهات الفاكهة' } },
  { value: 'anaerobic', nameEn: 'Anaerobic Fermentation', nameAr: 'تخمير لاهوائي', displayOrder: 6, description: { en: 'Complex, experimental, unique flavors', ar: 'معقدة، تجريبية، نكهات فريدة' } }
];

// Flavor Profiles
const flavorProfiles = [
  { value: 'fruity', nameEn: 'Fruity', nameAr: 'فواكهية', icon: '🍓', color: '#FF6B6B', displayOrder: 1, description: { en: 'Berry, citrus, stone fruit notes', ar: 'نكهات التوت والحمضيات والفاكهة الحجرية' } },
  { value: 'nutty', nameEn: 'Nutty', nameAr: 'جوزية', icon: '🌰', color: '#8B4513', displayOrder: 2, description: { en: 'Almond, hazelnut, walnut notes', ar: 'نكهات اللوز والبندق والجوز' } },
  { value: 'chocolate', nameEn: 'Chocolate', nameAr: 'شوكولاتة', icon: '🍫', color: '#5D4037', displayOrder: 3, description: { en: 'Cocoa, dark chocolate notes', ar: 'نكهات الكاكاو والشوكولاتة الداكنة' } },
  { value: 'floral', nameEn: 'Floral', nameAr: 'زهرية', icon: '🌸', color: '#E91E63', displayOrder: 4, description: { en: 'Jasmine, rose, lavender notes', ar: 'نكهات الياسمين والورد واللافندر' } },
  { value: 'spicy', nameEn: 'Spicy', nameAr: 'بهارية', icon: '🌶️', color: '#D32F2F', displayOrder: 5, description: { en: 'Cinnamon, clove, pepper notes', ar: 'نكهات القرفة والقرنفل والفلفل' } },
  { value: 'caramel', nameEn: 'Caramel', nameAr: 'كراميل', icon: '🍮', color: '#D4A574', displayOrder: 6, description: { en: 'Toffee, brown sugar, caramel notes', ar: 'نكهات التوفي والسكر البني والكراميل' } },
  { value: 'citrus', nameEn: 'Citrus', nameAr: 'حمضيات', icon: '🍋', color: '#FDD835', displayOrder: 7, description: { en: 'Lemon, orange, grapefruit notes', ar: 'نكهات الليمون والبرتقال والجريب فروت' } },
  { value: 'berry', nameEn: 'Berry', nameAr: 'توت', icon: '🫐', color: '#673AB7', displayOrder: 8, description: { en: 'Blueberry, raspberry, blackberry notes', ar: 'نكهات العنب البري والتوت الأحمر والتوت الأسود' } },
  { value: 'earthy', nameEn: 'Earthy', nameAr: 'ترابية', icon: '🌱', color: '#6D4C41', displayOrder: 9, description: { en: 'Forest floor, mushroom, tobacco notes', ar: 'نكهات أرضية الغابة والفطر والتبغ' } },
  { value: 'sweet', nameEn: 'Sweet', nameAr: 'حلوة', icon: '🍯', color: '#FFB300', displayOrder: 10, description: { en: 'Honey, maple, vanilla notes', ar: 'نكهات العسل والقيقب والفانيليا' } },
  { value: 'smoky', nameEn: 'Smoky', nameAr: 'دخانية', icon: '💨', color: '#424242', displayOrder: 11, description: { en: 'Roasted, charred, smoky notes', ar: 'نكهات محمصة ومتفحمة ودخانية' } },
  { value: 'winey', nameEn: 'Winey', nameAr: 'نبيذية', icon: '🍷', color: '#880E4F', displayOrder: 12, description: { en: 'Wine, grape, fermented notes', ar: 'نكهات النبيذ والعنب والتخمر' } }
];

// ============================================================================
// SEED FUNCTIONS
// ============================================================================

async function seedAttributeGroups() {
  console.log('\n📦 Seeding Attribute Groups...');
  
  const createdGroups = {};
  
  for (const groupData of attributeGroups) {
    try {
      // Check if group already exists
      let group = await AttributeGroup.findOne({ key: groupData.key });
      
      if (group) {
        console.log(`   ⏩ Group "${groupData.name.en}" already exists, skipping...`);
      } else {
        group = new AttributeGroup(groupData);
        await group.save();
        console.log(`   ✅ Created group: ${groupData.name.en} (${groupData.key})`);
      }
      
      createdGroups[groupData.key] = group;
    } catch (error) {
      console.error(`   ❌ Error creating group ${groupData.key}:`, error.message);
    }
  }
  
  return createdGroups;
}

async function seedOriginCountries(originGroup) {
  console.log('\n🌍 Seeding Origin Countries...');
  
  let totalCreated = 0;
  
  for (const regionData of originValues) {
    // Create parent value (region)
    let parentValue = await AttributeValue.findOne({
      attributeGroup: originGroup._id,
      value: regionData.parent.toLowerCase().replace(/\s+/g, '-')
    });
    
    if (!parentValue) {
      parentValue = new AttributeValue({
        attributeGroup: originGroup._id,
        name: { en: regionData.parent, ar: regionData.parentAr },
        value: regionData.parent.toLowerCase().replace(/\s+/g, '-'),
        displayOrder: totalCreated,
        isActive: true
      });
      await parentValue.save();
      console.log(`   ✅ Created region: ${regionData.parent}`);
    }
    
    // Create child values (countries)
    for (const country of regionData.values) {
      try {
        const existing = await AttributeValue.findOne({
          attributeGroup: originGroup._id,
          value: country.value
        });
        
        if (existing) {
          console.log(`   ⏩ ${country.nameEn} already exists, skipping...`);
          continue;
        }
        
        const countryValue = new AttributeValue({
          attributeGroup: originGroup._id,
          name: { en: country.nameEn, ar: country.nameAr },
          value: country.value,
          icon: country.icon,
          parentValue: parentValue._id,
          metadata: country.metadata || {},
          displayOrder: country.displayOrder || totalCreated,
          isActive: true
        });
        
        await countryValue.save();
        console.log(`   ✅ Created country: ${country.nameEn} → ${regionData.parent}`);
        totalCreated++;
      } catch (error) {
        console.error(`   ❌ Error creating country ${country.nameEn}:`, error.message);
      }
    }
  }
  
  console.log(`\n   📊 Total countries created: ${totalCreated}`);
}

async function seedRoastLevels(roastGroup) {
  console.log('\n☕ Seeding Roast Levels...');
  
  let totalCreated = 0;
  
  for (const roast of roastLevels) {
    try {
      const existing = await AttributeValue.findOne({
        attributeGroup: roastGroup._id,
        value: roast.value
      });
      
      if (existing) {
        console.log(`   ⏩ ${roast.nameEn} already exists, skipping...`);
        continue;
      }
      
      const roastValue = new AttributeValue({
        attributeGroup: roastGroup._id,
        name: { en: roast.nameEn, ar: roast.nameAr },
        value: roast.value,
        icon: roast.icon,
        color: roast.color,
        description: roast.description,
        displayOrder: roast.displayOrder,
        isActive: true
      });
      
      await roastValue.save();
      console.log(`   ✅ Created roast level: ${roast.icon} ${roast.nameEn}`);
      totalCreated++;
    } catch (error) {
      console.error(`   ❌ Error creating roast level ${roast.nameEn}:`, error.message);
    }
  }
  
  console.log(`\n   📊 Total roast levels created: ${totalCreated}`);
}

async function seedProcessingMethods(processingGroup) {
  console.log('\n⚙️  Seeding Processing Methods...');
  
  let totalCreated = 0;
  
  for (const method of processingMethods) {
    try {
      const existing = await AttributeValue.findOne({
        attributeGroup: processingGroup._id,
        value: method.value
      });
      
      if (existing) {
        console.log(`   ⏩ ${method.nameEn} already exists, skipping...`);
        continue;
      }
      
      const methodValue = new AttributeValue({
        attributeGroup: processingGroup._id,
        name: { en: method.nameEn, ar: method.nameAr },
        value: method.value,
        description: method.description,
        displayOrder: method.displayOrder,
        isActive: true
      });
      
      await methodValue.save();
      console.log(`   ✅ Created processing method: ${method.nameEn}`);
      totalCreated++;
    } catch (error) {
      console.error(`   ❌ Error creating processing method ${method.nameEn}:`, error.message);
    }
  }
  
  console.log(`\n   📊 Total processing methods created: ${totalCreated}`);
}

async function seedFlavorProfiles(flavorGroup) {
  console.log('\n🍃 Seeding Flavor Profiles...');
  
  let totalCreated = 0;
  
  for (const flavor of flavorProfiles) {
    try {
      const existing = await AttributeValue.findOne({
        attributeGroup: flavorGroup._id,
        value: flavor.value
      });
      
      if (existing) {
        console.log(`   ⏩ ${flavor.nameEn} already exists, skipping...`);
        continue;
      }
      
      const flavorValue = new AttributeValue({
        attributeGroup: flavorGroup._id,
        name: { en: flavor.nameEn, ar: flavor.nameAr },
        value: flavor.value,
        icon: flavor.icon,
        color: flavor.color,
        description: flavor.description,
        displayOrder: flavor.displayOrder,
        isActive: true
      });
      
      await flavorValue.save();
      console.log(`   ✅ Created flavor: ${flavor.icon} ${flavor.nameEn}`);
      totalCreated++;
    } catch (error) {
      console.error(`   ❌ Error creating flavor ${flavor.nameEn}:`, error.message);
    }
  }
  
  console.log(`\n   📊 Total flavors created: ${totalCreated}`);
}

// ============================================================================
// MAIN EXECUTION
// ============================================================================

async function main() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    // Seed attribute groups
    const groups = await seedAttributeGroups();
    
    // Seed attribute values
    if (groups.origin_countries) {
      await seedOriginCountries(groups.origin_countries);
    }
    
    if (groups.roast_levels) {
      await seedRoastLevels(groups.roast_levels);
    }
    
    if (groups.processing_methods) {
      await seedProcessingMethods(groups.processing_methods);
    }
    
    if (groups.flavor_profiles) {
      await seedFlavorProfiles(groups.flavor_profiles);
    }
    
    // Summary
    console.log('\n' + '='.repeat(60));
    console.log('✨ ATTRIBUTE SEEDING COMPLETE!');
    console.log('='.repeat(60));
    
    const groupCount = await AttributeGroup.countDocuments();
    const valueCount = await AttributeValue.countDocuments();
    
    console.log(`\n📊 Summary:`);
    console.log(`   - Attribute Groups: ${groupCount}`);
    console.log(`   - Attribute Values: ${valueCount}`);
    
    console.log('\n🎉 All attributes have been successfully seeded to the database!');
    console.log('📝 Next steps:');
    console.log('   1. Update product form to load dynamic attributes');
    console.log('   2. Create attribute management UI in admin panel');
    console.log('   3. Test attribute CRUD operations\n');
    
  } catch (error) {
    console.error('\n❌ Fatal error during seeding:', error);
    process.exit(1);
  } finally {
    // Close connection
    await mongoose.connection.close();
    console.log('👋 Database connection closed');
    process.exit(0);
  }
}

// Run the seed script
main();

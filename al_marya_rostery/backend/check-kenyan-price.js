require('dotenv').config();
const mongoose = require('mongoose');

// Simple coffee schema
const coffeeSchema = new mongoose.Schema({}, { strict: false });
const Coffee = mongoose.model('Coffee', coffeeSchema);

async function checkKenyanPrice() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/al_marya_rostery');
    console.log('✅ Connected to MongoDB\n');

    const kenyan = await Coffee.findOne({ 'name.en': 'Kenyan AA Premium' });
    
    if (!kenyan) {
      console.log('❌ Kenyan AA Premium not found in database');
      return;
    }

    console.log('📦 Kenyan AA Premium pricing:');
    console.log('Base price:', kenyan.price);
    console.log('\nVariants:');
    kenyan.variants.forEach(v => {
      console.log(`  ${v.size}: AED ${v.price} (stock: ${v.stock})`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await mongoose.disconnect();
  }
}

checkKenyanPrice();

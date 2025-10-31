const mongoose = require('mongoose');
require('dotenv').config();

async function checkSliders() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');
    
    const sliderSchema = new mongoose.Schema({}, { collection: 'sliders', strict: false });
    const Slider = mongoose.model('Slider', sliderSchema);
    
    const count = await Slider.countDocuments();
    console.log('📊 Total sliders in database:', count);
    
    if (count > 0) {
      const sliders = await Slider.find({}).limit(3);
      console.log('🎯 Sample slider data:');
      sliders.forEach((slider, index) => {
        console.log(`${index + 1}. Title: ${slider.title || 'No Title'}`);
        console.log(`   Active: ${slider.isActive}`);
        console.log(`   Image: ${slider.image || 'No Image'}`);
        console.log('');
      });
    } else {
      console.log('⚠️  No sliders found in database');
      console.log('📱 Flutter app will use fallback mockup images');
    }
    
    mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

checkSliders();

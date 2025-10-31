/**
 * Delete placeholder/test sliders from database
 * Run with: node delete-placeholder-sliders.js
 */

const mongoose = require('mongoose');
const Slider = require('./models/Slider');

const MONGODB_URI = process.env.MONGODB_URI || '***REMOVED******REMOVED***:***REMOVED***@almaryarostery.2yel8zi.mongodb.net/al_marya_rostery?retryWrites=true&w=majority&appName=almaryarostery';

async function deletePlaceholderSliders() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find all sliders
    const allSliders = await Slider.find({});
    console.log(`📊 Total sliders in database: ${allSliders.length}\n`);

    // Find placeholder sliders (those with via.placeholder.com or unsplash.com)
    const placeholderSliders = await Slider.find({
      $or: [
        { image: { $regex: 'placeholder', $options: 'i' } },
        { image: { $regex: 'unsplash', $options: 'i' } },
        { mobileImage: { $regex: 'placeholder', $options: 'i' } },
        { mobileImage: { $regex: 'unsplash', $options: 'i' } }
      ]
    });

    if (placeholderSliders.length === 0) {
      console.log('✅ No placeholder sliders found! Database is clean.');
      process.exit(0);
    }

    console.log(`🎯 Found ${placeholderSliders.length} placeholder sliders:\n`);
    placeholderSliders.forEach((slider, index) => {
      console.log(`${index + 1}. ID: ${slider._id}`);
      console.log(`   Title: ${slider.title}`);
      console.log(`   Image: ${slider.image}`);
      console.log(`   Active: ${slider.isActive}\n`);
    });

    // Delete placeholder sliders
    console.log('🗑️  Deleting placeholder sliders...');
    const deleteResult = await Slider.deleteMany({
      $or: [
        { image: { $regex: 'placeholder', $options: 'i' } },
        { image: { $regex: 'unsplash', $options: 'i' } },
        { mobileImage: { $regex: 'placeholder', $options: 'i' } },
        { mobileImage: { $regex: 'unsplash', $options: 'i' } }
      ]
    });

    console.log(`✅ Deleted ${deleteResult.deletedCount} placeholder sliders\n`);

    // Show remaining sliders
    const remainingSliders = await Slider.find({});
    console.log(`📊 Remaining sliders: ${remainingSliders.length}`);
    if (remainingSliders.length > 0) {
      console.log('\n✅ Your real sliders:');
      remainingSliders.forEach((slider, index) => {
        console.log(`${index + 1}. ${slider.title}`);
        console.log(`   Image: ${slider.image}`);
        console.log(`   Active: ${slider.isActive}\n`);
      });
    }

    console.log('✅ Cleanup complete!');
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

// Run the cleanup
deletePlaceholderSliders();

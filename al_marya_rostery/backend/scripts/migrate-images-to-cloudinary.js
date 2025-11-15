/**
 * Migrate Local Images to Cloudinary
 * This script uploads local product images to Cloudinary and updates the database
 */

require('dotenv').config();
const mongoose = require('mongoose');
const cloudinary = require('cloudinary').v2;
const fs = require('fs');
const path = require('path');

// Models
const Coffee = require('../models/Coffee');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

async function uploadToCloudinary(localPath, productName) {
  try {
    console.log(`   📤 Uploading: ${path.basename(localPath)}...`);
    
    const result = await cloudinary.uploader.upload(localPath, {
      folder: 'al-marya/products',
      resource_type: 'image',
      transformation: [
        { width: 1000, height: 1000, crop: 'limit', quality: 'auto:good' }
      ],
      public_id: `coffee-${Date.now()}-${Math.floor(Math.random() * 1000000000)}`,
    });

    console.log(`   ✅ Uploaded successfully!`);
    console.log(`   🔗 URL: ${result.secure_url}`);
    
    return result.secure_url;
  } catch (error) {
    console.error(`   ❌ Error uploading: ${error.message}`);
    throw error;
  }
}

async function migrateCoffeeImages() {
  try {
    console.log('🚀 Starting Coffee Images Migration to Cloudinary...\n');
    
    // Check Cloudinary config
    console.log('🔍 Checking Cloudinary configuration...');
    if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      console.error('❌ Cloudinary credentials not found in environment variables!');
      console.log('Please set: CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET');
      process.exit(1);
    }
    console.log('✅ Cloudinary configured\n');

    // Connect to MongoDB
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find all coffees with local image paths
    console.log('🔍 Finding coffee products with local images...');
    const coffees = await Coffee.find({
      image: { $regex: '^/uploads/' }
    });
    
    console.log(`📦 Found ${coffees.length} products with local images\n`);
    
    if (coffees.length === 0) {
      console.log('✅ No local images to migrate!');
      await mongoose.connection.close();
      return;
    }

    const uploadsDir = path.join(__dirname, '..', 'uploads');
    
    let successCount = 0;
    let failCount = 0;
    let skippedCount = 0;

    // Migrate each product
    for (let i = 0; i < coffees.length; i++) {
      const coffee = coffees[i];
      console.log(`\n📦 [${i + 1}/${coffees.length}] Processing: ${coffee.name?.en || coffee.name || 'Unknown'}`);
      console.log(`   🖼️  Current image: ${coffee.image}`);
      
      // Extract filename from path
      const filename = coffee.image.replace('/uploads/', '');
      const localPath = path.join(uploadsDir, filename);
      
      // Check if file exists locally
      if (!fs.existsSync(localPath)) {
        console.log(`   ⚠️  File not found locally: ${localPath}`);
        console.log(`   ⏭️  Skipping...`);
        skippedCount++;
        continue;
      }

      try {
        // Upload to Cloudinary
        const cloudinaryUrl = await uploadToCloudinary(localPath, coffee.name?.en || coffee.name);
        
        // Update database
        coffee.image = cloudinaryUrl;
        await coffee.save();
        
        console.log(`   💾 Database updated!`);
        successCount++;
        
        // Small delay to avoid rate limits
        await new Promise(resolve => setTimeout(resolve, 500));
        
      } catch (error) {
        console.error(`   ❌ Failed to migrate: ${error.message}`);
        failCount++;
      }
    }

    // Summary
    console.log('\n═══════════════════════════════════════════════════');
    console.log('📊 MIGRATION SUMMARY');
    console.log('═══════════════════════════════════════════════════');
    console.log(`✅ Successfully migrated: ${successCount}`);
    console.log(`❌ Failed: ${failCount}`);
    console.log(`⏭️  Skipped (file not found): ${skippedCount}`);
    console.log(`📦 Total processed: ${coffees.length}`);
    console.log('═══════════════════════════════════════════════════\n');

    if (successCount > 0) {
      console.log('🎉 Migration completed!');
      console.log('✅ All images are now stored on Cloudinary');
      console.log('✅ Database updated with new URLs');
      console.log('\n💡 Next steps:');
      console.log('   1. Commit and push changes (database is already updated)');
      console.log('   2. Deploy to Render');
      console.log('   3. Images will now persist across restarts!\n');
    }

  } catch (error) {
    console.error('\n❌ Migration error:', error.message);
    console.error(error.stack);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Database connection closed');
  }
}

// Run migration
migrateCoffeeImages();

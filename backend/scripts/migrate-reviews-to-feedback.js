/**
 * Migration Script: Review Model → UserFeedback Model
 * 
 * Purpose: Migrate all reviews from the Review collection to UserFeedback collection
 * This consolidates two separate review systems into one unified system.
 * 
 * Usage:
 *   node backend/scripts/migrate-reviews-to-feedback.js [--dry-run] [--rollback]
 * 
 * Options:
 *   --dry-run   : Show what would be migrated without making changes
 *   --rollback  : Restore reviews from backup (if backup exists)
 */

const mongoose = require('mongoose');
const Review = require('../models/Review');
const UserFeedback = require('../models/UserFeedback');
const User = require('../models/User');
const Coffee = require('../models/Coffee');

// Load environment variables
require('dotenv').config();

// Parse command line arguments
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const isRollback = args.includes('--rollback');

// Migration statistics
const stats = {
  total: 0,
  migrated: 0,
  skipped: 0,
  failed: 0,
  errors: []
};

/**
 * Convert Firebase UID to MongoDB User ObjectId
 */
async function findUserByFirebaseUid(firebaseUid) {
  try {
    const user = await User.findOne({ firebaseUid });
    return user ? user._id : null;
  } catch (error) {
    console.warn(`⚠️  Could not find user for Firebase UID: ${firebaseUid}`);
    return null;
  }
}

/**
 * Convert productId (String) to Coffee ObjectId
 */
async function findProductById(productId) {
  try {
    // Try to find by MongoDB _id
    if (mongoose.Types.ObjectId.isValid(productId)) {
      const product = await Coffee.findById(productId);
      if (product) return product._id;
    }
    
    // Try to find by custom productId field
    const product = await Coffee.findOne({ productId });
    return product ? product._id : null;
  } catch (error) {
    console.warn(`⚠️  Could not find product for ID: ${productId}`);
    return null;
  }
}

/**
 * Map Review document to UserFeedback schema
 */
async function mapReviewToFeedback(review) {
  // Find user ObjectId from Firebase UID
  const userObjectId = await findUserByFirebaseUid(review.userId);
  
  // Find product ObjectId
  const productObjectId = await findProductById(review.productId);
  
  if (!userObjectId) {
    throw new Error(`User not found for Firebase UID: ${review.userId}`);
  }
  
  if (!productObjectId) {
    throw new Error(`Product not found for ID: ${review.productId}`);
  }
  
  // Map fields from Review to UserFeedback
  const feedbackData = {
    user: userObjectId,
    product: productObjectId,
    order: null, // Review model doesn't have order link
    rating: review.rating,
    title: review.title || `Review for ${review.productName}`,
    comment: review.comment,
    pros: [], // Review model doesn't have pros
    cons: [], // Review model doesn't have cons
    images: [], // Review model doesn't have images
    helpfulVotes: review.helpfulCount || 0,
    totalVotes: review.helpfulVotes?.length || 0,
    isVerifiedPurchase: review.isVerifiedPurchase || false,
    isApproved: review.status === 'approved', // Convert status to boolean
    moderationNotes: review.moderationNotes || '',
    isHidden: review.status === 'rejected' || review.status === 'flagged',
    tags: [],
    brewingMethod: null, // Review model doesn't have brewing method
    flavorProfile: {}, // Review model doesn't have flavor profile
    wouldRecommend: review.rating >= 4, // Assume 4+ stars means would recommend
    createdAt: review.createdAt,
    updatedAt: review.updatedAt
  };
  
  // Store original review ID for reference
  feedbackData.migrationData = {
    originalReviewId: review._id.toString(),
    migratedAt: new Date(),
    originalStatus: review.status
  };
  
  return feedbackData;
}

/**
 * Migrate a single review
 */
async function migrateReview(review) {
  try {
    // Check if already migrated
    const existing = await UserFeedback.findOne({
      'migrationData.originalReviewId': review._id.toString()
    });
    
    if (existing) {
      console.log(`⏭️  Skipping already migrated review: ${review._id}`);
      stats.skipped++;
      return;
    }
    
    // Map review to feedback format
    const feedbackData = await mapReviewToFeedback(review);
    
    if (isDryRun) {
      console.log(`\n🔍 DRY RUN - Would migrate review ${review._id}:`);
      console.log(`   Product: ${review.productName}`);
      console.log(`   User: ${review.userName} (${review.userEmail})`);
      console.log(`   Rating: ${review.rating}/5`);
      console.log(`   Status: ${review.status} → ${feedbackData.isApproved ? 'approved' : 'pending'}`);
      stats.migrated++;
      return;
    }
    
    // Create new UserFeedback document
    const feedback = new UserFeedback(feedbackData);
    await feedback.save();
    
    console.log(`✅ Migrated review ${review._id} → UserFeedback ${feedback._id}`);
    stats.migrated++;
    
  } catch (error) {
    console.error(`❌ Failed to migrate review ${review._id}:`, error.message);
    stats.failed++;
    stats.errors.push({
      reviewId: review._id,
      error: error.message
    });
  }
}

/**
 * Main migration function
 */
async function migrate() {
  console.log('\n🚀 Starting Review → UserFeedback Migration\n');
  console.log('━'.repeat(60));
  
  if (isDryRun) {
    console.log('🔍 DRY RUN MODE - No data will be modified');
  }
  
  console.log('━'.repeat(60) + '\n');
  
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('✅ Connected to MongoDB\n');
    
    // Fetch all reviews
    const reviews = await Review.find({}).sort({ createdAt: 1 });
    stats.total = reviews.length;
    
    console.log(`📊 Found ${stats.total} reviews to migrate\n`);
    
    if (stats.total === 0) {
      console.log('✨ No reviews found. Migration complete!');
      return;
    }
    
    // Migrate each review
    for (const review of reviews) {
      await migrateReview(review);
    }
    
    // Print summary
    console.log('\n' + '━'.repeat(60));
    console.log('📊 MIGRATION SUMMARY');
    console.log('━'.repeat(60));
    console.log(`Total Reviews:     ${stats.total}`);
    console.log(`✅ Migrated:       ${stats.migrated}`);
    console.log(`⏭️  Skipped:        ${stats.skipped} (already migrated)`);
    console.log(`❌ Failed:         ${stats.failed}`);
    console.log('━'.repeat(60));
    
    if (stats.errors.length > 0) {
      console.log('\n⚠️  ERRORS:\n');
      stats.errors.forEach(err => {
        console.log(`   Review ID: ${err.reviewId}`);
        console.log(`   Error: ${err.error}\n`);
      });
    }
    
    if (!isDryRun && stats.failed === 0) {
      console.log('\n✨ Migration completed successfully!\n');
      console.log('📝 Next Steps:');
      console.log('   1. Update admin panel to use /api/feedback');
      console.log('   2. Update Flutter app to use /api/feedback');
      console.log('   3. Test the migrated data');
      console.log('   4. Deprecate /api/reviews endpoint');
      console.log('   5. Remove Review model (keep for reference)\n');
    } else if (isDryRun) {
      console.log('\n✅ Dry run completed. Run without --dry-run to perform migration.\n');
    }
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
    console.log('👋 Disconnected from MongoDB\n');
  }
}

/**
 * Rollback migration (restore from backup if exists)
 */
async function rollback() {
  console.log('\n🔄 Starting Rollback...\n');
  console.log('⚠️  This will remove all migrated UserFeedback entries\n');
  
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    
    // Find all migrated feedback entries
    const result = await UserFeedback.deleteMany({
      'migrationData.originalReviewId': { $exists: true }
    });
    
    console.log(`✅ Removed ${result.deletedCount} migrated UserFeedback entries`);
    console.log('💡 Original Review documents remain intact\n');
    
  } catch (error) {
    console.error('❌ Rollback failed:', error);
    process.exit(1);
  } finally {
    await mongoose.connection.close();
  }
}

// Run migration or rollback
if (isRollback) {
  rollback();
} else {
  migrate();
}

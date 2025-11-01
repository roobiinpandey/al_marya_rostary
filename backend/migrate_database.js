const { MongoClient } = require('mongodb');

// OLD cluster (roobiinpandey) - has your data
const OLD_URI = 'mongodb+srv://roobiinpandey_db_user:gkivlSlHR5ksH3ow@almaryarostery.2yel8zi.mongodb.net/al_marya_rostery?retryWrites=true&w=majority';

// NEW cluster (almaryarostery) - empty
const NEW_URI = 'mongodb+srv://almaryarostery_db_user:7eoKRRBXJvL6djto@almaryahrostery.xtoji5x.mongodb.net/al_marya_rostery?retryWrites=true&w=majority&appName=almaryahrostery';

const DATABASE_NAME = 'al_marya_rostery';

// Collections to migrate
const COLLECTIONS_TO_MIGRATE = [
  'coffees',
  'categories',
  'sliders',
  'subscriptions',
  'settings',
  'orders',
  'users',
  'reviews',
  'loyalty_transactions',
  'addresses',
  'contacts',
  'accessories',
  'accessory_categories'
];

async function migrateDatabase() {
  let oldClient, newClient;
  
  try {
    console.log('🔄 Starting Database Migration');
    console.log('================================');
    console.log('');
    
    // Connect to OLD cluster
    console.log('📡 Connecting to OLD cluster (roobiinpandey)...');
    oldClient = new MongoClient(OLD_URI);
    await oldClient.connect();
    console.log('✅ Connected to OLD cluster');
    
    // Connect to NEW cluster
    console.log('📡 Connecting to NEW cluster (almaryarostery)...');
    newClient = new MongoClient(NEW_URI);
    await newClient.connect();
    console.log('✅ Connected to NEW cluster');
    console.log('');
    
    const oldDb = oldClient.db(DATABASE_NAME);
    const newDb = newClient.db(DATABASE_NAME);
    
    // Get all collections from old database
    const existingCollections = await oldDb.listCollections().toArray();
    const existingCollectionNames = existingCollections.map(c => c.name);
    
    console.log(`📂 Found ${existingCollectionNames.length} collections in OLD database`);
    console.log('Collections:', existingCollectionNames.join(', '));
    console.log('');
    
    let totalDocsMigrated = 0;
    let successCount = 0;
    let skippedCount = 0;
    
    // Migrate each collection
    for (const collectionName of COLLECTIONS_TO_MIGRATE) {
      try {
        // Check if collection exists in old database
        if (!existingCollectionNames.includes(collectionName)) {
          console.log(`⏭️  Skipping ${collectionName} (doesn't exist in old DB)`);
          skippedCount++;
          continue;
        }
        
        const oldCollection = oldDb.collection(collectionName);
        const newCollection = newDb.collection(collectionName);
        
        // Get all documents from old collection
        const documents = await oldCollection.find({}).toArray();
        
        if (documents.length === 0) {
          console.log(`⏭️  Skipping ${collectionName} (empty collection)`);
          skippedCount++;
          continue;
        }
        
        console.log(`📦 Migrating ${collectionName}...`);
        console.log(`   Documents to migrate: ${documents.length}`);
        
        // Clear existing data in new collection (optional)
        const existingCount = await newCollection.countDocuments();
        if (existingCount > 0) {
          console.log(`   ⚠️  Collection has ${existingCount} existing documents`);
          console.log(`   Clearing existing data...`);
          await newCollection.deleteMany({});
        }
        
        // Insert documents into new collection
        const result = await newCollection.insertMany(documents);
        console.log(`   ✅ Migrated ${result.insertedCount} documents`);
        
        totalDocsMigrated += result.insertedCount;
        successCount++;
        
      } catch (error) {
        console.error(`   ❌ Error migrating ${collectionName}:`, error.message);
      }
      
      console.log('');
    }
    
    // Summary
    console.log('================================');
    console.log('🎉 Migration Complete!');
    console.log('================================');
    console.log(`✅ Collections migrated: ${successCount}`);
    console.log(`⏭️  Collections skipped: ${skippedCount}`);
    console.log(`📊 Total documents migrated: ${totalDocsMigrated}`);
    console.log('');
    
    // Verify migration
    console.log('🔍 Verifying migration...');
    for (const collectionName of COLLECTIONS_TO_MIGRATE) {
      if (!existingCollectionNames.includes(collectionName)) continue;
      
      const oldCount = await oldDb.collection(collectionName).countDocuments();
      const newCount = await newDb.collection(collectionName).countDocuments();
      
      if (oldCount === newCount && oldCount > 0) {
        console.log(`   ✅ ${collectionName}: ${newCount} documents (matches old DB)`);
      } else if (oldCount === 0) {
        console.log(`   ⏭️  ${collectionName}: empty in both databases`);
      } else {
        console.log(`   ⚠️  ${collectionName}: OLD=${oldCount}, NEW=${newCount} (mismatch!)`);
      }
    }
    
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    console.error(error);
    process.exit(1);
  } finally {
    // Close connections
    if (oldClient) {
      await oldClient.close();
      console.log('');
      console.log('📴 Disconnected from OLD cluster');
    }
    if (newClient) {
      await newClient.close();
      console.log('📴 Disconnected from NEW cluster');
    }
  }
}

// Run migration
console.log('');
console.log('🚀 Al Marya Rostery Database Migration Tool');
console.log('===========================================');
console.log('');
console.log('FROM: almaryarostery.2yel8zi.mongodb.net (roobiinpandey)');
console.log('TO:   almaryahrostery.xtoji5x.mongodb.net (almaryarostery)');
console.log('');
console.log('⚠️  WARNING: This will REPLACE all data in the NEW database!');
console.log('');
console.log('Starting migration in 3 seconds...');
console.log('Press Ctrl+C to cancel');
console.log('');

setTimeout(() => {
  migrateDatabase().catch(console.error);
}, 3000);

const mongoose = require('mongoose');
require('dotenv').config();

const testConnection = async () => {
  try {
    console.log('🔄 Testing MongoDB connection...');

    // First try without database name
    const baseURI = '***REMOVED******REMOVED***:spjIBzJO1V4hZxPo@***REMOVED***.ph5cazq.mongodb.net/?retryWrites=true&w=majority&appName=***REMOVED***';
    console.log('Connection string (masked):', baseURI.replace(/:([^:@]{4})[^:@]*@/, ':****@'));

    await mongoose.connect(baseURI);

    console.log('✅ MongoDB Connected Successfully!');
    console.log('📊 Available databases:');

    // List available databases
    const adminDb = mongoose.connection.db.admin();
    const databases = await adminDb.listDatabases();
    databases.databases.forEach(db => {
      console.log(`  - ${db.name}`);
    });

    // Try to create/use our database
    const ourDb = mongoose.connection.useDb('qahwat_al_emarat');
    console.log('📊 Using database: qahwat_al_emarat');

    // Test creating a simple document
    const Test = ourDb.model('Test', { message: String }, 'tests');
    const testDoc = new Test({ message: 'Connection test successful!' });
    await testDoc.save();
    console.log('✅ Test document created in qahwat_al_emarat database');

    // Clean up
    await Test.deleteMany({});
    console.log('✅ Test cleanup completed');

    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');

  } catch (error) {
    console.error('❌ MongoDB Connection Failed:');
    console.error('Error:', error.message);

    if (error.message.includes('Authentication failed')) {
      console.log('\n� MongoDB Atlas Setup Steps:');
      console.log('1. Go to MongoDB Atlas Dashboard');
      console.log('2. Click "Database Access" in the left sidebar');
      console.log('3. Click "Add New Database User"');
      console.log('4. Create user: ***REMOVED***');
      console.log('5. Set password: spjIBzJO1V4hZxPo');
      console.log('6. Grant "Read and write" permissions');
      console.log('7. Click "Network Access" in left sidebar');
      console.log('8. Add IP Address: 0.0.0.0/0 (Allow Access from Anywhere)');
    }

    process.exit(1);
  }
};

testConnection();

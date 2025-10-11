const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
require('dotenv').config();

async function createProductionAdmin() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ MongoDB Connected Successfully');

        // Check if admin already exists
        const existingAdmin = await User.findOne({ email: 'almarya@admin' });
        if (existingAdmin) {
            console.log('⚠️ Production admin user already exists with email: almarya@admin');
            
            // Update password if needed
            const hashedPassword = await bcrypt.hash('almaryaadmin2020', 10);
            await User.findByIdAndUpdate(existingAdmin._id, {
                password: hashedPassword,
                roles: ['admin'],
                isActive: true,
                name: 'Al Marya Admin'
            });
            console.log('✅ Production admin credentials updated successfully');
        } else {
            // Create new production admin
            const hashedPassword = await bcrypt.hash('almaryaadmin2020', 10);
            
            const productionAdmin = new User({
                name: 'Al Marya Admin',
                email: 'almarya@admin',
                password: hashedPassword,
                roles: ['admin'],
                isActive: true,
                createdAt: new Date(),
                updatedAt: new Date()
            });

            await productionAdmin.save();
            console.log('✅ Production admin user created successfully');
            console.log('📧 Email: almarya@admin');
            console.log('🔒 Password: almaryaadmin2020');
            console.log('👤 Role: admin');
        }

        // Remove demo admin for production security
        const demoAdmin = await User.findOne({ email: 'admin@qahwat.com' });
        if (demoAdmin) {
            await User.findByIdAndDelete(demoAdmin._id);
            console.log('🗑️ Demo admin user removed for production security');
        }

        console.log('🎉 Production admin setup completed successfully!');
        
    } catch (error) {
        console.error('❌ Error creating production admin:', error);
    } finally {
        await mongoose.disconnect();
        console.log('📊 Database connection closed');
        process.exit(0);
    }
}

createProductionAdmin();

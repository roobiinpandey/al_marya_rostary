#!/usr/bin/env node
require('dotenv').config();
const mongoose = require('mongoose');
const Staff = require('./models/Staff');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    const count = await Staff.countDocuments({ isDeleted: false });
    const staff = await Staff.find({ isDeleted: false }).select('employeeId name email role');
    console.log(`\n📊 Total Staff in Database: ${count}\n`);
    if (count > 0) {
      staff.forEach(s => {
        console.log(`- ${s.employeeId}: ${s.name} (${s.email}) - ${s.role}`);
      });
    } else {
      console.log('No staff found in database.');
    }
    console.log('');
    await mongoose.disconnect();
    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
  });

require('dotenv').config();
const User = require('../models/User');

async function createTestUsers() {
  try {
    // Create regular customer user
    const existingCustomer = await User.findByEmail('customer@example.com');
    if (!existingCustomer) {
      await User.create({
        name: 'Customer User',
        email: 'customer@example.com',
        password: 'customer123',
        role: 'customer'
      });
      console.log('✅ Customer user created successfully!');
    } else {
      console.log('✅ Customer user already exists');
    }

    // Create staff user
    const existingStaff = await User.findByEmail('staff@example.com');
    if (!existingStaff) {
      await User.create({
        name: 'Staff User',
        email: 'staff@example.com',
        password: 'staff123',
        role: 'staff'
      });
      console.log('✅ Staff user created successfully!');
    } else {
      console.log('✅ Staff user already exists');
    }

    console.log('\n📋 Test User Credentials:');
    console.log('Admin - Email: admin@example.com, Password: admin123');
    console.log('Staff - Email: staff@example.com, Password: staff123');
    console.log('Customer - Email: customer@example.com, Password: customer123');
    
  } catch (error) {
    console.error('❌ Error creating test users:', error.message);
  } finally {
    process.exit(0);
  }
}

createTestUsers();
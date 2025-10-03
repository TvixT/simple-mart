require('dotenv').config();
const User = require('../models/User');

async function checkAdminUser() {
  try {
    console.log('🔍 Checking admin user...');
    
    const adminUser = await User.findByEmail('admin@example.com');
    
    if (adminUser) {
      console.log('✅ Admin user found:');
      console.log('ID:', adminUser.id);
      console.log('Name:', adminUser.name);
      console.log('Email:', adminUser.email);
      console.log('Role:', adminUser.role);
      console.log('Created:', adminUser.created_at);
    } else {
      console.log('❌ Admin user not found');
    }

    // Also check with password for login verification
    const adminWithPassword = await User.findByEmailWithPassword('admin@example.com');
    if (adminWithPassword) {
      console.log('✅ Admin user with password found');
      console.log('Password hash exists:', !!adminWithPassword.password);
    }
    
  } catch (error) {
    console.error('❌ Error checking admin user:', error.message);
  } finally {
    process.exit(0);
  }
}

checkAdminUser();
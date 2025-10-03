require('dotenv').config();
const { promisePool } = require('../config/database');

async function listUsers() {
  try {
    const [users] = await promisePool.execute(
      'SELECT id, name, email, role, created_at FROM users ORDER BY id'
    );
    
    console.log('📋 Current users in database:');
    console.table(users);
    
    if (users.length === 0) {
      console.log('\n⚠️  No users found in database!');
      console.log('Run: node scripts/create-test-users.js to create test users');
    } else {
      console.log('\n🔑 Login Credentials:');
      users.forEach(user => {
        let defaultPassword = 'password123'; // default
        if (user.email.includes('admin')) defaultPassword = 'admin123';
        if (user.email.includes('staff')) defaultPassword = 'staff123';
        if (user.email.includes('customer')) defaultPassword = 'customer123';
        
        console.log(`${user.role.toUpperCase()}: ${user.email} / ${defaultPassword}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error listing users:', error.message);
  } finally {
    process.exit(0);
  }
}

listUsers();
require('dotenv').config();
const { promisePool } = require('../config/database');
const bcrypt = require('bcrypt');

async function setupUsersWithRoles() {
  try {
    console.log('🔧 Setting up users with roles...');
    
    // 1. Ensure role column exists
    const [columns] = await promisePool.execute(
      "SHOW COLUMNS FROM users LIKE 'role'"
    );

    if (columns.length === 0) {
      console.log('📝 Adding role column...');
      await promisePool.execute(
        "ALTER TABLE users ADD COLUMN role ENUM('customer', 'staff', 'admin') DEFAULT 'customer' AFTER password"
      );
      console.log('✅ Role column added');
    } else {
      console.log('✅ Role column exists');
    }

    // 2. Create test users with roles
    const testUsers = [
      {
        name: 'Admin User',
        email: 'admin@example.com',
        password: 'admin123',
        role: 'admin'
      },
      {
        name: 'Staff User',
        email: 'staff@example.com',
        password: 'staff123',
        role: 'staff'
      },
      {
        name: 'Customer User',
        email: 'customer@example.com',
        password: 'customer123',
        role: 'customer'
      }
    ];

    console.log('👥 Creating test users...');

    for (const userData of testUsers) {
      // Check if user exists
      const [existingUser] = await promisePool.execute(
        'SELECT id, role FROM users WHERE email = ?',
        [userData.email]
      );

      if (existingUser.length > 0) {
        // Update existing user's role
        await promisePool.execute(
          'UPDATE users SET role = ? WHERE email = ?',
          [userData.role, userData.email]
        );
        console.log(`✅ Updated ${userData.email} role to ${userData.role}`);
      } else {
        // Create new user
        const hashedPassword = await bcrypt.hash(userData.password, 10);
        await promisePool.execute(
          'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)',
          [userData.name, userData.email, hashedPassword, userData.role]
        );
        console.log(`✅ Created ${userData.email} with role ${userData.role}`);
      }
    }

    // 3. Display all users
    const [users] = await promisePool.execute(
      'SELECT id, name, email, role, created_at FROM users ORDER BY role DESC, id'
    );
    
    console.log('\n📋 Current users in database:');
    console.table(users);
    
    console.log('\n🔑 Login Credentials:');
    console.log('ADMIN  : admin@example.com / admin123');
    console.log('STAFF  : staff@example.com / staff123');  
    console.log('CUSTOMER: customer@example.com / customer123');
    
  } catch (error) {
    console.error('❌ Error setting up users:', error.message);
  } finally {
    process.exit(0);
  }
}

setupUsersWithRoles();
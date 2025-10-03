const { promisePool } = require('../config/database');

async function addRoleColumn() {
  try {
    // Check if role column exists
    const [columns] = await promisePool.execute(
      "SHOW COLUMNS FROM users LIKE 'role'"
    );

    if (columns.length === 0) {
      // Add role column to users table
      await promisePool.execute(
        "ALTER TABLE users ADD COLUMN role ENUM('customer', 'staff', 'admin') DEFAULT 'customer' AFTER password"
      );
      console.log('✅ Added role column to users table');
    } else {
      console.log('✅ Role column already exists');
    }

    // Update existing admin user to have admin role
    await promisePool.execute(
      "UPDATE users SET role = 'admin' WHERE email = 'admin@example.com'"
    );
    console.log('✅ Updated admin user role');

    // Show current users with roles
    const [users] = await promisePool.execute(
      'SELECT id, name, email, role FROM users'
    );
    console.log('\n📋 Current users:');
    console.table(users);

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
}

addRoleColumn();
const fs = require('fs');
const path = require('path');
const { promisePool } = require('../config/database');

/**
 * Initialize database by executing the schema SQL file
 */
async function initializeSchema() {
  try {
    console.log('Starting database schema initialization...');
    
    // Read the SQL schema file
    const schemaPath = path.join(__dirname, 'schema.sql');
    const sqlScript = fs.readFileSync(schemaPath, 'utf8');
    
    // Split SQL script into individual statements
    const statements = sqlScript
      .split(';')
      .map(stmt => stmt.trim())
      .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));
    
    // Execute each statement
    for (const statement of statements) {
      if (statement.trim()) {
        try {
          await promisePool.execute(statement);
          console.log('✅ Executed:', statement.substring(0, 50) + '...');
        } catch (error) {
          // Some statements might fail if tables already exist, that's okay
          if (!error.message.includes('already exists')) {
            console.log('⚠️  Warning:', error.message);
          }
        }
      }
    }

    // Run migrations to update existing schema
    await runMigrations();
    
    console.log('✅ Database schema initialization completed successfully!');
    return true;
  } catch (error) {
    console.error('❌ Error initializing database schema:', error.message);
    return false;
  }
}

/**
 * Run database migrations for schema updates
 */
async function runMigrations() {
  try {
    console.log('Running database migrations...');
    
    // Migration 1: Add role column to users table if it doesn't exist
    try {
      await promisePool.execute(`
        ALTER TABLE users 
        ADD COLUMN role ENUM('customer', 'staff', 'admin') DEFAULT 'customer'
      `);
      console.log('✅ Added role column to users table');
    } catch (error) {
      if (error.message.includes('Duplicate column name')) {
        console.log('✅ Role column already exists in users table');
      } else {
        console.log('⚠️  Migration warning:', error.message);
      }
    }

    // Migration 2: Add index for role column if it doesn't exist
    try {
      await promisePool.execute(`
        ALTER TABLE users ADD INDEX idx_role (role)
      `);
      console.log('✅ Added role index to users table');
    } catch (error) {
      if (error.message.includes('Duplicate key name')) {
        console.log('✅ Role index already exists in users table');
      } else {
        console.log('⚠️  Index warning:', error.message);
      }
    }

    console.log('✅ Database migrations completed successfully!');
  } catch (error) {
    console.error('❌ Error running migrations:', error.message);
  }
}

/**
 * Verify database structure by checking if all required tables exist
 */
async function verifyDatabaseStructure() {
  try {
    console.log('Verifying database structure...');
    
    const requiredTables = ['users', 'products', 'cart', 'orders', 'order_items', 'categories'];
    const [tables] = await promisePool.execute('SHOW TABLES');
    
    const existingTables = tables.map(row => Object.values(row)[0]);
    
    for (const table of requiredTables) {
      if (existingTables.includes(table)) {
        console.log(`✅ Table '${table}' exists`);
      } else {
        console.log(`❌ Table '${table}' is missing`);
        return false;
      }
    }
    
    console.log('✅ All required tables exist!');
    return true;
  } catch (error) {
    console.error('❌ Error verifying database structure:', error.message);
    return false;
  }
}

/**
 * Get database statistics
 */
async function getDatabaseStats() {
  try {
    const stats = {};
    
    const tables = ['users', 'products', 'cart', 'orders', 'order_items', 'categories'];
    
    for (const table of tables) {
      try {
        const [rows] = await promisePool.execute(`SELECT COUNT(*) as count FROM ${table}`);
        stats[table] = rows[0].count;
      } catch (error) {
        stats[table] = 'Error';
      }
    }
    
    return stats;
  } catch (error) {
    console.error('Error getting database stats:', error.message);
    return {};
  }
}

module.exports = {
  initializeSchema,
  runMigrations,
  verifyDatabaseStructure,
  getDatabaseStats
};
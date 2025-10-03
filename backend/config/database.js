const mysql = require('mysql2');
require('dotenv').config();

// Create a connection pool for better performance
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'simple_mart_db',
  port: process.env.DB_PORT || 3306,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
});

// Create a promise-based pool for async/await usage
const promisePool = pool.promise();

// Test the connection
async function testConnection() {
  try {
    const connection = await promisePool.getConnection();
    console.log('Successfully connected to MySQL database');
    connection.release();
    return true;
  } catch (error) {
    console.error('Error connecting to MySQL database:', error.message);
    return false;
  }
}

// Initialize database (create database if it doesn't exist)
async function initializeDatabase() {
  try {
    // Create a connection without specifying database
    const initPool = mysql.createPool({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      port: process.env.DB_PORT || 3306
    });
    
    const initPromisePool = initPool.promise();
    
    // Create database if it doesn't exist
    await initPromisePool.execute(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME || 'simple_mart_db'}`);
    console.log(`Database '${process.env.DB_NAME || 'simple_mart_db'}' initialized successfully`);
    
    initPool.end();
  } catch (error) {
    console.error('Error initializing database:', error.message);
    throw error;
  }
}

// Initialize database schema with tables
async function initializeSchema() {
  try {
    console.log('Starting database schema initialization...');
    
    // Create tables if they don't exist (preserves existing data)
    const createQueries = [
      // Users table with role column
      `CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(150) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        role ENUM('admin', 'staff', 'customer') NOT NULL DEFAULT 'customer',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        INDEX idx_email (email)
      )`,

      // Categories table
      `CREATE TABLE IF NOT EXISTS categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )`,

      // Products table
      `CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(200) NOT NULL,
        description TEXT,
        price DECIMAL(10, 2) NOT NULL,
        stock INT NOT NULL DEFAULT 0,
        image_url VARCHAR(500),
        category_id INT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL,
        INDEX idx_category (category_id),
        INDEX idx_price (price)
      )`,

      // Cart table
      `CREATE TABLE IF NOT EXISTS cart (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        product_id INT NOT NULL,
        quantity INT NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        UNIQUE KEY unique_user_product (user_id, product_id),
        INDEX idx_user (user_id)
      )`,

      // Orders table
      `CREATE TABLE IF NOT EXISTS orders (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        total_price DECIMAL(10, 2) NOT NULL,
        status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
        shipping_address TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user (user_id),
        INDEX idx_status (status),
        INDEX idx_created (created_at)
      )`,

      // Order items table
      `CREATE TABLE IF NOT EXISTS order_items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        order_id INT NOT NULL,
        product_id INT NOT NULL,
        quantity INT NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
        INDEX idx_order (order_id)
      )`
    ];

    for (const query of createQueries) {
      await promisePool.execute(query);
    }

    // Add role column to existing users table if it doesn't exist
    try {
      await promisePool.execute(`
        ALTER TABLE users 
        ADD COLUMN role ENUM('admin', 'staff', 'customer') NOT NULL DEFAULT 'customer'
      `);
      console.log('✅ Added role column to users table');
    } catch (error) {
      if (error.code === 'ER_DUP_FIELDNAME') {
        console.log('ℹ️  Role column already exists in users table');
      } else {
        console.log('⚠️  Warning adding role column:', error.message);
      }
    }

    console.log('✅ Database schema initialization completed successfully!');
  } catch (error) {
    console.error('❌ Error initializing database schema:', error.message);
    throw error;
  }
}

// Verify database structure
async function verifySchema() {
  try {
    console.log('Verifying database structure...');
    const tables = ['users', 'categories', 'products', 'cart', 'orders', 'order_items'];
    
    for (const table of tables) {
      const [rows] = await promisePool.execute(`SHOW TABLES LIKE '${table}'`);
      if (rows.length === 0) {
        console.log(`❌ Table '${table}' is missing`);
      } else {
        console.log(`✅ Table '${table}' exists`);
      }
    }
  } catch (error) {
    console.error('Error verifying schema:', error.message);
  }
}

module.exports = {
  pool,
  promisePool,
  testConnection,
  initializeDatabase,
  initializeSchema,
  verifySchema
};
-- Simple Mart Database Schema
-- Created: October 2025
-- Description: Complete database schema for Simple Mart e-commerce application

-- Use the simple_mart database
USE simple_mart_db;

-- Create Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('customer', 'staff', 'admin') DEFAULT 'customer',
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_created_at (created_at)
);

-- Create Products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    image_url VARCHAR(500),
    category VARCHAR(50),
    brand VARCHAR(100),
    weight DECIMAL(8, 2),
    dimensions VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_name (name),
    INDEX idx_price (price),
    INDEX idx_category (category),
    INDEX idx_stock (stock),
    INDEX idx_is_active (is_active)
);

-- Create Cart table
CREATE TABLE IF NOT EXISTS cart (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_product (user_id, product_id),
    INDEX idx_user_id (user_id),
    INDEX idx_product_id (product_id)
);

-- Create Orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_price DECIMAL(12, 2) NOT NULL,
    status ENUM('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'failed', 'refunded') DEFAULT 'pending',
    payment_method VARCHAR(50),
    shipping_address TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_payment_status (payment_status)
);

-- Create Order Items table (junction table for orders and products)
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(12, 2) NOT NULL,
    
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT,
    INDEX idx_order_id (order_id),
    INDEX idx_product_id (product_id)
);

-- Create Categories table (for future expansion)
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_id INT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL,
    INDEX idx_name (name),
    INDEX idx_parent_id (parent_id)
);

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
('Electronics', 'Electronic devices and accessories'),
('Clothing', 'Clothing and fashion items'),
('Books', 'Books and educational materials'),
('Home & Garden', 'Home improvement and garden supplies'),
('Sports', 'Sports equipment and accessories')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- Insert sample users (for testing purposes)
INSERT INTO users (name, email, password, phone, address) VALUES
('John Doe', 'john@example.com', '$2b$10$example_hashed_password', '+1234567890', '123 Main St, City, State'),
('Jane Smith', 'jane@example.com', '$2b$10$example_hashed_password', '+1234567891', '456 Oak Ave, City, State'),
('Admin User', 'admin@simplemart.com', '$2b$10$example_hashed_password', '+1234567892', '789 Admin Blvd, City, State')
ON DUPLICATE KEY UPDATE name = VALUES(name);

-- Insert sample products
INSERT INTO products (name, description, price, stock, image_url, category, brand) VALUES
('Wireless Headphones', 'High-quality wireless headphones with noise cancellation', 99.99, 50, '/images/headphones.jpg', 'Electronics', 'TechBrand'),
('Cotton T-Shirt', 'Comfortable 100% cotton t-shirt in various colors', 19.99, 100, '/images/tshirt.jpg', 'Clothing', 'FashionCo'),
('Programming Book', 'Complete guide to modern web development', 39.99, 30, '/images/book.jpg', 'Books', 'TechPublisher'),
('Garden Tools Set', 'Complete set of essential garden tools', 79.99, 25, '/images/garden-tools.jpg', 'Home & Garden', 'GardenPro'),
('Running Shoes', 'Professional running shoes for athletes', 129.99, 40, '/images/shoes.jpg', 'Sports', 'SportsBrand')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- Create indexes for better performance
CREATE INDEX idx_products_price_stock ON products(price, stock);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_cart_user_added ON cart(user_id, added_at);

-- Create views for common queries
CREATE OR REPLACE VIEW active_products AS
SELECT * FROM products WHERE is_active = TRUE AND stock > 0;

CREATE OR REPLACE VIEW user_cart_details AS
SELECT 
    c.id as cart_id,
    c.user_id,
    c.product_id,
    c.quantity,
    p.name as product_name,
    p.price as unit_price,
    (c.quantity * p.price) as total_price,
    p.stock,
    c.added_at
FROM cart c
JOIN products p ON c.product_id = p.id
WHERE p.is_active = TRUE;

CREATE OR REPLACE VIEW order_summary AS
SELECT 
    o.id as order_id,
    o.user_id,
    u.name as user_name,
    u.email as user_email,
    o.total_price,
    o.status,
    o.payment_status,
    o.created_at,
    COUNT(oi.id) as item_count
FROM orders o
JOIN users u ON o.user_id = u.id
LEFT JOIN order_items oi ON o.id = oi.order_id
GROUP BY o.id, o.user_id, u.name, u.email, o.total_price, o.status, o.payment_status, o.created_at;

-- Show table creation results
SHOW TABLES;

-- Show table structures
DESCRIBE users;
DESCRIBE products;
DESCRIBE cart;
DESCRIBE orders;
DESCRIBE order_items;
DESCRIBE categories;
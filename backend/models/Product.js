const { promisePool } = require('../config/database');

class Product {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description;
    this.price = parseFloat(data.price);
    this.stock = data.stock;
    this.image_url = data.image_url;
    this.category_id = data.category_id;
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create a new product
  static async create(productData) {
    try {
      const { name, description, price, stock, image_url, category_id } = productData;

      const [result] = await promisePool.execute(
        'INSERT INTO products (name, description, price, stock, image_url, category_id) VALUES (?, ?, ?, ?, ?, ?)',
        [name, description, price, stock, image_url, category_id]
      );

      return await Product.findById(result.insertId);
    } catch (error) {
      throw error;
    }
  }

  // Find product by ID
  static async findById(id) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT p.*, c.name as category_name 
         FROM products p 
         LEFT JOIN categories c ON p.category_id = c.id 
         WHERE p.id = ?`,
        [id]
      );

      if (rows.length === 0) {
        return null;
      }

      return new Product(rows[0]);
    } catch (error) {
      throw error;
    }
  }

  // Get all products with filters and pagination
  static async findAll(options = {}) {
    try {
      const {
        page = 1,
        limit = 10,
        category_id,
        search,
        min_price,
        max_price,
        in_stock_only = false,
        sort_by = 'created_at',
        sort_order = 'DESC'
      } = options;

      const offset = (page - 1) * limit;
      let whereClause = '1=1';
      const params = [];

      // Build WHERE clause
      if (category_id) {
        whereClause += ' AND p.category_id = ?';
        params.push(category_id);
      }

      if (search) {
        whereClause += ' AND (p.name LIKE ? OR p.description LIKE ?)';
        params.push(`%${search}%`, `%${search}%`);
      }

      if (min_price) {
        whereClause += ' AND p.price >= ?';
        params.push(min_price);
      }

      if (max_price) {
        whereClause += ' AND p.price <= ?';
        params.push(max_price);
      }

      if (in_stock_only) {
        whereClause += ' AND p.stock > 0';
      }

      // Validate sort fields
      const validSortFields = ['name', 'price', 'stock', 'created_at'];
      const sortField = validSortFields.includes(sort_by) ? sort_by : 'created_at';
      const sortDirection = sort_order.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

      const query = `
        SELECT p.*, c.name as category_name 
        FROM products p 
        LEFT JOIN categories c ON p.category_id = c.id 
        WHERE ${whereClause} 
        ORDER BY p.${sortField} ${sortDirection} 
        LIMIT ? OFFSET ?
      `;

      const [rows] = await promisePool.execute(query, [...params, limit, offset]);

      // Get total count
      const countQuery = `
        SELECT COUNT(*) as total 
        FROM products p 
        WHERE ${whereClause}
      `;
      const [countResult] = await promisePool.execute(countQuery, params);

      const products = rows.map(row => new Product(row));
      const total = countResult[0].total;
      const totalPages = Math.ceil(total / limit);

      return {
        products,
        pagination: {
          currentPage: page,
          totalPages,
          totalProducts: total,
          hasNext: page < totalPages,
          hasPrev: page > 1
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Update product
  static async update(id, productData) {
    try {
      const { name, description, price, stock, image_url, category_id } = productData;
      
      await promisePool.execute(
        'UPDATE products SET name = ?, description = ?, price = ?, stock = ?, image_url = ?, category_id = ?, updated_at = NOW() WHERE id = ?',
        [name, description, price, stock, image_url, category_id, id]
      );

      return await Product.findById(id);
    } catch (error) {
      throw error;
    }
  }

  // Update stock quantity
  static async updateStock(id, quantity, operation = 'set') {
    try {
      let query;
      let params;

      switch (operation) {
        case 'add':
          query = 'UPDATE products SET stock = stock + ?, updated_at = NOW() WHERE id = ?';
          params = [quantity, id];
          break;
        case 'subtract':
          query = 'UPDATE products SET stock = GREATEST(0, stock - ?), updated_at = NOW() WHERE id = ?';
          params = [quantity, id];
          break;
        case 'set':
        default:
          query = 'UPDATE products SET stock = ?, updated_at = NOW() WHERE id = ?';
          params = [quantity, id];
          break;
      }

      await promisePool.execute(query, params);
      return await Product.findById(id);
    } catch (error) {
      throw error;
    }
  }

  // Check if product has sufficient stock
  static async checkStock(id, requiredQuantity) {
    try {
      const [rows] = await promisePool.execute(
        'SELECT stock FROM products WHERE id = ?',
        [id]
      );

      if (rows.length === 0) {
        return { available: false, error: 'Product not found' };
      }

      const currentStock = rows[0].stock;
      return {
        available: currentStock >= requiredQuantity,
        currentStock,
        requiredQuantity
      };
    } catch (error) {
      throw error;
    }
  }

  // Delete product
  static async delete(id) {
    try {
      const [result] = await promisePool.execute(
        'DELETE FROM products WHERE id = ?',
        [id]
      );

      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Get products by category
  static async findByCategory(categoryId, page = 1, limit = 10) {
    try {
      return await Product.findAll({
        page,
        limit,
        category_id: categoryId
      });
    } catch (error) {
      throw error;
    }
  }

  // Search products
  static async search(searchTerm, page = 1, limit = 10) {
    try {
      return await Product.findAll({
        page,
        limit,
        search: searchTerm
      });
    } catch (error) {
      throw error;
    }
  }

  // Get low stock products
  static async getLowStock(threshold = 10) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT p.*, c.name as category_name 
         FROM products p 
         LEFT JOIN categories c ON p.category_id = c.id 
         WHERE p.stock <= ? 
         ORDER BY p.stock ASC`,
        [threshold]
      );

      return rows.map(row => new Product(row));
    } catch (error) {
      throw error;
    }
  }

  // Get featured products (you can customize the criteria)
  static async getFeatured(limit = 8) {
    try {
      const [rows] = await promisePool.execute(
        `SELECT p.*, c.name as category_name 
         FROM products p 
         LEFT JOIN categories c ON p.category_id = c.id 
         WHERE p.stock > 0 
         ORDER BY p.created_at DESC 
         LIMIT ?`,
        [limit]
      );

      return rows.map(row => new Product(row));
    } catch (error) {
      throw error;
    }
  }

  // Get product statistics
  static async getStats() {
    try {
      const [results] = await promisePool.execute(`
        SELECT 
          COUNT(*) as total_products,
          COUNT(CASE WHEN stock > 0 THEN 1 END) as in_stock_products,
          COUNT(CASE WHEN stock = 0 THEN 1 END) as out_of_stock_products,
          AVG(price) as average_price,
          SUM(stock) as total_stock
        FROM products
      `);

      return results[0];
    } catch (error) {
      throw error;
    }
  }

  // Check if product is in stock
  isInStock() {
    return this.stock > 0;
  }

  // Get formatted price
  getFormattedPrice(currency = '$') {
    return `${currency}${this.price.toFixed(2)}`;
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      price: this.price,
      stock: this.stock,
      image_url: this.image_url,
      category_id: this.category_id,
      in_stock: this.isInStock(),
      formatted_price: this.getFormattedPrice(),
      created_at: this.created_at,
      updated_at: this.updated_at
    };
  }
}

module.exports = Product;
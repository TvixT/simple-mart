const { promisePool } = require('../config/database');

class Category {
  constructor(data) {
    this.id = data.id;
    this.name = data.name;
    this.description = data.description || '';
    this.created_at = data.created_at;
    this.updated_at = data.updated_at;
  }

  // Create a new category
  static async create(categoryData) {
    try {
      const { name, description = '' } = categoryData;

      const [result] = await promisePool.execute(
        'INSERT INTO categories (name, description) VALUES (?, ?)',
        [name, description]
      );

      // Return the created category
      return await Category.findById(result.insertId);
    } catch (error) {
      throw error;
    }
  }

  // Find category by ID
  static async findById(id) {
    try {
      const [rows] = await promisePool.execute(
        'SELECT * FROM categories WHERE id = ?',
        [id]
      );

      if (rows.length === 0) {
        return null;
      }

      return new Category(rows[0]);
    } catch (error) {
      throw error;
    }
  }

  // Get all categories with pagination
  static async getAll(options = {}) {
    try {
      const {
        page = 1,
        limit = 50,
        sortBy = 'name',
        sortOrder = 'ASC',
        search = ''
      } = options;

      const offset = (page - 1) * limit;
      let whereClause = '';
      let queryParams = [];

      // Add search functionality
      if (search) {
        whereClause = 'WHERE name LIKE ? OR description LIKE ?';
        queryParams.push(`%${search}%`, `%${search}%`);
      }

      // Validate sort parameters
      const allowedSortFields = ['name', 'description', 'created_at'];
      const sortField = allowedSortFields.includes(sortBy) ? sortBy : 'name';
      const order = sortOrder.toUpperCase() === 'DESC' ? 'DESC' : 'ASC';

      const query = `
        SELECT * FROM categories 
        ${whereClause}
        ORDER BY ${sortField} ${order}
        LIMIT ? OFFSET ?
      `;

      queryParams.push(limit, offset);

      const [rows] = await promisePool.execute(query, queryParams);

      // Get total count for pagination
      const countQuery = `SELECT COUNT(*) as total FROM categories ${whereClause}`;
      const countParams = search ? [`%${search}%`, `%${search}%`] : [];
      const [countRows] = await promisePool.execute(countQuery, countParams);
      const total = countRows[0].total;

      return {
        categories: rows.map(row => new Category(row)),
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(total / limit),
          totalItems: total,
          hasNextPage: page < Math.ceil(total / limit),
          hasPrevPage: page > 1
        }
      };
    } catch (error) {
      throw error;
    }
  }

  // Update category
  static async update(id, updateData) {
    try {
      const { name, description } = updateData;
      
      // Build dynamic update query
      const updates = [];
      const values = [];

      if (name !== undefined) {
        updates.push('name = ?');
        values.push(name);
      }

      if (description !== undefined) {
        updates.push('description = ?');
        values.push(description);
      }

      if (updates.length === 0) {
        throw new Error('No fields to update');
      }

      values.push(id);

      const query = `UPDATE categories SET ${updates.join(', ')} WHERE id = ?`;

      const [result] = await promisePool.execute(query, values);

      if (result.affectedRows === 0) {
        return null;
      }

      // Return updated category
      return await Category.findById(id);
    } catch (error) {
      throw error;
    }
  }

  // Delete category
  static async delete(id) {
    try {
      // Check if category has products
      const [productRows] = await promisePool.execute(
        'SELECT COUNT(*) as count FROM products WHERE category_id = ?',
        [id]
      );

      const productCount = productRows[0].count;

      if (productCount > 0) {
        // Option 1: Prevent deletion if products exist
        throw new Error(`Cannot delete category. ${productCount} products are assigned to this category.`);
        
        // Option 2: Set products category_id to NULL (uncomment if preferred)
        // await promisePool.execute(
        //   'UPDATE products SET category_id = NULL WHERE category_id = ?',
        //   [id]
        // );
      }

      const [result] = await promisePool.execute(
        'DELETE FROM categories WHERE id = ?',
        [id]
      );

      return result.affectedRows > 0;
    } catch (error) {
      throw error;
    }
  }

  // Get category with product count
  static async findByIdWithProductCount(id) {
    try {
      const [rows] = await promisePool.execute(`
        SELECT c.*, COUNT(p.id) as product_count 
        FROM categories c 
        LEFT JOIN products p ON c.id = p.category_id 
        WHERE c.id = ? 
        GROUP BY c.id
      `, [id]);

      if (rows.length === 0) {
        return null;
      }

      const category = new Category(rows[0]);
      category.product_count = rows[0].product_count;
      return category;
    } catch (error) {
      throw error;
    }
  }

  // Get all categories with product counts
  static async getAllWithProductCounts() {
    try {
      const [rows] = await promisePool.execute(`
        SELECT c.*, COUNT(p.id) as product_count 
        FROM categories c 
        LEFT JOIN products p ON c.id = p.category_id 
        GROUP BY c.id 
        ORDER BY c.name ASC
      `);

      return rows.map(row => {
        const category = new Category(row);
        category.product_count = row.product_count;
        return category;
      });
    } catch (error) {
      throw error;
    }
  }

  // Search categories by name
  static async searchByName(searchTerm, limit = 10) {
    try {
      const [rows] = await promisePool.execute(
        'SELECT * FROM categories WHERE name LIKE ? ORDER BY name ASC LIMIT ?',
        [`%${searchTerm}%`, limit]
      );

      return rows.map(row => new Category(row));
    } catch (error) {
      throw error;
    }
  }

  // Convert to JSON
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      description: this.description,
      created_at: this.created_at,
      updated_at: this.updated_at,
      product_count: this.product_count || 0
    };
  }
}

module.exports = Category;
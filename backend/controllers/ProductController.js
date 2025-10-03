const Product = require('../models/Product');

class ProductController {
  // Get all products with filtering and pagination
  static async getProducts(req, res) {
    try {
      const {
        page = 1,
        limit = 10,
        category_id,
        search,
        min_price,
        max_price,
        in_stock_only,
        sort_by = 'created_at',
        sort_order = 'DESC'
      } = req.query;

      const options = {
        page: parseInt(page),
        limit: parseInt(limit),
        category_id: category_id ? parseInt(category_id) : undefined,
        search,
        min_price: min_price ? parseFloat(min_price) : undefined,
        max_price: max_price ? parseFloat(max_price) : undefined,
        in_stock_only: in_stock_only === 'true',
        sort_by,
        sort_order
      };

      const result = await Product.findAll(options);

      res.json({
        success: true,
        message: 'Products retrieved successfully',
        data: result
      });

    } catch (error) {
      console.error('Get products error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving products',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get single product by ID
  static async getProduct(req, res) {
    try {
      const { id } = req.params;

      if (!id || isNaN(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid product ID is required'
        });
      }

      const product = await Product.findById(parseInt(id));

      if (!product) {
        return res.status(404).json({
          success: false,
          message: 'Product not found'
        });
      }

      res.json({
        success: true,
        message: 'Product retrieved successfully',
        data: {
          product: product.toJSON()
        }
      });

    } catch (error) {
      console.error('Get product error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving product',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Create new product (admin only)
  static async createProduct(req, res) {
    try {
      const { name, description, price, stock, image_url, category_id } = req.body;

      // Validation
      if (!name || !price) {
        return res.status(400).json({
          success: false,
          message: 'Product name and price are required'
        });
      }

      if (price <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Price must be greater than 0'
        });
      }

      if (stock && stock < 0) {
        return res.status(400).json({
          success: false,
          message: 'Stock cannot be negative'
        });
      }

      const productData = {
        name,
        description: description || '',
        price: parseFloat(price),
        stock: stock ? parseInt(stock) : 0,
        image_url: image_url || null,
        category_id: category_id ? parseInt(category_id) : null
      };

      const product = await Product.create(productData);

      res.status(201).json({
        success: true,
        message: 'Product created successfully',
        data: {
          product: product.toJSON()
        }
      });

    } catch (error) {
      console.error('Create product error:', error);
      res.status(500).json({
        success: false,
        message: 'Error creating product',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Update product (admin only)
  static async updateProduct(req, res) {
    try {
      const { id } = req.params;
      const { name, description, price, stock, image_url, category_id } = req.body;

      if (!id || isNaN(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid product ID is required'
        });
      }

      // Check if product exists
      const existingProduct = await Product.findById(parseInt(id));
      if (!existingProduct) {
        return res.status(404).json({
          success: false,
          message: 'Product not found'
        });
      }

      // Validation
      if (price && price <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Price must be greater than 0'
        });
      }

      if (stock && stock < 0) {
        return res.status(400).json({
          success: false,
          message: 'Stock cannot be negative'
        });
      }

      const updateData = {
        name: name || existingProduct.name,
        description: description !== undefined ? description : existingProduct.description,
        price: price ? parseFloat(price) : existingProduct.price,
        stock: stock !== undefined ? parseInt(stock) : existingProduct.stock,
        image_url: image_url !== undefined ? image_url : existingProduct.image_url,
        category_id: category_id !== undefined ? (category_id ? parseInt(category_id) : null) : existingProduct.category_id
      };

      const updatedProduct = await Product.update(parseInt(id), updateData);

      res.json({
        success: true,
        message: 'Product updated successfully',
        data: {
          product: updatedProduct.toJSON()
        }
      });

    } catch (error) {
      console.error('Update product error:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating product',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Delete product (admin only)
  static async deleteProduct(req, res) {
    try {
      const { id } = req.params;

      if (!id || isNaN(id)) {
        return res.status(400).json({
          success: false,
          message: 'Valid product ID is required'
        });
      }

      // Check if product exists
      const existingProduct = await Product.findById(parseInt(id));
      if (!existingProduct) {
        return res.status(404).json({
          success: false,
          message: 'Product not found'
        });
      }

      const deleted = await Product.delete(parseInt(id));

      if (deleted) {
        res.json({
          success: true,
          message: 'Product deleted successfully'
        });
      } else {
        res.status(500).json({
          success: false,
          message: 'Failed to delete product'
        });
      }

    } catch (error) {
      console.error('Delete product error:', error);
      res.status(500).json({
        success: false,
        message: 'Error deleting product',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Search products
  static async searchProducts(req, res) {
    try {
      const { q: searchTerm, page = 1, limit = 10 } = req.query;

      if (!searchTerm) {
        return res.status(400).json({
          success: false,
          message: 'Search term is required'
        });
      }

      const result = await Product.search(searchTerm, parseInt(page), parseInt(limit));

      res.json({
        success: true,
        message: 'Search completed successfully',
        data: result
      });

    } catch (error) {
      console.error('Search products error:', error);
      res.status(500).json({
        success: false,
        message: 'Error searching products',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get products by category
  static async getProductsByCategory(req, res) {
    try {
      const { categoryId } = req.params;
      const { page = 1, limit = 10 } = req.query;

      if (!categoryId || isNaN(categoryId)) {
        return res.status(400).json({
          success: false,
          message: 'Valid category ID is required'
        });
      }

      const result = await Product.findByCategory(parseInt(categoryId), parseInt(page), parseInt(limit));

      res.json({
        success: true,
        message: 'Products retrieved successfully',
        data: result
      });

    } catch (error) {
      console.error('Get products by category error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving products by category',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get featured products
  static async getFeaturedProducts(req, res) {
    try {
      const { limit = 8 } = req.query;

      const products = await Product.getFeatured(parseInt(limit));

      res.json({
        success: true,
        message: 'Featured products retrieved successfully',
        data: {
          products: products.map(product => product.toJSON())
        }
      });

    } catch (error) {
      console.error('Get featured products error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving featured products',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get low stock products (admin only)
  static async getLowStockProducts(req, res) {
    try {
      const { threshold = 10 } = req.query;

      const products = await Product.getLowStock(parseInt(threshold));

      res.json({
        success: true,
        message: 'Low stock products retrieved successfully',
        data: {
          products: products.map(product => product.toJSON()),
          threshold: parseInt(threshold)
        }
      });

    } catch (error) {
      console.error('Get low stock products error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving low stock products',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }

  // Get product statistics (admin only)
  static async getProductStats(req, res) {
    try {
      const stats = await Product.getStats();

      res.json({
        success: true,
        message: 'Product statistics retrieved successfully',
        data: {
          statistics: stats
        }
      });

    } catch (error) {
      console.error('Get product stats error:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving product statistics',
        error: process.env.NODE_ENV === 'development' ? error.message : undefined
      });
    }
  }
}

module.exports = ProductController;
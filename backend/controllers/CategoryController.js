const Category = require('../models/Category');

class CategoryController {
  // Get all categories
  static async getCategories(req, res) {
    try {
      const {
        page = 1,
        limit = 50,
        sortBy = 'name',
        sortOrder = 'ASC',
        search = '',
        includeProductCount = false
      } = req.query;

      if (includeProductCount === 'true') {
        const categories = await Category.getAllWithProductCounts();
        return res.status(200).json({
          success: true,
          message: 'Categories retrieved successfully',
          data: {
            categories: categories.map(category => category.toJSON())
          }
        });
      }

      const result = await Category.getAll({
        page: parseInt(page),
        limit: parseInt(limit),
        sortBy,
        sortOrder,
        search
      });

      res.status(200).json({
        success: true,
        message: 'Categories retrieved successfully',
        data: {
          categories: result.categories.map(category => category.toJSON()),
          pagination: result.pagination
        }
      });
    } catch (error) {
      console.error('Error getting categories:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving categories',
        error: error.message
      });
    }
  }

  // Get single category by ID
  static async getCategoryById(req, res) {
    try {
      const { id } = req.params;
      const { includeProductCount = false } = req.query;

      let category;
      if (includeProductCount === 'true') {
        category = await Category.findByIdWithProductCount(id);
      } else {
        category = await Category.findById(id);
      }

      if (!category) {
        return res.status(404).json({
          success: false,
          message: 'Category not found'
        });
      }

      res.status(200).json({
        success: true,
        message: 'Category retrieved successfully',
        data: {
          category: category.toJSON()
        }
      });
    } catch (error) {
      console.error('Error getting category:', error);
      res.status(500).json({
        success: false,
        message: 'Error retrieving category',
        error: error.message
      });
    }
  }

  // Create new category (admin only)
  static async createCategory(req, res) {
    try {
      const { name, description } = req.body;

      // Validation
      if (!name || name.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Category name is required'
        });
      }

      if (name.trim().length < 2) {
        return res.status(400).json({
          success: false,
          message: 'Category name must be at least 2 characters long'
        });
      }

      if (name.trim().length > 100) {
        return res.status(400).json({
          success: false,
          message: 'Category name cannot exceed 100 characters'
        });
      }

      // Check if category with same name already exists
      const existingCategories = await Category.searchByName(name.trim());
      const exactMatch = existingCategories.find(cat => 
        cat.name.toLowerCase() === name.trim().toLowerCase()
      );

      if (exactMatch) {
        return res.status(400).json({
          success: false,
          message: 'A category with this name already exists'
        });
      }

      const category = await Category.create({
        name: name.trim(),
        description: description ? description.trim() : ''
      });

      res.status(201).json({
        success: true,
        message: 'Category created successfully',
        data: {
          category: category.toJSON()
        }
      });
    } catch (error) {
      console.error('Error creating category:', error);
      res.status(500).json({
        success: false,
        message: 'Error creating category',
        error: error.message
      });
    }
  }

  // Update category (admin only)
  static async updateCategory(req, res) {
    try {
      const { id } = req.params;
      const { name, description } = req.body;

      // Check if category exists
      const existingCategory = await Category.findById(id);
      if (!existingCategory) {
        return res.status(404).json({
          success: false,
          message: 'Category not found'
        });
      }

      // Validation
      if (name !== undefined) {
        if (!name || name.trim().length === 0) {
          return res.status(400).json({
            success: false,
            message: 'Category name cannot be empty'
          });
        }

        if (name.trim().length < 2) {
          return res.status(400).json({
            success: false,
            message: 'Category name must be at least 2 characters long'
          });
        }

        if (name.trim().length > 100) {
          return res.status(400).json({
            success: false,
            message: 'Category name cannot exceed 100 characters'
          });
        }

        // Check if another category with same name exists
        const existingCategories = await Category.searchByName(name.trim());
        const exactMatch = existingCategories.find(cat => 
          cat.name.toLowerCase() === name.trim().toLowerCase() && cat.id !== parseInt(id)
        );

        if (exactMatch) {
          return res.status(400).json({
            success: false,
            message: 'A category with this name already exists'
          });
        }
      }

      const updateData = {};
      if (name !== undefined) updateData.name = name.trim();
      if (description !== undefined) updateData.description = description ? description.trim() : '';

      const updatedCategory = await Category.update(id, updateData);

      if (!updatedCategory) {
        return res.status(404).json({
          success: false,
          message: 'Category not found'
        });
      }

      res.status(200).json({
        success: true,
        message: 'Category updated successfully',
        data: {
          category: updatedCategory.toJSON()
        }
      });
    } catch (error) {
      console.error('Error updating category:', error);
      res.status(500).json({
        success: false,
        message: 'Error updating category',
        error: error.message
      });
    }
  }

  // Delete category (admin only)
  static async deleteCategory(req, res) {
    try {
      const { id } = req.params;

      // Check if category exists
      const existingCategory = await Category.findById(id);
      if (!existingCategory) {
        return res.status(404).json({
          success: false,
          message: 'Category not found'
        });
      }

      const deleted = await Category.delete(id);

      if (!deleted) {
        return res.status(404).json({
          success: false,
          message: 'Category not found'
        });
      }

      res.status(200).json({
        success: true,
        message: 'Category deleted successfully',
        data: {
          deletedCategory: existingCategory.toJSON()
        }
      });
    } catch (error) {
      console.error('Error deleting category:', error);
      
      // Handle specific constraint errors
      if (error.message.includes('Cannot delete category')) {
        return res.status(400).json({
          success: false,
          message: error.message
        });
      }

      res.status(500).json({
        success: false,
        message: 'Error deleting category',
        error: error.message
      });
    }
  }

  // Search categories
  static async searchCategories(req, res) {
    try {
      const { q, limit = 10 } = req.query;

      if (!q || q.trim().length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Search query is required'
        });
      }

      const categories = await Category.searchByName(q.trim(), parseInt(limit));

      res.status(200).json({
        success: true,
        message: 'Categories search completed',
        data: {
          categories: categories.map(category => category.toJSON()),
          searchQuery: q.trim()
        }
      });
    } catch (error) {
      console.error('Error searching categories:', error);
      res.status(500).json({
        success: false,
        message: 'Error searching categories',
        error: error.message
      });
    }
  }
}

module.exports = CategoryController;
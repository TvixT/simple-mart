import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/product.dart';
import '../../models/category.dart' as category_model;

class EditProductScreen extends StatefulWidget {
  final Product product;
  
  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;
  
  category_model.Category? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current product data
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: widget.product.stockQuantity.toString());
    _imageUrlController = TextEditingController(text: widget.product.imageUrl ?? '');
    
    // Load categories and set selected category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      categoryProvider.fetchCategories().then((_) {
        if (widget.product.categoryId != null) {
          _selectedCategory = categoryProvider.getCategoryById(widget.product.categoryId!);
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user has management access
        if (!authProvider.hasManagementAccess) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
            ),
            body: const Center(
              child: Text(
                'You do not have permission to access this page.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Edit ${widget.product.name}'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Product Info Header
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Editing Product',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'ID: ${widget.product.id}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Product Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Product Name
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Product Name *',
                                    hintText: 'Enter product name',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Product name is required';
                                    }
                                    if (value.trim().length < 2) {
                                      return 'Product name must be at least 2 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Product Description
                                TextFormField(
                                  controller: _descriptionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    hintText: 'Enter product description',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  validator: (value) {
                                    // Description is optional, but if provided should have minimum length
                                    if (value != null && value.trim().isNotEmpty && value.trim().length < 10) {
                                      return 'Description should be at least 10 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Category Selection
                                Consumer<CategoryProvider>(
                                  builder: (context, categoryProvider, child) {
                                    if (categoryProvider.isLoading) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    if (categoryProvider.categories.isEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'No categories available. Please add categories first.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      );
                                    }

                                    return DropdownButtonFormField<category_model.Category>(
                                      decoration: const InputDecoration(
                                        labelText: 'Category *',
                                        hintText: 'Select a category',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: _selectedCategory,
                                      items: categoryProvider.categories.map((category) {
                                        return DropdownMenuItem<category_model.Category>(
                                          value: category,
                                          child: Text(category.name),
                                        );
                                      }).toList(),
                                      onChanged: (category_model.Category? newValue) {
                                        setState(() {
                                          _selectedCategory = newValue;
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Please select a category';
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                
                                // Price and Stock Row
                                Row(
                                  children: [
                                    // Price
                                    Expanded(
                                      child: TextFormField(
                                        controller: _priceController,
                                        decoration: const InputDecoration(
                                          labelText: 'Price (\$) *',
                                          hintText: '0.00',
                                          border: OutlineInputBorder(),
                                          prefixText: '\$ ',
                                        ),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                        ],
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Price is required';
                                          }
                                          final price = double.tryParse(value.trim());
                                          if (price == null || price <= 0) {
                                            return 'Enter a valid price greater than 0';
                                          }
                                          if (price > 999999.99) {
                                            return 'Price cannot exceed \$999,999.99';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // Stock Quantity
                                    Expanded(
                                      child: TextFormField(
                                        controller: _stockController,
                                        decoration: const InputDecoration(
                                          labelText: 'Stock Quantity *',
                                          hintText: '0',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return 'Stock quantity is required';
                                          }
                                          final stock = int.tryParse(value.trim());
                                          if (stock == null || stock < 0) {
                                            return 'Enter a valid stock quantity (0 or greater)';
                                          }
                                          if (stock > 999999) {
                                            return 'Stock cannot exceed 999,999';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Image URL
                                TextFormField(
                                  controller: _imageUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Image URL',
                                    hintText: 'https://example.com/image.jpg',
                                    border: OutlineInputBorder(),
                                    helperText: 'Optional: Enter a valid image URL',
                                  ),
                                  validator: (value) {
                                    if (value != null && value.trim().isNotEmpty) {
                                      final uri = Uri.tryParse(value.trim());
                                      if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
                                        return 'Enter a valid URL starting with http:// or https://';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _updateProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text('Update Product'),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Changes Preview
                        if (_hasChanges())
                          Card(
                            color: Colors.orange[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Changes Detected',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You have unsaved changes. Tap "Update Product" to save them.',
                                    style: TextStyle(color: Colors.orange[800]),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 8),
                        
                        // Help Text
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tips:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const Text('• Only fields that are different will be updated'),
                                const Text('• Make sure to save your changes before leaving'),
                                const Text('• Stock updates will affect inventory immediately'),
                                const Text('• Price changes will be visible to customers right away'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  bool _hasChanges() {
    return _nameController.text.trim() != widget.product.name ||
           _descriptionController.text.trim() != widget.product.description ||
           _priceController.text.trim() != widget.product.price.toString() ||
           _stockController.text.trim() != widget.product.stockQuantity.toString() ||
           _imageUrlController.text.trim() != (widget.product.imageUrl ?? '') ||
           _selectedCategory?.id != widget.product.categoryId;
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if there are any changes
    if (!_hasChanges()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes detected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Only send changed fields
      final Map<String, dynamic> updates = {};
      
      if (_nameController.text.trim() != widget.product.name) {
        updates['name'] = _nameController.text.trim();
      }
      
      if (_descriptionController.text.trim() != widget.product.description) {
        updates['description'] = _descriptionController.text.trim();
      }
      
      if (_priceController.text.trim() != widget.product.price.toString()) {
        updates['price'] = double.parse(_priceController.text.trim());
      }
      
      if (_stockController.text.trim() != widget.product.stockQuantity.toString()) {
        updates['stockQuantity'] = int.parse(_stockController.text.trim());
        print('🔄 Stock update: ${widget.product.stockQuantity} -> ${updates['stockQuantity']}');
      }
      
      if (_imageUrlController.text.trim() != (widget.product.imageUrl ?? '')) {
        updates['imageUrl'] = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
      }

      if (_selectedCategory?.id != widget.product.categoryId) {
        updates['categoryId'] = _selectedCategory?.id;
      }

      print('📤 Sending updates: $updates');

      final success = await productProvider.updateProductData(
        productId: widget.product.id!,
        name: updates['name'],
        description: updates['description'],
        price: updates['price'],
        stockQuantity: updates['stockQuantity'],
        categoryId: updates['categoryId'],
        imageUrl: updates['imageUrl'],
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Return to previous screen with success result
          Navigator.of(context).pop(true);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(productProvider.errorMessage ?? 'Failed to update product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
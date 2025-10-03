import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Product> _products = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _searchQuery = '';
  int? _selectedCategoryId;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final int _pageSize = 20;

  // Getters
  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get hasMorePages => _hasMorePages;
  int get totalProducts => _products.length;

  // Get filtered products based on search and category
  List<Product> get filteredProducts {
    var filtered = _products;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filter by category
    if (_selectedCategoryId != null) {
      filtered = filtered.where((product) => 
          product.categoryId == _selectedCategoryId).toList();
    }

    return filtered;
  }

  // Get products by availability
  List<Product> get availableProducts => 
      filteredProducts.where((product) => product.isInStock).toList();

  List<Product> get outOfStockProducts => 
      filteredProducts.where((product) => !product.isInStock).toList();

  // Load products from API
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMorePages = true;
      _products.clear();
    }

    if (_isLoading || !_hasMorePages) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getProducts(
        page: _currentPage,
        limit: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
      );

      if (response.success && response.data != null) {
        final newProducts = response.data!;
        
        if (refresh) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }

        // Check if there are more pages
        _hasMorePages = newProducts.length == _pageSize;
        if (_hasMorePages) {
          _currentPage++;
        }

        _setLoading(false);
      } else {
        _setError(response.message);
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load products: $e');
      _setLoading(false);
    }
  }

  // Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMorePages) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _apiService.getProducts(
        page: _currentPage,
        limit: _pageSize,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        categoryId: _selectedCategoryId,
      );

      if (response.success && response.data != null) {
        final newProducts = response.data!;
        _products.addAll(newProducts);

        // Check if there are more pages
        _hasMorePages = newProducts.length == _pageSize;
        if (_hasMorePages) {
          _currentPage++;
        }

        _isLoadingMore = false;
        notifyListeners();
      } else {
        _setError(response.message);
        _isLoadingMore = false;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load more products: $e');
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Get single product by ID
  Future<Product?> getProduct(int id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getProduct(id);

      if (response.success && response.data != null) {
        _selectedProduct = response.data!;
        
        // Update product in list if it exists
        final index = _products.indexWhere((p) => p.id == id);
        if (index != -1) {
          _products[index] = _selectedProduct!;
        }

        _setLoading(false);
        return _selectedProduct;
      } else {
        _setError(response.message);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Failed to load product: $e');
      _setLoading(false);
      return null;
    }
  }

  // Create new product (admin only)
  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    required int stockQuantity,
    int? categoryId,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.createProduct(
        name: name,
        description: description,
        price: price,
        stockQuantity: stockQuantity,
        categoryId: categoryId,
        imageUrl: imageUrl,
      );

      if (response.success && response.data != null) {
        // Add new product to the beginning of the list
        _products.insert(0, response.data!);
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to create product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update existing product (admin only)
  Future<bool> updateProductData({
    required int productId,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    int? categoryId,
    String? imageUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔄 ProductProvider.updateProductData called with:');
      print('  productId: $productId');
      print('  stockQuantity: $stockQuantity');
      
      final response = await _apiService.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        stockQuantity: stockQuantity,
        categoryId: categoryId,
        imageUrl: imageUrl,
      );

      if (response.success && response.data != null) {
        // Update product in the list
        updateProduct(response.data!);
        _setLoading(false);
        notifyListeners(); // Ensure UI updates
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Delete product (admin only)
  Future<bool> deleteProduct(int productId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.deleteProduct(productId);

      if (response.success) {
        // Remove product from the list
        removeProduct(productId);
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete product: $e');
      _setLoading(false);
      return false;
    }
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _hasMorePages = true;
    loadProducts(refresh: true);
  }

  // Filter by category
  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _currentPage = 1;
    _hasMorePages = true;
    loadProducts(refresh: true);
  }

  // Clear search and filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _currentPage = 1;
    _hasMorePages = true;
    loadProducts(refresh: true);
  }

  // Set selected product
  void setSelectedProduct(Product? product) {
    _selectedProduct = product;
    notifyListeners();
  }

  // Update product in list
  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      
      // Update selected product if it's the same
      if (_selectedProduct?.id == updatedProduct.id) {
        _selectedProduct = updatedProduct;
      }
      
      notifyListeners();
    }
  }

  // Remove product from list
  void removeProduct(int productId) {
    _products.removeWhere((p) => p.id == productId);
    
    // Clear selected product if it's the removed one
    if (_selectedProduct?.id == productId) {
      _selectedProduct = null;
    }
    
    notifyListeners();
  }

  // Refresh products
  Future<void> refreshProducts() async {
    await loadProducts(refresh: true);
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _clearError();
  }

  // Get product by ID from local list
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if product exists in local list
  bool hasProduct(int id) {
    return _products.any((product) => product.id == id);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
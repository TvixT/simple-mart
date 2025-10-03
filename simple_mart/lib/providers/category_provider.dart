import 'package:flutter/foundation.dart';
import '../models/category.dart' as category_model;
import '../services/api_service.dart';

class CategoryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<category_model.Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<category_model.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get all categories
  Future<bool> fetchCategories() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.getCategories();
      
      if (response.success) {
        _categories = response.data ?? [];
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error fetching categories: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new category
  Future<bool> createCategory({
    required String name,
    String? description,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.createCategory(
        name: name,
        description: description,
      );
      
      if (response.success && response.data != null) {
        // Add the new category to the list
        _categories.add(response.data!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error creating category: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing category
  Future<bool> updateCategory({
    required int id,
    String? name,
    String? description,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.updateCategory(
        categoryId: id,
        name: name,
        description: description,
      );
      
      if (response.success && response.data != null) {
        // Update the category in the list
        final index = _categories.indexWhere((c) => c.id == id);
        if (index != -1) {
          _categories[index] = response.data!;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating category: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a category
  Future<bool> deleteCategory(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.deleteCategory(id);
      
      if (response.success) {
        // Remove the category from the list
        _categories.removeWhere((c) => c.id == id);
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error deleting category: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get category by ID
  category_model.Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
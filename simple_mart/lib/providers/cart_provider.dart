import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _cartItems.isEmpty;
  int get itemCount => _cartItems.length;

  // Get total quantity of all items
  int get totalQuantity => _cartItems.fold(
    0, (sum, item) => sum + item.quantity);

  // Get total price of all items
  double get totalPrice => _cartItems.fold(
    0.0, (sum, item) => sum + item.totalPrice);

  // Get formatted total price
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  // Get cart items that are available (in stock)
  List<CartItem> get availableItems => 
      _cartItems.where((item) => item.isAvailable).toList();

  // Get cart items that are not available (out of stock)
  List<CartItem> get unavailableItems => 
      _cartItems.where((item) => !item.isAvailable).toList();

  // Load cart from API
  Future<void> loadCart() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getCart();

      if (response.success && response.data != null) {
        _cartItems = response.data!;
        _setLoading(false);
      } else {
        _setError(response.message);
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load cart: $e');
      _setLoading(false);
    }
  }

  // Add item to cart
  Future<bool> addToCart({
    required int productId,
    required int quantity,
    Product? product,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.addToCart(
        productId: productId,
        quantity: quantity,
      );

      if (response.success && response.data != null) {
        final newCartItem = response.data!;
        
        // If product data is provided, update the cart item
        if (product != null) {
          final updatedCartItem = newCartItem.copyWith(product: product);
          _addOrUpdateCartItem(updatedCartItem);
        } else {
          _addOrUpdateCartItem(newCartItem);
        }

        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to add item to cart: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update cart item quantity
  Future<bool> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return await removeFromCart(cartItemId);
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.updateCartItem(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      if (response.success && response.data != null) {
        final updatedCartItem = response.data!;
        _addOrUpdateCartItem(updatedCartItem);
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update cart item: $e');
      _setLoading(false);
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(int cartItemId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.removeFromCart(cartItemId);

      if (response.success) {
        _cartItems.removeWhere((item) => item.id == cartItemId);
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to remove item from cart: $e');
      _setLoading(false);
      return false;
    }
  }

  // Clear entire cart
  Future<bool> clearCart() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.clearCart();

      if (response.success) {
        _cartItems.clear();
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to clear cart: $e');
      _setLoading(false);
      return false;
    }
  }

  // Increase item quantity
  Future<bool> increaseQuantity(int cartItemId) async {
    final item = getCartItemById(cartItemId);
    if (item != null) {
      return await updateCartItem(
        cartItemId: cartItemId,
        quantity: item.quantity + 1,
      );
    }
    return false;
  }

  // Decrease item quantity
  Future<bool> decreaseQuantity(int cartItemId) async {
    final item = getCartItemById(cartItemId);
    if (item != null) {
      return await updateCartItem(
        cartItemId: cartItemId,
        quantity: item.quantity - 1,
      );
    }
    return false;
  }

  // Get cart item by ID
  CartItem? getCartItemById(int cartItemId) {
    try {
      return _cartItems.firstWhere((item) => item.id == cartItemId);
    } catch (e) {
      return null;
    }
  }

  // Get cart item by product ID
  CartItem? getCartItemByProductId(int productId) {
    try {
      return _cartItems.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Check if product is in cart
  bool isProductInCart(int productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  // Get quantity of specific product in cart
  int getProductQuantity(int productId) {
    final item = getCartItemByProductId(productId);
    return item?.quantity ?? 0;
  }

  // Validate cart (check stock availability)
  Future<bool> validateCart() async {
    _clearError();

    try {
      // Check each item's availability
      bool allAvailable = true;
      final unavailableProducts = <String>[];

      for (final item in _cartItems) {
        if (!item.isAvailable) {
          allAvailable = false;
          unavailableProducts.add(item.product?.name ?? 'Unknown product');
        }
      }

      if (!allAvailable) {
        _setError('Some items are no longer available: ${unavailableProducts.join(', ')}');
        return false;
      }

      return true;
    } catch (e) {
      _setError('Failed to validate cart: $e');
      return false;
    }
  }

  // Refresh cart data
  Future<void> refreshCart() async {
    await loadCart();
  }

  // Helper method to add or update cart item in local list
  void _addOrUpdateCartItem(CartItem cartItem) {
    final index = _cartItems.indexWhere((item) => item.id == cartItem.id);
    if (index != -1) {
      _cartItems[index] = cartItem;
    } else {
      _cartItems.add(cartItem);
    }
    notifyListeners();
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

  // Quick add methods for UI convenience
  Future<bool> quickAddToCart(Product product, {int quantity = 1}) async {
    return await addToCart(
      productId: product.id!,
      quantity: quantity,
      product: product,
    );
  }

  // Get cart summary for UI
  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': itemCount,
      'totalQuantity': totalQuantity,
      'totalPrice': totalPrice,
      'formattedTotalPrice': formattedTotalPrice,
      'hasUnavailableItems': unavailableItems.isNotEmpty,
      'availableItemsCount': availableItems.length,
      'unavailableItemsCount': unavailableItems.length,
    };
  }

  @override
  void dispose() {
    super.dispose();
  }
}
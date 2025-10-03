import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Order> _orders = [];
  Order? _selectedOrder;
  bool _isLoading = false;
  bool _isCreatingOrder = false;
  String? _errorMessage;

  // Getters
  List<Order> get orders => _orders;
  Order? get selectedOrder => _selectedOrder;
  bool get isLoading => _isLoading;
  bool get isCreatingOrder => _isCreatingOrder;
  String? get errorMessage => _errorMessage;
  bool get hasOrders => _orders.isNotEmpty;
  int get totalOrders => _orders.length;

  // Get orders by status
  List<Order> getOrdersByStatus(OrderStatus status) =>
      _orders.where((order) => order.status == status).toList();

  // Get pending orders
  List<Order> get pendingOrders => getOrdersByStatus(OrderStatus.pending);

  // Get processing orders
  List<Order> get processingOrders => getOrdersByStatus(OrderStatus.processing);

  // Get shipped orders
  List<Order> get shippedOrders => getOrdersByStatus(OrderStatus.shipped);

  // Get delivered orders
  List<Order> get deliveredOrders => getOrdersByStatus(OrderStatus.delivered);

  // Get cancelled orders
  List<Order> get cancelledOrders => getOrdersByStatus(OrderStatus.cancelled);

  // Get active orders (not delivered or cancelled)
  List<Order> get activeOrders => _orders.where((order) => 
      order.status != OrderStatus.delivered && 
      order.status != OrderStatus.cancelled).toList();

  // Get recent orders (last 10)
  List<Order> get recentOrders {
    final sortedOrders = List<Order>.from(_orders);
    sortedOrders.sort((a, b) => 
        (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    return sortedOrders.take(10).toList();
  }

  // Load orders from API
  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _orders.clear();
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getOrders();

      if (response.success && response.data != null) {
        _orders = response.data!;
        
        // Sort orders by creation date (newest first)
        _orders.sort((a, b) => 
            (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

        _setLoading(false);
      } else {
        _setError(response.message);
        _setLoading(false);
      }
    } catch (e) {
      _setError('Failed to load orders: $e');
      _setLoading(false);
    }
  }

  // Get single order by ID
  Future<Order?> getOrder(int id) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getOrder(id);

      if (response.success && response.data != null) {
        _selectedOrder = response.data!;
        
        // Update order in list if it exists
        final index = _orders.indexWhere((o) => o.id == id);
        if (index != -1) {
          _orders[index] = _selectedOrder!;
        }

        _setLoading(false);
        return _selectedOrder;
      } else {
        _setError(response.message);
        _setLoading(false);
        return null;
      }
    } catch (e) {
      _setError('Failed to load order: $e');
      _setLoading(false);
      return null;
    }
  }

  // Create order from cart
  Future<Order?> createOrder({
    required String shippingAddress,
  }) async {
    _isCreatingOrder = true;
    _clearError();
    notifyListeners();

    try {
      final response = await _apiService.createOrder(
        shippingAddress: shippingAddress,
      );

      if (response.success && response.data != null) {
        final newOrder = response.data!;
        
        // Add new order to the beginning of the list
        _orders.insert(0, newOrder);
        _selectedOrder = newOrder;

        _isCreatingOrder = false;
        notifyListeners();
        return newOrder;
      } else {
        _setError(response.message);
        _isCreatingOrder = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _setError('Failed to create order: $e');
      _isCreatingOrder = false;
      notifyListeners();
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(int orderId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.cancelOrder(orderId);

      if (response.success && response.data != null) {
        final updatedOrder = response.data!;
        _updateOrderInList(updatedOrder);
        
        // Update selected order if it's the same
        if (_selectedOrder?.id == orderId) {
          _selectedOrder = updatedOrder;
        }

        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to cancel order: $e');
      _setLoading(false);
      return false;
    }
  }

  // Set selected order
  void setSelectedOrder(Order? order) {
    _selectedOrder = order;
    notifyListeners();
  }

  // Update order in list
  void _updateOrderInList(Order updatedOrder) {
    final index = _orders.indexWhere((o) => o.id == updatedOrder.id);
    if (index != -1) {
      _orders[index] = updatedOrder;
      notifyListeners();
    }
  }

  // Remove order from list
  void removeOrder(int orderId) {
    _orders.removeWhere((o) => o.id == orderId);
    
    // Clear selected order if it's the removed one
    if (_selectedOrder?.id == orderId) {
      _selectedOrder = null;
    }
    
    notifyListeners();
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await loadOrders(refresh: true);
  }

  // Get order by ID from local list
  Order? getOrderById(int id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if order exists in local list
  bool hasOrder(int id) {
    return _orders.any((order) => order.id == id);
  }

  // Get order statistics
  Map<String, dynamic> getOrderStatistics() {
    final totalSpent = _orders.fold(0.0, (sum, order) => sum + order.totalPrice);
    final totalItems = _orders.fold(0, (sum, order) => sum + order.totalItems);
    
    return {
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'formattedTotalSpent': '\$${totalSpent.toStringAsFixed(2)}',
      'totalItems': totalItems,
      'averageOrderValue': totalOrders > 0 ? totalSpent / totalOrders : 0.0,
      'pendingCount': pendingOrders.length,
      'processingCount': processingOrders.length,
      'shippedCount': shippedOrders.length,
      'deliveredCount': deliveredOrders.length,
      'cancelledCount': cancelledOrders.length,
      'activeCount': activeOrders.length,
    };
  }

  // Search orders by ID or status
  List<Order> searchOrders(String query) {
    if (query.isEmpty) return _orders;
    
    final lowerQuery = query.toLowerCase();
    return _orders.where((order) {
      final orderId = order.id.toString();
      final status = order.formattedStatus.toLowerCase();
      return orderId.contains(lowerQuery) || status.contains(lowerQuery);
    }).toList();
  }

  // Filter orders by date range
  List<Order> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _orders.where((order) {
      if (order.createdAt == null) return false;
      final orderDate = order.createdAt!;
      return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             orderDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Get orders from last N days
  List<Order> getRecentOrdersByDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _orders.where((order) {
      if (order.createdAt == null) return false;
      return order.createdAt!.isAfter(cutoffDate);
    }).toList();
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

  // Clear all orders (for logout)
  void clearOrders() {
    _orders.clear();
    _selectedOrder = null;
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
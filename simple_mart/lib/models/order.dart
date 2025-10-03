import 'product.dart';

class OrderItem {
  final int? id;
  final int? orderId;
  final int productId;
  final Product? product;
  final int quantity;
  final double price;
  final DateTime? createdAt;

  OrderItem({
    this.id,
    this.orderId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.price,
    this.createdAt,
  });

  // Convert OrderItem object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product': product?.toJson(),
      'quantity': quantity,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Create OrderItem object from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      product: json['product'] != null 
          ? Product.fromJson(json['product']) 
          : null,
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  // Calculate total price for this order item
  double get totalPrice => price * quantity;

  // Get formatted total price string
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  // Get formatted unit price string
  String get formattedUnitPrice => '\$${price.toStringAsFixed(2)}';

  @override
  String toString() {
    return 'OrderItem{id: $id, productId: $productId, quantity: $quantity, price: $formattedUnitPrice}';
  }
}

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

class Order {
  final int? id;
  final int? userId;
  final double totalPrice;
  final OrderStatus status;
  final String? shippingAddress;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    this.id,
    this.userId,
    required this.totalPrice,
    required this.status,
    this.shippingAddress,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Convert Order object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_price': totalPrice,
      'status': status.name,
      'shipping_address': shippingAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create Order object from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: _parseOrderStatus(json['status']),
      shippingAddress: json['shipping_address'],
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : [],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Parse order status from string
  static OrderStatus _parseOrderStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  // Get formatted total price string
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  // Get formatted order status
  String get formattedStatus {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get total number of items in order
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // Check if order can be cancelled
  bool get canBeCancelled => 
      status == OrderStatus.pending || status == OrderStatus.processing;

  // Get order status color for UI
  String get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return '#FFA500'; // Orange
      case OrderStatus.processing:
        return '#2196F3'; // Blue
      case OrderStatus.shipped:
        return '#9C27B0'; // Purple
      case OrderStatus.delivered:
        return '#4CAF50'; // Green
      case OrderStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  // Get formatted date string
  String get formattedDate {
    if (createdAt != null) {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    }
    return 'Unknown Date';
  }

  // Copy with method for immutable updates
  Order copyWith({
    int? id,
    int? userId,
    double? totalPrice,
    OrderStatus? status,
    String? shippingAddress,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Order{id: $id, totalPrice: $formattedTotalPrice, status: $formattedStatus, items: ${items.length}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}
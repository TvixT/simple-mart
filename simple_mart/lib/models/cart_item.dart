import 'product.dart';

class CartItem {
  final int? id;
  final int? userId;
  final int productId;
  final Product? product;
  final int quantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItem({
    this.id,
    this.userId,
    required this.productId,
    this.product,
    required this.quantity,
    this.createdAt,
    this.updatedAt,
  });

  // Convert CartItem object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'product': product?.toJson(),
      'quantity': quantity,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create CartItem object from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      product: json['product'] != null 
          ? Product.fromJson(json['product']) 
          : null,
      quantity: json['quantity'] ?? 1,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Calculate total price for this cart item
  double get totalPrice {
    if (product != null) {
      return product!.price * quantity;
    }
    return 0.0;
  }

  // Get formatted total price string
  String get formattedTotalPrice => '\$${totalPrice.toStringAsFixed(2)}';

  // Check if quantity is valid (greater than 0)
  bool get isValidQuantity => quantity > 0;

  // Check if cart item is available (product in stock)
  bool get isAvailable {
    if (product != null) {
      return product!.stockQuantity >= quantity;
    }
    return false;
  }

  // Copy with method for immutable updates
  CartItem copyWith({
    int? id,
    int? userId,
    int? productId,
    Product? product,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CartItem{id: $id, productId: $productId, quantity: $quantity, totalPrice: $formattedTotalPrice}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && 
      runtimeType == other.runtimeType && 
      id == other.id &&
      productId == other.productId;

  @override
  int get hashCode => id.hashCode ^ productId.hashCode;
}
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/category.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
    int statusCode,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null 
          ? fromJsonT(json['data']) 
          : json['data'],
      error: json['error'],
      statusCode: statusCode,
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://localhost:5000';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  late final Dio _dio;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_LoggingInterceptor());
  }

  // Get stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Store JWT token
  Future<void> setToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Remove JWT token
  Future<void> removeToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // AUTHENTICATION ENDPOINTS

  // User registration
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'name': fullName, // Backend expects 'name', not 'username' or 'full_name'
        'email': email,
        'password': password,
      });

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>, // Return the full data structure
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    }
  }

  // User login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      return ApiResponse.fromJson(
        response.data,
        (data) => data,
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Map<String, dynamic>>(e);
    }
  }

  // PRODUCT ENDPOINTS

  // Get all products
  Future<ApiResponse<List<Product>>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    int? categoryId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null) queryParams['search'] = search;
      if (categoryId != null) queryParams['category_id'] = categoryId;

      final response = await _dio.get('/api/products', queryParameters: queryParams);

      return ApiResponse.fromJson(
        response.data,
        (data) => (data['products'] as List)
            .map((item) => Product.fromJson(item))
            .toList(),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<List<Product>>(e);
    }
  }

  // Get single product
  Future<ApiResponse<Product>> getProduct(int id) async {
    try {
      final response = await _dio.get('/api/products/$id');

      return ApiResponse.fromJson(
        response.data,
        (data) => Product.fromJson(data['product']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Product>(e);
    }
  }

  // Create product (admin only)
  Future<ApiResponse<Product>> createProduct({
    required String name,
    required String description,
    required double price,
    required int stockQuantity,
    int? categoryId,
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post('/api/products', data: {
        'name': name,
        'description': description,
        'price': price,
        'stock': stockQuantity, // Fixed: backend expects 'stock'
        'category_id': categoryId,
        'image_url': imageUrl,
      });

      return ApiResponse.fromJson(
        response.data,
        (data) => Product.fromJson(data['product']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Product>(e);
    }
  }

  // Update product (admin only)
  Future<ApiResponse<Product>> updateProduct({
    required int productId,
    String? name,
    String? description,
    double? price,
    int? stockQuantity,
    int? categoryId,
    String? imageUrl,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (stockQuantity != null) {
        data['stock'] = stockQuantity; // Fixed: backend expects 'stock'
        print('🔧 FIXED: Converting stockQuantity $stockQuantity to stock field');
      }
      if (categoryId != null) data['category_id'] = categoryId;
      if (imageUrl != null) data['image_url'] = imageUrl;

      print('🌐 API updateProduct sending: $data');

      final response = await _dio.put('/api/products/$productId', data: data);

      return ApiResponse.fromJson(
        response.data,
        (data) => Product.fromJson(data['product']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Product>(e);
    }
  }

  // Delete product (admin only)
  Future<ApiResponse<void>> deleteProduct(int productId) async {
    try {
      final response = await _dio.delete('/api/products/$productId');

      return ApiResponse.fromJson(
        response.data,
        (data) => null,
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<void>(e);
    }
  }

  // CATEGORY ENDPOINTS

  // Get all categories
  Future<ApiResponse<List<Category>>> getCategories({
    bool includeProductCount = false,
  }) async {
    try {
      final response = await _dio.get('/api/categories', 
        queryParameters: {
          'includeProductCount': includeProductCount.toString(),
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data['categories'] as List)
            .map((item) => Category.fromJson(item))
            .toList(),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<List<Category>>(e);
    }
  }

  // Get single category by ID
  Future<ApiResponse<Category>> getCategoryById(int categoryId) async {
    try {
      final response = await _dio.get('/api/categories/$categoryId');

      return ApiResponse.fromJson(
        response.data,
        (data) => Category.fromJson(data['category']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Category>(e);
    }
  }

  // Search categories
  Future<ApiResponse<List<Category>>> searchCategories(String query) async {
    try {
      final response = await _dio.get('/api/categories/search/query',
        queryParameters: {'q': query},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => (data['categories'] as List)
            .map((item) => Category.fromJson(item))
            .toList(),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<List<Category>>(e);
    }
  }

  // Create category (admin only)
  Future<ApiResponse<Category>> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post('/api/categories', data: {
        'name': name,
        'description': description ?? '',
      });

      return ApiResponse.fromJson(
        response.data,
        (data) => Category.fromJson(data['category']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Category>(e);
    }
  }

  // Update category (admin only)
  Future<ApiResponse<Category>> updateCategory({
    required int categoryId,
    String? name,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;

      final response = await _dio.put('/api/categories/$categoryId', data: data);

      return ApiResponse.fromJson(
        response.data,
        (data) => Category.fromJson(data['category']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Category>(e);
    }
  }

  // Delete category (admin only)
  Future<ApiResponse<void>> deleteCategory(int categoryId) async {
    try {
      final response = await _dio.delete('/api/categories/$categoryId');

      return ApiResponse.fromJson(
        response.data,
        (data) => null,
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<void>(e);
    }
  }

  // CART ENDPOINTS

  // Get user's cart
  Future<ApiResponse<List<CartItem>>> getCart() async {
    try {
      final response = await _dio.get('/api/cart');

      return ApiResponse.fromJson(
        response.data,
        (data) => (data['cart'] as List)
            .map((item) => CartItem.fromJson(item))
            .toList(),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<List<CartItem>>(e);
    }
  }

  // Add item to cart
  Future<ApiResponse<CartItem>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.post('/api/cart', data: {
        'product_id': productId,
        'quantity': quantity,
      });

      return ApiResponse.fromJson(
        response.data,
        (data) => CartItem.fromJson(data['cart']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<CartItem>(e);
    }
  }

  // Update cart item quantity
  Future<ApiResponse<CartItem>> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.put('/api/cart', data: {
        'cart_item_id': cartItemId,
        'quantity': quantity,
      });

      return ApiResponse.fromJson(
        response.data,
        (data) => CartItem.fromJson(data['cart']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<CartItem>(e);
    }
  }

  // Remove item from cart
  Future<ApiResponse<void>> removeFromCart(int cartItemId) async {
    try {
      final response = await _dio.delete('/api/cart/$cartItemId');

      return ApiResponse.fromJson(
        response.data,
        null,
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<void>(e);
    }
  }

  // Clear entire cart
  Future<ApiResponse<void>> clearCart() async {
    try {
      final response = await _dio.delete('/api/cart');

      return ApiResponse.fromJson(
        response.data,
        null,
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<void>(e);
    }
  }

  // ORDER ENDPOINTS

  // Get user's orders
  Future<ApiResponse<List<Order>>> getOrders() async {
    try {
      final response = await _dio.get('/api/orders/user');

      return ApiResponse.fromJson(
        response.data,
        (data) => (data['orders'] as List)
            .map((item) => Order.fromJson(item))
            .toList(),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<List<Order>>(e);
    }
  }

  // Create order from cart
  Future<ApiResponse<Order>> createOrder({
    required String shippingAddress,
  }) async {
    try {
      final response = await _dio.post('/api/orders', data: {
        'shipping_address': shippingAddress,
      });

      return ApiResponse.fromJson(
        response.data,
        (data) => Order.fromJson(data['order']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Order>(e);
    }
  }

  // Get single order
  Future<ApiResponse<Order>> getOrder(int id) async {
    try {
      final response = await _dio.get('/api/orders/$id');

      return ApiResponse.fromJson(
        response.data,
        (data) => Order.fromJson(data['order']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Order>(e);
    }
  }

  // Cancel order
  Future<ApiResponse<Order>> cancelOrder(int id) async {
    try {
      final response = await _dio.put('/api/orders/$id/cancel');

      return ApiResponse.fromJson(
        response.data,
        (data) => Order.fromJson(data['order']),
        response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<Order>(e);
    }
  }

  // Error handler
  ApiResponse<T> _handleError<T>(DioException e) {
    String message = 'An error occurred';
    int statusCode = 500;

    if (e.response != null) {
      statusCode = e.response!.statusCode ?? 500;
      final data = e.response!.data;
      
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error'] ?? message;
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      message = 'Connection timeout';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      message = 'Receive timeout';
    } else {
      message = e.message ?? message;
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      error: message,
      statusCode: statusCode,
    );
  }
}

// Auth interceptor to add JWT token to requests
class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
}

// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🚀 REQUEST: ${options.method} ${options.path}');
    print('📤 Data: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    print('📥 Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ ERROR: ${err.response?.statusCode} ${err.requestOptions.path}');
    print('📥 Error Data: ${err.response?.data}');
    handler.next(err);
  }
}
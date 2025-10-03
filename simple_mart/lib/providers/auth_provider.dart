import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initializeAuth();
  }

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      final token = await _apiService.getToken();
      if (token != null) {
        _token = token;
        await _loadUserFromStorage();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // Load user data from local storage
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        // Parse user data from JSON if needed
        // For now, we'll set a placeholder
        _user = User(
          id: prefs.getInt('user_id'),
          username: prefs.getString('username') ?? '',
          email: prefs.getString('email') ?? '',
          fullName: prefs.getString('full_name') ?? '',
          role: prefs.getString('role'), // Make sure role is loaded
        );
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
    }
  }

  // Save user data to local storage
  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id ?? 0);
      await prefs.setString('username', user.username);
      await prefs.setString('email', user.email);
      await prefs.setString('full_name', user.fullName);
      await prefs.setString('role', user.role ?? 'customer'); // Save role
    } catch (e) {
      debugPrint('Error saving user to storage: $e');
    }
  }

  // Clear user data from local storage
  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('full_name');
      await prefs.remove('role');
      await prefs.remove('user_data');
    } catch (e) {
      debugPrint('Error clearing user from storage: $e');
    }
  }

  // User registration
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        // Handle the correct response structure for registration
        _token = data['tokens']['accessToken']; // Backend returns tokens.accessToken
        _user = User.fromJson(data['user']);
        
        // Store token and user data
        await _apiService.setToken(_token!);
        await _saveUserToStorage(_user!);
        
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // User login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        // Fix: Handle the correct response structure
        _token = data['tokens']['accessToken']; // Backend returns tokens.accessToken
        _user = User.fromJson(data['user']);
        
        // Store token and user data
        await _apiService.setToken(_token!);
        await _saveUserToStorage(_user!);
        
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // User logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      // Clear token from secure storage
      await _apiService.removeToken();
      
      // Clear user data from local storage
      await _clearUserFromStorage();
      
      // Reset state
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      
      _setLoading(false);
    } catch (e) {
      debugPrint('Error during logout: $e');
      _setLoading(false);
    }
  }

  // Check if user is admin
  bool get isAdmin => _user?.role == 'admin';

  // Check if user is staff
  bool get isStaff => _user?.role == 'staff';

  // Check if user is admin or staff (has management access)
  bool get hasManagementAccess => isAdmin || isStaff;

  // Update user profile
  Future<bool> updateProfile({
    String? username,
    String? email,
    String? fullName,
  }) async {
    if (_user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      // Create updated user object
      final updatedUser = _user!.copyWith(
        username: username ?? _user!.username,
        email: email ?? _user!.email,
        fullName: fullName ?? _user!.fullName,
      );

      // Update local state
      _user = updatedUser;
      await _saveUserToStorage(_user!);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      _setLoading(false);
      return false;
    }
  }

  // Refresh authentication status
  Future<void> refreshAuth() async {
    await _initializeAuth();
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

  @override
  void dispose() {
    super.dispose();
  }
}
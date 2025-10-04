import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'admin_category_screen.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _selectedNavItem = 'Products';
  
  // Search and filter controls
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _stockFilter = 'All'; // All, In Stock, Out of Stock
  String _sortBy = 'name'; // name, price, stock
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Load products when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 768;
  }

  int _getCrossAxisCount(BuildContext context) {
    return _isDesktop(context) ? 5 : 2;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ProductProvider>(
      builder: (context, authProvider, productProvider, child) {
        // Check if user has management access
        if (!authProvider.hasManagementAccess) {
          return _buildAccessDeniedScreen();
        }

        final isDesktop = _isDesktop(context);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: isDesktop 
              ? _buildDesktopLayout(productProvider)
              : _buildMobileLayout(productProvider),
        );
      },
    );
  }

  Widget _buildAccessDeniedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Color(0xFFE74C3C),
              ),
              const SizedBox(height: 16),
              const Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You do not have permission to access this page.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ProductProvider productProvider) {
    return Row(
      children: [
        // Sidebar
        _buildSidebar(),
        
        // Main Content
        Expanded(
          child: _buildMainContent(productProvider),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(ProductProvider productProvider) {
    return Column(
      children: [
        _buildMobileHeader(productProvider),
        Expanded(
          child: _buildProductGrid(productProvider),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Title
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4267B2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Navigation Links
          _buildNavLink(
            'Products', 
            Icons.inventory_2_outlined,
            'Products',
            () => setState(() => _selectedNavItem = 'Products'),
          ),
          _buildNavLink(
            'Categories', 
            Icons.category_outlined,
            'Categories',
            () {
              setState(() => _selectedNavItem = 'Categories');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminCategoryScreen(),
                ),
              );
            },
          ),
          _buildNavLink(
            'Orders', 
            Icons.receipt_long_outlined,
            'Orders',
            () {
              setState(() => _selectedNavItem = 'Orders');
              Navigator.of(context).pushNamed('/orders');
            },
          ),
          
          const Spacer(),
          
          // Back to Store
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/products');
              },
              icon: const Icon(Icons.store_outlined, size: 20),
              label: const Text('Back to Store'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String text, IconData icon, String value, VoidCallback onTap) {
    final isSelected = _selectedNavItem == value;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFF4267B2).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF4267B2).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? const Color(0xFF4267B2)
                      : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFF4267B2)
                        : Colors.grey[700],
                    fontWeight: isSelected 
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(ProductProvider productProvider) {
    return Column(
      children: [
        _buildDesktopHeader(productProvider),
        Expanded(
          child: _buildProductGrid(productProvider),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(ProductProvider productProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title and main actions row
          Row(
            children: [
              const Text(
                'Product Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              
              // Refresh Button
              IconButton(
                onPressed: () => productProvider.refreshProducts(),
                icon: const Icon(Icons.refresh_outlined),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF4267B2).withOpacity(0.1),
                  foregroundColor: const Color(0xFF4267B2),
                ),
                tooltip: 'Refresh Products',
              ),
              
              const SizedBox(width: 12),
              
              // Add Product Button
              ElevatedButton.icon(
                onPressed: () => _navigateToAddProduct(productProvider),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ).copyWith(
                  elevation: MaterialStateProperty.resolveWith<double>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered)) {
                        return 8;
                      }
                      if (states.contains(MaterialState.pressed)) {
                        return 2;
                      }
                      return 4;
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Search and filter row
          _buildSearchAndFilters(),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(ProductProvider productProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF4267B2).withOpacity(0.1),
                    foregroundColor: const Color(0xFF4267B2),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Product Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => productProvider.refreshProducts(),
                  icon: const Icon(Icons.refresh_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF4267B2).withOpacity(0.1),
                    foregroundColor: const Color(0xFF4267B2),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search and filters for mobile
            _buildSearchAndFilters(),
            
            const SizedBox(height: 16),
            
            // Add Product Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToAddProduct(productProvider),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        // Get unique categories for filter
        final categories = ['All'];
        if (productProvider.products.isNotEmpty) {
          final categoryNames = productProvider.products
              .where((product) => product.categoryName != null)
              .map((product) => product.categoryName!)
              .toSet()
              .toList();
          categories.addAll(categoryNames);
        }

        return Column(
          children: [
            // Search bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: Icon(
                          Icons.search_outlined,
                          color: Color(0xFF4267B2),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Clear search button
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C).withOpacity(0.1),
                      foregroundColor: const Color(0xFFE74C3C),
                    ),
                    tooltip: 'Clear search',
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Category filter
                  _buildFilterChip(
                    'Category',
                    _selectedCategory,
                    categories,
                    (value) => setState(() => _selectedCategory = value),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Stock filter
                  _buildFilterChip(
                    'Stock',
                    _stockFilter,
                    ['All', 'In Stock', 'Out of Stock'],
                    (value) => setState(() => _stockFilter = value),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Sort filter
                  _buildSortChip(),
                  
                  const SizedBox(width: 12),
                  
                  // Clear filters button
                  if (_hasActiveFilters())
                    ActionChip(
                      onPressed: _clearAllFilters,
                      label: const Text('Clear All'),
                      avatar: const Icon(Icons.clear_all, size: 16),
                      backgroundColor: const Color(0xFFE74C3C).withOpacity(0.1),
                      labelStyle: const TextStyle(
                        color: Color(0xFFE74C3C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (context) => options.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Row(
            children: [
              Icon(
                selectedValue == option 
                    ? Icons.radio_button_checked 
                    : Icons.radio_button_unchecked,
                size: 16,
                color: const Color(0xFF4267B2),
              ),
              const SizedBox(width: 8),
              Text(option),
            ],
          ),
        );
      }).toList(),
      child: Chip(
        label: Text('$label: $selectedValue'),
        avatar: const Icon(Icons.filter_list, size: 16),
        backgroundColor: selectedValue != 'All' && selectedValue != options.first
            ? const Color(0xFF4267B2).withOpacity(0.1)
            : const Color(0xFFF7F8FA),
        labelStyle: TextStyle(
          color: selectedValue != 'All' && selectedValue != options.first
              ? const Color(0xFF4267B2)
              : Colors.grey[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          if (value == _sortBy) {
            _sortAscending = !_sortAscending;
          } else {
            _sortBy = value;
            _sortAscending = true;
          }
        });
      },
      itemBuilder: (context) => [
        'name',
        'price',
        'stock',
      ].map((option) {
        final isSelected = _sortBy == option;
        return PopupMenuItem<String>(
          value: option,
          child: Row(
            children: [
              Icon(
                isSelected 
                    ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                    : Icons.sort,
                size: 16,
                color: const Color(0xFF4267B2),
              ),
              const SizedBox(width: 8),
              Text('Sort by ${option.substring(0, 1).toUpperCase()}${option.substring(1)}'),
            ],
          ),
        );
      }).toList(),
      child: Chip(
        label: Text('Sort: ${_sortBy.substring(0, 1).toUpperCase()}${_sortBy.substring(1)} ${_sortAscending ? '↑' : '↓'}'),
        avatar: const Icon(Icons.sort, size: 16),
        backgroundColor: const Color(0xFF4267B2).withOpacity(0.1),
        labelStyle: const TextStyle(
          color: Color(0xFF4267B2),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
           _selectedCategory != 'All' ||
           _stockFilter != 'All' ||
           _sortBy != 'name' ||
           !_sortAscending;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
      _stockFilter = 'All';
      _sortBy = 'name';
      _sortAscending = true;
    });
  }

  Widget _buildProductGrid(ProductProvider productProvider) {
    if (productProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4267B2),
          strokeWidth: 3,
        ),
      );
    }

    if (productProvider.errorMessage != null) {
      return _buildErrorState(productProvider);
    }

    if (productProvider.products.isEmpty) {
      return _buildEmptyState();
    }

    // Apply filters and sorting
    final filteredProducts = _getFilteredAndSortedProducts(productProvider.products);

    if (filteredProducts.isEmpty) {
      return _buildNoResultsState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            // Results count
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Showing ${filteredProducts.length} of ${productProvider.products.length} products',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Product grid
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => productProvider.refreshProducts(),
                color: const Color(0xFF4267B2),
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(context),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return ModernProductCard(
                      product: product,
                      onEdit: () => _navigateToEditProduct(product, productProvider),
                      onDelete: () => _showDeleteConfirmation(product, productProvider),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _getFilteredAndSortedProducts(List<Product> products) {
    List<Product> filteredProducts = products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((product) {
        final nameMatch = product.name.toLowerCase().contains(_searchQuery);
        final descriptionMatch = product.description.toLowerCase().contains(_searchQuery);
        final categoryMatch = product.categoryName?.toLowerCase().contains(_searchQuery) ?? false;
        
        return nameMatch || descriptionMatch || categoryMatch;
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filteredProducts = filteredProducts.where((product) {
        return product.categoryName == _selectedCategory;
      }).toList();
    }

    // Apply stock filter
    if (_stockFilter == 'In Stock') {
      filteredProducts = filteredProducts.where((product) {
        return product.stockQuantity > 0;
      }).toList();
    } else if (_stockFilter == 'Out of Stock') {
      filteredProducts = filteredProducts.where((product) {
        return product.stockQuantity == 0;
      }).toList();
    }

    // Apply sorting
    filteredProducts.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'stock':
          comparison = a.stockQuantity.compareTo(b.stockQuantity);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });

    return filteredProducts;
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4267B2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_outlined,
                size: 64,
                color: Color(0xFF4267B2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search or filters to find what you\'re looking for.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_all, size: 20),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4267B2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ProductProvider productProvider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFE74C3C),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              productProvider.errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => productProvider.refreshProducts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4267B2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4267B2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Color(0xFF4267B2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first product to get started!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToAddProduct(
                Provider.of<ProductProvider>(context, listen: false),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB74D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddProduct(ProductProvider productProvider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
    // Refresh list if product was added
    if (result == true) {
      productProvider.refreshProducts();
    }
  }

  Future<void> _navigateToEditProduct(Product product, ProductProvider productProvider) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(product: product),
      ),
    );
    // Refresh list if product was updated
    if (result == true) {
      productProvider.refreshProducts();
    }
  }

  void _showDeleteConfirmation(Product product, ProductProvider productProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: const Color(0xFFE74C3C),
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Product',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${product.name}"?\n\nThis action cannot be undone.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProduct(product, productProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(Product product, ProductProvider productProvider) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF4267B2),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Deleting product...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final success = await productProvider.deleteProduct(product.id!);

      // Close loading indicator
      Navigator.of(context).pop();

      if (success) {
        // Show success message
        _showSnackBar(
          '${product.name} deleted successfully',
          const Color(0xFF27AE60),
          Icons.check_circle_outline,
        );
        // Refresh the product list
        productProvider.loadProducts();
      } else {
        // Show error message
        _showSnackBar(
          'Failed to delete product',
          const Color(0xFFE74C3C),
          Icons.error_outline,
        );
      }
    } catch (e) {
      // Close loading indicator if still open
      Navigator.of(context).pop();
      
      // Show error message
      _showSnackBar(
        'Error deleting product: $e',
        const Color(0xFFE74C3C),
        Icons.error_outline,
      );
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class ModernProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ModernProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<ModernProductCard> createState() => _ModernProductCardState();
}

class _ModernProductCardState extends State<ModernProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: _buildProductImage(),
            ),
            
            // Product Info
            Expanded(
              flex: 2,
              child: _buildProductInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
            ? Image.network(
                widget.product.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder();
                },
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF7F8FA),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name
          Text(
            widget.product.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Stock Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: widget.product.stockQuantity > 0
                  ? const Color(0xFF27AE60).withOpacity(0.1)
                  : const Color(0xFFE74C3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Stock: ${widget.product.stockQuantity}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.product.stockQuantity > 0
                    ? const Color(0xFF27AE60)
                    : const Color(0xFFE74C3C),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_outlined,
                  onPressed: widget.onEdit,
                  color: const Color(0xFF4267B2),
                  tooltip: 'Edit',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline,
                  onPressed: widget.onDelete,
                  color: const Color(0xFFE74C3C),
                  tooltip: 'Delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
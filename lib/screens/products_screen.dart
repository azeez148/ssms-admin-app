import 'package:flutter/material.dart';
import 'package:flutter_admin_app/models/category.dart';
import 'package:flutter_admin_app/models/product_size.dart';
import 'package:flutter_admin_app/services/product_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../models/product.dart';

enum ProductSortOption {
  unitPriceAsc('Unit Price (Low to High)', true),
  unitPriceDesc('Unit Price (High to Low)', false),
  sellingPriceAsc('Selling Price (Low to High)', true),
  sellingPriceDesc('Selling Price (High to Low)', false);

  final String label;
  final bool ascending;

  const ProductSortOption(this.label, this.ascending);
}

class ProductFilterOptions {
  final String? searchQuery;
  final String? categoryName;
  final bool? hasImage;
  final bool? isActive;
  final bool? canListed;
  final String? sizeFilter;

  const ProductFilterOptions({
    this.searchQuery,
    this.categoryName,
    this.hasImage,
    this.isActive,
    this.canListed,
    this.sizeFilter,
  });

  bool matches(Product product) {
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!product.name.toLowerCase().contains(query)) {
        return false;
      }
    }

    if (categoryName != null && (product.category?.name != categoryName)) {
      return false;
    }

    if (hasImage != null) {
      final hasProductImage =
          product.imageUrl != null && product.imageUrl!.isNotEmpty;
      if (hasImage != hasProductImage) {
        return false;
      }
    }

    if (isActive != null && product.isActive != isActive) {
      return false;
    }

    if (canListed != null && product.canListed != canListed) {
      return false;
    }

    if (sizeFilter != null && product.sizeMap != null) {
      final hasSize = product.sizeMap!.any((s) =>
          s.size.toLowerCase() == sizeFilter!.toLowerCase() && s.quantity > 0);
      if (!hasSize) {
        return false;
      }
    }

    return true;
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    Key? key,
    required this.label,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        onDeleted: onRemove,
        backgroundColor: const Color(0xFF2A2D3E), // Primary Color
        labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
        deleteIconColor: Colors.white70,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
    );
  }
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _displayedProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  final int _pageSize = 20; // Increased page size for grid
  int _currentPage = 0;

  // Filter and sort state
  ProductFilterOptions _filterOptions = const ProductFilterOptions();
  ProductSortOption _sortOption = ProductSortOption.sellingPriceAsc;
  Set<String> _availableCategories = {};
  Set<String> _availableSizes = {};
  List<Category> _availableCategoriesList = [];  // Category objects for add product dialog

  // Styling Constants (Matching SalesScreen)
  final Color primaryColor = const Color(0xFF2A2D3E);
  final Color accentColor = const Color(0xFF2196F3);
  final Color surfaceColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Build full image URL from relative path
  String? _buildImageUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    return '${ApiService.defaultBaseUrl}$imageUrl';
  }

  void _updateAvailableFilters() {
    _availableCategories = _allProducts
        .where((p) => p.category?.name != null)
        .map((p) => p.category!.name)
        .toSet();

    // Build category objects list (removing duplicates by name)
    final Map<String, Category> categoriesMap = {};
    for (final product in _allProducts) {
      if (product.category != null) {
        categoriesMap[product.category!.name] = product.category!;
      }
    }
    _availableCategoriesList = categoriesMap.values.toList();

    _availableSizes = _allProducts
        .where((p) => p.sizeMap != null)
        .expand((p) => p.sizeMap!)
        .map((s) => s.size)
        .toSet();
  }

  void _onSearchChanged() {
    setState(() {
      _filterOptions = ProductFilterOptions(
        searchQuery: _searchController.text,
        categoryName: _filterOptions.categoryName,
        hasImage: _filterOptions.hasImage,
        isActive: _filterOptions.isActive,
        canListed: _filterOptions.canListed,
        sizeFilter: _filterOptions.sizeFilter,
      );
      _applyFiltersAndSort();
    });
  }

  void _updateFilters({
    String? categoryName,
    bool? hasImage,
    bool? isActive,
    bool? canListed,
    String? sizeFilter,
  }) {
    setState(() {
      _filterOptions = ProductFilterOptions(
        searchQuery: _filterOptions.searchQuery,
        categoryName: categoryName,
        hasImage: hasImage,
        isActive: isActive,
        canListed: canListed,
        sizeFilter: sizeFilter,
      );
      _applyFiltersAndSort();
    });
  }

  void _updateSort(ProductSortOption option) {
    setState(() {
      _sortOption = option;
      _applyFiltersAndSort();
    });
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    String? selectedCategory = _filterOptions.categoryName;
    bool? hasImage = _filterOptions.hasImage;
    bool? isActive = _filterOptions.isActive;
    bool? canListed = _filterOptions.canListed;
    String? selectedSize = _filterOptions.sizeFilter;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Dropdown
              if (_availableCategories.isNotEmpty) ...[
                const Text('Category',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._availableCategories.map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        )),
                  ],
                  onChanged: (value) {
                    selectedCategory = value;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Image Filter
              const Text('Image Status',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Has Image')),
                  ButtonSegment(value: false, label: Text('No Image')),
                ],
                selected: {hasImage},
                onSelectionChanged: (Set<bool?> newValue) {
                  // SegmentedButton requires setState inside dialog to update visual selection immediately?
                  // Usually Dialogs are stateless or use StatefulBuilder.
                  // For simplicity, we just capture value here, but UI won't update without state management.
                  // Using StatefulBuilder for the dialog content is better practice, but sticking to existing pattern:
                  hasImage = newValue.first;
                  (context as Element)
                      .markNeedsBuild(); // Quick hack for dialog refresh or use StatefulBuilder
                },
              ),
              const SizedBox(height: 16),

              // Active Status
              const Text('Active Status',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Active')),
                  ButtonSegment(value: false, label: Text('Inactive')),
                ],
                selected: {isActive},
                onSelectionChanged: (Set<bool?> newValue) {
                  isActive = newValue.first;
                  (context as Element).markNeedsBuild();
                },
              ),
              const SizedBox(height: 16),

              // Size Filter
              if (_availableSizes.isNotEmpty) ...[
                const Text('Size',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: selectedSize,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Sizes'),
                    ),
                    ..._availableSizes.map((size) => DropdownMenuItem(
                          value: size,
                          child: Text(size),
                        )),
                  ],
                  onChanged: (value) {
                    selectedSize = value;
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, foregroundColor: Colors.white),
            onPressed: () {
              _updateFilters(
                categoryName: selectedCategory,
                hasImage: hasImage,
                isActive: isActive,
                canListed: canListed,
                sizeFilter: selectedSize,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  void _applyFiltersAndSort() {
    // Apply filters
    _filteredProducts = _allProducts.where(_filterOptions.matches).toList();

    // Apply sorting
    _filteredProducts.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case ProductSortOption.unitPriceAsc:
        case ProductSortOption.unitPriceDesc:
          comparison = a.unitPrice.compareTo(b.unitPrice);
          break;
        case ProductSortOption.sellingPriceAsc:
        case ProductSortOption.sellingPriceDesc:
          comparison = a.sellingPrice.compareTo(b.sellingPrice);
          break;
      }
      return _sortOption.ascending ? comparison : -comparison;
    });

    // Reset pagination
    _currentPage = 0;
    _displayedProducts = [];
    _loadNextPage();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMoreItems) {
      _loadNextPage();
    }
  }

  bool get _hasMoreItems => _currentPage * _pageSize < _filteredProducts.length;

  void _loadNextPage() {
    if (_isLoading && _displayedProducts.isEmpty)
      return; // Allow pagination loading even if general loading is false

    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredProducts.length);

    if (start < _filteredProducts.length) {
      setState(() {
        _displayedProducts.addAll(_filteredProducts.getRange(start, end));
        _currentPage++;
      });
    }
  }

Future<void> _loadProducts() async {
  setState(() {
    _isLoading = true;
    _currentPage = 0;
    _displayedProducts.clear();
  });

  try {
    final List<dynamic> response =
        await ApiService.instance.getProducts(context);

    final products = response
        .whereType<Map<String, dynamic>>()
        .map((json) {
          print('Raw product JSON: $json'); // Debug print
          return Product.fromJson({
            ...json,
            // Build full image URL
            'image_url': _buildImageUrl(json['image_url']),
            // Match Angular defaults
            'offer_id': json['offer_id'],
            'discounted_price': json['discounted_price'] ?? 0,
            'offer_price': json['offer_price'] ?? 0,
          });
        })
        .toList();

    if (!mounted) return;

    setState(() {
      _allProducts = products;
      _updateAvailableFilters();
      _applyFiltersAndSort();
      _isLoading = false;
    });

    debugPrint('Loaded ${products.length} products');
  } catch (e, st) {
    debugPrint('Error loading products: $e');
    debugPrintStack(stackTrace: st);

    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to load products'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: _loadProducts,
        ),
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    // Grid Setup
    int crossAxisCount = isMobile ? 1 : (screenWidth < 1100 ? 3 : 4);
    double childAspectRatio = isMobile ? 1.6 : 0.75;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // 1. Header & Summary Section
          _buildHeader(isMobile),

          // 2. Filters & Actions Bar (Overlapping)
          _buildActionBar(isMobile),

          // 3. Active Filters
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _buildFilterChips(),
                ),
              ),
            ),

          // 4. Products Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty && _allProducts.isNotEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadProducts,
                        child: isMobile
                            ? ListView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _displayedProducts.length +
                                    (_hasMoreItems ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _displayedProducts.length) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildProductCard(
                                        _displayedProducts[index], isMobile),
                                  );
                                },
                              )
                            : GridView.builder(
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(24, 8, 24, 24),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _displayedProducts.length +
                                    (_hasMoreItems ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _displayedProducts.length) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  return _buildProductCard(
                                      _displayedProducts[index], isMobile);
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Product',
        onPressed: () => _showAddProductDialog(context),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    final activeCount = _allProducts.where((p) => p.isActive).length;
    final categoryCount = _availableCategories.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Inventory',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Inventory',
              )
            ],
          ),
          const SizedBox(height: 24),
          // Summary Metrics
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                    'Total Products',
                    '${_allProducts.length}',
                    Icons.inventory_2_outlined,
                    Colors.blueAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem('Active', '$activeCount',
                    Icons.check_circle_outline, Colors.greenAccent),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem('Categories', '$categoryCount',
                      Icons.category_outlined, Colors.orangeAccent),
                ),
              ]
            ],
          ),
          const SizedBox(height: 20), // Space for overlay
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionBar(bool isMobile) {
    return Transform.translate(
      offset: const Offset(0, -25),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isMobile
            ? Column(
                children: [
                  _buildSearchField(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _buildSortDropdown()),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showFilterDialog(context),
                        icon: const Icon(Icons.filter_list),
                        color: primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor: surfaceColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  )
                ],
              )
            : Row(
                children: [
                  Expanded(flex: 2, child: _buildSearchField()),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildSortDropdown()),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showFilterDialog(context),
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filters'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: surfaceColor,
                      foregroundColor: primaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search products by name...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProductSortOption>(
          value: _sortOption,
          isExpanded: true,
          icon: const Icon(Icons.sort, size: 20),
          items: ProductSortOption.values.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option.label, style: const TextStyle(fontSize: 13)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) _updateSort(val);
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isMobile) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductDetails(product),
        onLongPress: () => _showProductActions(context, product),
        child: isMobile
            ? _buildMobileCardLayout(product)
            : _buildDesktopCardLayout(product),
      ),
    );
  }

  Widget _buildDesktopCardLayout(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Section
        Expanded(
          flex: 5,
          child: _buildCardImage(product),
        ),
        // Info Section
        Expanded(
          flex: 4,
          child: _buildCardInfo(product),
        ),
      ],
    );
  }

  Widget _buildMobileCardLayout(Product product) {
    return Row(
      children: [
        // Image Section
        SizedBox(
          width: 120,
          height: 120,
          child: _buildCardImage(product),
        ),
        // Info Section
        Expanded(
          child: _buildCardInfo(product),
        ),
      ],
    );
  }

  Widget _buildCardImage(Product product) {
    return Container(
      color: Colors.grey[50],
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (product.imageUrl != null)
            Image.network(
              ApiService.instance.getFullImageUrl(product.imageUrl!),
              fit: BoxFit.cover,
              errorBuilder: (ctx, _, __) => const Center(
                  child: Icon(Icons.image_not_supported,
                      color: Colors.grey, size: 40)),
            )
          else
            const Center(
                child: Icon(Icons.image_not_supported,
                    color: Colors.grey, size: 40)),

          // Status Badge
          if (!product.isActive)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('INACTIVE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),

          // Offer Badge
          if (product.offerId != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(product.offerId.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (product.category?.name != null)
                Text(
                  product.category!.name,
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.offerPrice != null ||
                      product.discountedPrice != null)
                    Text(
                      '₹${product.sellingPrice}',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  Text(
                    '₹${product.discountedPrice}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (product.sizeMap != null && product.sizeMap!.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${product.sizeMap!.length} Sizes',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No products found",
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _filterOptions = const ProductFilterOptions();
                _searchController.clear();
                _applyFiltersAndSort();
              });
            },
            child: const Text("Clear Filters"),
          )
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _filterOptions.categoryName != null ||
        _filterOptions.hasImage != null ||
        _filterOptions.isActive != null ||
        _filterOptions.canListed != null ||
        _filterOptions.sizeFilter != null;
  }

  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];
    if (_filterOptions.categoryName != null) {
      chips.add(_FilterChip(
        label: 'Category: ${_filterOptions.categoryName}',
        onRemove: () => _updateFilters(categoryName: null),
      ));
    }
    if (_filterOptions.hasImage != null) {
      chips.add(_FilterChip(
        label: _filterOptions.hasImage! ? 'Has Image' : 'No Image',
        onRemove: () => _updateFilters(hasImage: null),
      ));
    }
    if (_filterOptions.isActive != null) {
      chips.add(_FilterChip(
        label: _filterOptions.isActive! ? 'Active' : 'Inactive',
        onRemove: () => _updateFilters(isActive: null),
      ));
    }
    if (_filterOptions.canListed != null) {
      chips.add(_FilterChip(
        label: _filterOptions.canListed! ? 'Listed' : 'Unlisted',
        onRemove: () => _updateFilters(canListed: null),
      ));
    }
    if (_filterOptions.sizeFilter != null) {
      chips.add(_FilterChip(
        label: 'Size: ${_filterOptions.sizeFilter}',
        onRemove: () => _updateFilters(sizeFilter: null),
      ));
    }

    // Clear All Chip
    if (chips.isNotEmpty) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ActionChip(
            label: const Text('Clear All'),
            onPressed: () {
              setState(() {
                _filterOptions = const ProductFilterOptions();
                _applyFiltersAndSort();
              });
            },
            backgroundColor: Colors.red.withOpacity(0.1),
            labelStyle: const TextStyle(color: Colors.red, fontSize: 11),
            side: BorderSide.none,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
    }

    return chips;
  }

  // --- Actions & Dialogs (Preserved from original code with minor styling updates) ---

  Future<void> _showProductActions(
      BuildContext context, Product product) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit, color: Colors.blue),
                ),
                title: const Text('Update Details'),
                onTap: () => Navigator.pop(context, 'update'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.image, color: Colors.purple),
                ),
                title: const Text('Add/Update Image'),
                onTap: () => Navigator.pop(context, 'image'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.inventory, color: Colors.orange),
                ),
                title: const Text('Update Stock/Quantity'),
                onTap: () => Navigator.pop(context, 'quantity'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: const FaIcon(FontAwesomeIcons.whatsapp,
                      color: Colors.green),
                ),
                title: const Text('Open WhatsApp Group'),
                onTap: () => Navigator.pop(context, 'whatsapp'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    switch (result) {
      case 'update':
        await _showUpdateProductDialog(context, product);
        break;
      case 'image':
        await _showImagePickerDialog(context, product);
        break;
      case 'quantity':
        await _showQuantityUpdateDialog(context, product);
        break;
      case 'whatsapp':
        await _openWhatsAppGroup(context);
        break;
    }
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.imageUrl != null)
                Center(
                  child: SizedBox(
                    height: 200,
                    child: Image.network(
                      ApiService.instance.getFullImageUrl(product.imageUrl!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _DetailRow('ID', product.id.toString()),
              _DetailRow('Category', product.category?.name ?? 'N/A'),
              _DetailRow('Unit Price', '₹${product.unitPrice}'),
              _DetailRow('Selling Price', '₹${product.sellingPrice}'),
              if (product.discountedPrice != null)
                _DetailRow('Discounted', '₹${product.discountedPrice}'),
              _DetailRow('Status', product.isActive ? 'Active' : 'Inactive'),
              const Divider(),
              const Text('Stock:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (product.sizeMap != null)
                ...product.sizeMap!.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 16, top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Size ${s.size}'),
                          Text('${s.quantity} units'),
                        ],
                      ),
                    )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods for Dialogs (Update, Quantity, Image, Whatsapp) ---
  // Keeping these implementation details as mostly standard Flutter dialogs but wrapped in standard styles if needed.
  // For brevity, assuming standard implementations similar to original code provided by user.

  Future<void> _showUpdateProductDialog(
      BuildContext context, Product product) async {
    final nameController = TextEditingController(text: product.name);
    final descController = TextEditingController(text: product.description ?? '');
    final unitPriceController =
        TextEditingController(text: product.unitPrice.toString());
    final sellingPriceController =
        TextEditingController(text: product.sellingPrice.toString());
    final discountedPriceController = TextEditingController(
        text: product.discountedPrice?.toString() ?? '');
    String? selectedCategoryName = product.category?.name;
    bool canListed = product.canListed;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              DropdownButtonFormField<String?>(
                value: selectedCategoryName,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Select Category'),
                  ),
                  ..._availableCategoriesList.map((cat) => DropdownMenuItem(
                        value: cat.name,
                        child: Text(cat.name),
                      )),
                ],
                onChanged: (val) => selectedCategoryName = val,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: unitPriceController,
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sellingPriceController,
                decoration: const InputDecoration(labelText: 'Selling Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: discountedPriceController,
                decoration: const InputDecoration(labelText: 'Discounted Price'),
                keyboardType: TextInputType.number,
              ),
              CheckboxListTile(
                value: canListed,
                onChanged: (val) => canListed = val ?? true,
                title: const Text('Can be listed'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate required fields
              if (nameController.text.isEmpty ||
                  unitPriceController.text.isEmpty ||
                  sellingPriceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              try {
                final updatedProduct = Product(
                  id: product.id,
                  name: nameController.text,
                  description: descController.text,
                  category: selectedCategoryName != null
                      ? _availableCategoriesList.firstWhere(
                          (cat) => cat.name == selectedCategoryName,
                          orElse: () => product.category!)
                      : product.category,
                  categoryId: product.categoryId,
                  unitPrice: int.tryParse(unitPriceController.text) ?? 0,
                  sellingPrice: int.tryParse(sellingPriceController.text) ?? 0,
                  discountedPrice: int.tryParse(discountedPriceController.text) ?? 0,
                  offerPrice: product.offerPrice,
                  offerId: product.offerId,
                  canListed: canListed,
                  isActive: product.isActive,
                  imageUrl: product.imageUrl,
                  sizeMap: product.sizeMap,
                );

                await ProductService().updateProduct(
                  context,
                  product.id,
                  updatedProduct.toJson(),
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                _loadProducts(); // Refresh the list
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating product: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePickerDialog(
      BuildContext context, Product product) async {
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (result != null) {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: result == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );

        if (image != null) {
          // For web, we need to use readAsBytes() instead of file path
          // For mobile, we can use the file path directly
          if (image.path.startsWith('blob:')) {
            // Web platform - use bytes
            final bytes = await image.readAsBytes();
            await ApiService.instance.uploadProductImageBytes(
                context, product.id, bytes, image.name);
          } else {
            // Mobile platform - use file path
            await ApiService.instance
                .uploadProductImage(context, product.id, image.path);
          }

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
          _loadProducts(); // Refresh the list
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  final Map<String, List<String>> sizeConfig = {
    'Jersey': ['S', 'M', 'L', 'XL', 'XXL'],
    'Five Sleeve Jersey': ['S', 'M', 'L', 'XL', 'XXL'],
    'Full Sleeve Jersey': ['S', 'M', 'L', 'XL', 'XXL'],
    'Kids Jersey': ['20', '22', '24', '26', '28', '30', '32', '34'],
    'First Copy Jersey': ['S', 'M', 'L', 'XL', 'XXL'],
    'Tshirt': ['S', 'M', 'L', 'XL', 'XXL'],
    'Dotknit Shorts - Embroidery': ['S', 'M', 'L', 'XL', 'XXL'],
    'Dotknit Shorts - Submiation': ['S', 'M', 'L', 'XL', 'XXL'],
    'Dotknit Shorts - Plain': ['S', 'M', 'L', 'XL', 'XXL'],
    'PP Shorts - Plain': ['S', 'M', 'L', 'XL', 'XXL'],
    'PP Shorts - Embroidery': ['S', 'M', 'L', 'XL', 'XXL'],
    'FC Shorts': ['S', 'M', 'L', 'XL', 'XXL'],
    'NS Shorts': ['S', 'M', 'L', 'XL', 'XXL'],
    'Sleeve Less - D/N': ['S', 'M', 'L', 'XL', 'XXL'],
    'Sleeve Less - Saleena': ['S', 'M', 'L', 'XL', 'XXL'],
    'Sleeve Less - Other': ['S', 'M', 'L', 'XL', 'XXL'],
    'Sleeve Less - NS': ['S', 'M', 'L', 'XL', 'XXL'],
    'Track Pants - Imp': ['S', 'M', 'L', 'XL', 'XXL'],
    'Track Pants - Normal': ['S', 'M', 'L', 'XL', 'XXL'],
    'Boot-Adult': [
      '5',
      '5.5',
      '6',
      '6.5',
      '7',
      '7.5',
      '8',
      '8.5',
      '9',
      '9.5',
      '10',
      '10.5',
      '11'
    ],
    'Boot-Kids': ['-13', '-12', '-11', '1', '2', '3', '4'],
    'Boot-Imp': [
      '5',
      '5.5',
      '6',
      '6.5',
      '7',
      '7.5',
      '8',
      '8.5',
      '9',
      '9.5',
      '10',
      '10.5',
      '11'
    ],
    'Shorts-Kids': ['20', '22', '24', '26', '28', '30', '32', '34'],
    'Football': ['3', '4', '5'],
    'Cricket Ball': ['Standard'],
    'Shuttle Bat': ['Standard'],
    'Shuttle Cock': ['Standard'],
    'Foot Pad': ['Free Size'],
    'Foot sleeve': ['Free Size'],
    'Socks-Full': ['Free Size'],
    'Socks-3/4': ['Free Size'],
    'Socks-Half': ['Free Size'],
    'Socks-Ankle': ['Free Size'],
    'Hand Sleeve': ['Free Size'],
    'GK Glove': [
      '5.5',
      '6',
      '6.5',
      '7',
      '7.5',
      '8',
      '8.5',
      '9',
      '9.5',
      '10',
      '10.5',
      '11'
    ],
    'Trophy': ['Small', 'Medium', 'Large'],
  };

  Future<void> _showQuantityUpdateDialog(
      BuildContext context, Product product) async {
    final Map<String, TextEditingController> standardControllers = {};
    final Map<String, TextEditingController> customSizeControllers = {};
    final Map<String, TextEditingController> customQtyControllers = {};
    final Map<String, int> currentQuantities = {};

    // Get standard sizes for this category
    final categoryName = product.category?.name ?? '';
    final standardSizes = sizeConfig[categoryName] ?? [];
    final standardSizeSet = standardSizes.toSet();

    // Initialize standard size controllers
    for (final size in standardSizes) {
      final sizeMapList = product.sizeMap ?? [];
      ProductSize? existingSize;
      try {
        existingSize = sizeMapList.firstWhere((s) => s.size == size);
      } catch (e) {
        existingSize = null;
      }
      standardControllers[size] = TextEditingController(
        text: (existingSize?.quantity ?? 0).toString(),
      );
    }

    // Initialize custom size controllers (sizes not in standard list)
    int customIndex = 0;
    for (final size in product.sizeMap ?? []) {
      if (!standardSizeSet.contains(size.size)) {
        customSizeControllers['custom_$customIndex'] = TextEditingController(
          text: size.size,
        );
        customQtyControllers['custom_$customIndex'] = TextEditingController(
          text: size.quantity.toString(),
        );
        currentQuantities['custom_$customIndex'] = size.quantity;
        customIndex++;
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Product Quantity for ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Standard Sizes Section
                const Text(
                  'Standard Sizes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (standardControllers.isNotEmpty)
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: standardControllers.entries
                        .map((entry) => SizedBox(
                              width: 130,
                              child: TextField(
                                controller: entry.value,
                                decoration: InputDecoration(
                                  labelText: '${entry.key} Quantity',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ))
                        .toList(),
                  )
                else
                  const Text('No standard sizes for this category',
                      style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                // Custom Sizes Section
                const Text(
                  'Custom Sizes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Custom Size Entries
                ...List.generate(customSizeControllers.length, (index) {
                  final key = 'custom_$index';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: customSizeControllers[key],
                            decoration: const InputDecoration(
                              labelText: 'Size Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: customQtyControllers[key],
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              customSizeControllers[key]?.dispose();
                              customQtyControllers[key]?.dispose();
                              customSizeControllers.remove(key);
                              customQtyControllers.remove(key);
                              currentQuantities.remove(key);
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Size'),
                  onPressed: () {
                    setState(() {
                      final nextIndex = customSizeControllers.length;
                      customSizeControllers['custom_$nextIndex'] =
                          TextEditingController();
                      customQtyControllers['custom_$nextIndex'] =
                          TextEditingController(text: '0');
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        final Map<String, int> updatedSizeMap = {};

        // Add standard sizes
        standardControllers.forEach((size, controller) {
          updatedSizeMap[size] = int.tryParse(controller.text) ?? 0;
        });

        // Add custom sizes (filter out empty size names)
        for (int i = 0; i < customSizeControllers.length; i++) {
          final key = 'custom_$i';
          final sizeName = customSizeControllers[key]?.text ?? '';
          if (sizeName.isNotEmpty) {
            updatedSizeMap[sizeName] =
                int.tryParse(customQtyControllers[key]?.text ?? '0') ?? 0;
          }
        }

        await ApiService.instance
            .updateSizeMap(context, product.id, updatedSizeMap);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantities updated successfully')),
        );
        _loadProducts(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating quantities: $e')),
        );
      }
    }

    // Dispose all controllers
    for (final controller in standardControllers.values) {
      controller.dispose();
    }
    for (final controller in customSizeControllers.values) {
      controller.dispose();
    }
    for (final controller in customQtyControllers.values) {
      controller.dispose();
    }
  }

  Future<void> _openWhatsAppGroup(BuildContext context) async {
    const whatsappUrl = 'YOUR_WHATSAPP_GROUP_URL'; // Replace with actual URL
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

Future<void> _showAddProductDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final unitPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final discountedPriceController = TextEditingController();
  String? selectedCategoryId;
  bool canListed = true;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add New Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            DropdownButtonFormField<String?>(
              value: selectedCategoryId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Select Category'),
                ),
                ..._availableCategoriesList.map((cat) => DropdownMenuItem(
                      value: cat.id.toString(),
                      child: Text(cat.name),
                    )),
              ],
              onChanged: (val) => selectedCategoryId = val,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: unitPriceController,
              decoration: const InputDecoration(labelText: 'Unit Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: sellingPriceController,
              decoration: const InputDecoration(labelText: 'Selling Price'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: discountedPriceController,
              decoration: const InputDecoration(labelText: 'Discounted Price'),
              keyboardType: TextInputType.number,
            ),
            CheckboxListTile(
              value: canListed,
              onChanged: (val) => canListed = val ?? true,
              title: const Text('Can be listed'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Validate
            if (nameController.text.isEmpty ||
                selectedCategoryId == null ||
                unitPriceController.text.isEmpty ||
                sellingPriceController.text.isEmpty ||
                discountedPriceController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all required fields')),
              );
              return;
            }
            
            // Find category object from list by name
            Category? selectedCategory;
            try {
              selectedCategory = _availableCategoriesList
                  .firstWhere((cat) => cat.id == int.parse(selectedCategoryId!));
            } catch (e) {
              selectedCategory = null;
            }

            if (selectedCategory == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected category not found')),
              );
              return;
            }

            final newProduct = Product(
              id: 0,
              name: nameController.text,
              description: descController.text,
              category: selectedCategory,
              categoryId: selectedCategory.id,
              unitPrice: int.tryParse(unitPriceController.text) ?? 0,
              sellingPrice: int.tryParse(sellingPriceController.text) ?? 0,
              discountedPrice: int.tryParse(discountedPriceController.text) ?? 0,
              canListed: canListed,
              isActive: true,
              imageUrl: null,
              sizeMap: [], offerPrice: 0,
            );
            debugPrint('Adding product: ${newProduct.toJson()}');
            try {
              await ProductService().addProduct(context, newProduct);
              // Navigator.pop(context);
              // _loadProducts();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error adding product: $e')),
              );
            }
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}


}

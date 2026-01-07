import 'package:flutter/material.dart';
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

    if (categoryName != null && 
        (product.category?.name != categoryName)) {
      return false;
    }

    if (hasImage != null) {
      final hasProductImage = product.imageUrl != null && product.imageUrl!.isNotEmpty;
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
        s.size.toLowerCase() == sizeFilter!.toLowerCase() && s.quantity > 0
      );
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
        backgroundColor: Colors.white.withOpacity(0.2),
        labelStyle: const TextStyle(color: Colors.white),
        deleteIconColor: Colors.white,
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
  final int _pageSize = 10;
  int _currentPage = 0;

  // Filter and sort state
  ProductFilterOptions _filterOptions = const ProductFilterOptions();
  ProductSortOption _sortOption = ProductSortOption.sellingPriceAsc;
  Set<String> _availableCategories = {};
  Set<String> _availableSizes = {};

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

  void _updateAvailableFilters() {
    _availableCategories = _allProducts
        .where((p) => p.category?.name != null)
        .map((p) => p.category!.name)
        .toSet();

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
                const Text('Category'),
                DropdownButton<String?>(
                  value: selectedCategory,
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
                    setState(() => selectedCategory = value);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Image Filter
              const Text('Image'),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Has Image')),
                  ButtonSegment(value: false, label: Text('No Image')),
                ],
                selected: {hasImage},
                onSelectionChanged: (Set<bool?> newValue) {
                  setState(() => hasImage = newValue.first);
                },
              ),
              const SizedBox(height: 16),

              // Active Status
              const Text('Status'),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Active')),
                  ButtonSegment(value: false, label: Text('Inactive')),
                ],
                selected: {isActive},
                onSelectionChanged: (Set<bool?> newValue) {
                  setState(() => isActive = newValue.first);
                },
              ),
              const SizedBox(height: 16),

              // Listed Status
              const Text('Listing'),
              SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment(value: null, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Listed')),
                  ButtonSegment(value: false, label: Text('Not Listed')),
                ],
                selected: {canListed},
                onSelectionChanged: (Set<bool?> newValue) {
                  setState(() => canListed = newValue.first);
                },
              ),
              const SizedBox(height: 16),

              // Size Filter
              if (_availableSizes.isNotEmpty) ...[
                const Text('Size'),
                DropdownButton<String?>(
                  value: selectedSize,
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
                    setState(() => selectedSize = value);
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
          TextButton(
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
            child: const Text('Apply'),
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

  bool get _hasMoreItems => _currentPage * _pageSize < _allProducts.length;

  void _loadNextPage() {
    if (_isLoading) return;

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
      _displayedProducts = [];
      _currentPage = 0;
    });

    try {
      final List<dynamic> response = await ApiService.instance.getProducts(context);

      if (mounted) {
        final products = <Product>[];

        for (final item in response) {
          try {
            if (item is Map<String, dynamic>) {
              try {
                // Attempt to parse the product with required and optional properties
                final sanitizedJson = <String, dynamic>{
                  'id': int.tryParse(item['id']?.toString() ?? '') ?? 0,
                  'name': item['name']?.toString() ?? 'Unnamed Product',
                  'image_url': item['image_url']?.toString(),
                  'description': item['description']?.toString(),
                  'unit_price': item['unit_price'] != null
                      ? int.tryParse(item['unit_price'].toString()) ?? 0
                      : 0,
                  'selling_price': item['selling_price'] != null
                      ? int.tryParse(item['selling_price'].toString()) ?? 0
                      : 0,
                  'category_id': item['category_id'] != null
                      ? int.tryParse(item['category_id'].toString()) ?? 0
                      : 0,
                  'is_active': item['is_active'] == true || item['is_active']?.toString() == 'true',
                  'can_listed': item['can_listed'] == true || item['can_listed']?.toString() == 'true',
                  'category': item['category'] is Map<String, dynamic>
                      ? {
                          'name': item['category']['name']?.toString() ?? '',
                          'description': item['category']['description']?.toString(),
                        }
                      : null,
                  'discounted_price': item['discounted_price'] != null
                      ? int.tryParse(item['discounted_price'].toString())
                      : null,
                  'offer_id': item['offer_id'] != null
                      ? int.tryParse(item['offer_id'].toString())
                      : null,
                  'offer_price': item['offer_price'] != null
                      ? int.tryParse(item['offer_price'].toString())
                      : null,
                  'offer_name': item['offer_name']?.toString(),
                  'size_map': (item['size_map'] as List<dynamic>?)?.map((size) => {
                        'size': size['size']?.toString() ?? '',
                        'quantity': int.tryParse(size['quantity']?.toString() ?? '0') ?? 0,
                      }).toList(),
                };

              products.add(Product.fromJson(sanitizedJson));
              } catch (e) {
                print('1 Error parsing product: $e');
                print(item);
                continue;
              }
              // Ensure required numeric fields have default values if null
              // Convert and sanitize all numeric fields
              
            }
          } catch (itemError) {
            print('Error parsing product: $itemError');
            // Continue with next product if one fails to parse
            continue;
          }
        }

        setState(() {
          _allProducts = products;
          _updateAvailableFilters();
          _isLoading = false;
          _applyFiltersAndSort(); // This will trigger _loadNextPage
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: ${e.toString()}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    
    int crossAxisCount;
    double childAspectRatio;
    double spacing;
    double padding;

    if (isMobile) {
      crossAxisCount = 1;
      childAspectRatio = 1.3;
      spacing = 12;
      padding = 12;
    } else if (isTablet) {
      crossAxisCount = 2;
      childAspectRatio = 1.1;
      spacing = 14;
      padding = 14;
    } else {
      crossAxisCount = 3;
      childAspectRatio = 0.9;
      spacing = 16;
      padding = 16;
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Sort Button
          PopupMenuButton<ProductSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: _updateSort,
            itemBuilder: (context) => ProductSortOption.values
                .map((option) => PopupMenuItem(
                      value: option,
                      child: Text(option.label),
                    ))
                .toList(),
          ),
          // Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_filterOptions.categoryName != null)
                    _FilterChip(
                      label: 'Category: ${_filterOptions.categoryName}',
                      onRemove: () => _updateFilters(categoryName: null),
                    ),
                  if (_filterOptions.hasImage != null)
                    _FilterChip(
                      label: _filterOptions.hasImage! ? 'Has Image' : 'No Image',
                      onRemove: () => _updateFilters(hasImage: null),
                    ),
                  if (_filterOptions.isActive != null)
                    _FilterChip(
                      label: _filterOptions.isActive! ? 'Active' : 'Inactive',
                      onRemove: () => _updateFilters(isActive: null),
                    ),
                  if (_filterOptions.canListed != null)
                    _FilterChip(
                      label: _filterOptions.canListed! ? 'Listed' : 'Not Listed',
                      onRemove: () => _updateFilters(canListed: null),
                    ),
                  if (_filterOptions.sizeFilter != null)
                    _FilterChip(
                      label: 'Size: ${_filterOptions.sizeFilter}',
                      onRemove: () => _updateFilters(sizeFilter: null),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredProducts.isEmpty && _allProducts.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No products match the selected filters'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterOptions = const ProductFilterOptions();
                            _searchController.clear();
                            _applyFiltersAndSort();
                          });
                        },
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _displayedProducts.clear();
                  _allProducts.clear();
                  _currentPage = 0;
                });
                await _loadProducts();
              },
              child: GridView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(padding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: _displayedProducts.length + (_hasMoreItems ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _displayedProducts.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final product = _displayedProducts[index];
                  print('product: $product');
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _showProductDetails(product),
                      onLongPress: () => _showProductActions(context, product),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: isMobile ? 80 : 120,
                            width: double.infinity,
                            child: product.imageUrl != null
                                ? Image.network(
                                    ApiService.instance.getFullImageUrl(product.imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      ),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: ClipRect(
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 8 : 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        product.name,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontSize: isMobile ? 12 : 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${product.offerPrice ?? product.discountedPrice ?? product.sellingPrice}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: (product.offerPrice != null || product.discountedPrice != null) ? Colors.red : null,
                                      ),
                                    ),
                                    if (product.offerName != null) ...[
                                      const SizedBox(height: 1),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                            vertical: 0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            product.offerName!,
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontSize: 8,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (product.sizeMap != null && product.sizeMap!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Flexible(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: product.sizeMap!
                                                .where((size) => size.quantity > 0)
                                                .take(4)
                                                .map((size) => Padding(
                                                  padding: const EdgeInsets.only(right: 2),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 3,
                                                      vertical: 1,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey.shade100,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                    child: Text(
                                                      size.size,
                                                      style: TextStyle(
                                                        color: Colors.grey.shade700,
                                                        fontSize: 9,
                                                      ),
                                                    ),
                                                  ),
                                                ))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _showProductActions(BuildContext context, Product product) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Update Details'),
                onTap: () {
                  Navigator.pop(context, 'update');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Add Image'),
                onTap: () {
                  Navigator.pop(context, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Update Quantity'),
                onTap: () {
                  Navigator.pop(context, 'quantity');
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.whatsapp),
                title: const Text('Open WhatsApp Group'),
                onTap: () {
                  Navigator.pop(context, 'whatsapp');
                },
              ),
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

  Future<void> _showUpdateProductDialog(BuildContext context, Product product) async {
    final nameController = TextEditingController(text: product.name);
    final descController = TextEditingController(text: product.description);
    final unitPriceController = TextEditingController(text: product.unitPrice.toString());
    final sellingPriceController = TextEditingController(text: product.sellingPrice.toString());
    
    final result = await showDialog<bool>(
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
                maxLines: 2,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Active:'),
                  Switch(
                    value: product.isActive,
                    onChanged: (value) {
                      setState(() => product = Product(
                        id: product.id,
                        name: product.name,
                        description: product.description,
                        unitPrice: product.unitPrice,
                        sellingPrice: product.sellingPrice,
                        isActive: value,
                        canListed: product.canListed,
                        categoryId: product.categoryId,
                        category: product.category,
                        imageUrl: product.imageUrl,
                        offerId: product.offerId,
                        offerPrice: product.offerPrice,
                        offerName: product.offerName,
                        discountedPrice: product.discountedPrice,
                        sizeMap: product.sizeMap,
                      ));
                    },
                  ),
                  const SizedBox(width: 16),
                  const Text('Can List:'),
                  Switch(
                    value: product.canListed,
                    onChanged: (value) {
                      setState(() => product = Product(
                        id: product.id,
                        name: product.name,
                        description: product.description,
                        unitPrice: product.unitPrice,
                        sellingPrice: product.sellingPrice,
                        isActive: product.isActive,
                        canListed: value,
                        categoryId: product.categoryId,
                        category: product.category,
                        imageUrl: product.imageUrl,
                        offerId: product.offerId,
                        offerPrice: product.offerPrice,
                        offerName: product.offerName,
                        discountedPrice: product.discountedPrice,
                        sizeMap: product.sizeMap,
                      ));
                    },
                  ),
                ],
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
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final updatedData = {
          'name': nameController.text,
          'description': descController.text,
          'unit_price': int.parse(unitPriceController.text),
          'selling_price': int.parse(sellingPriceController.text),
          'is_active': product.isActive,
          'can_listed': product.canListed,
          'category_id': product.categoryId,
        };

        await ApiService.instance.updateProduct(context, product.id, updatedData);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        _loadProducts(); // Refresh the list
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  Future<void> _showImagePickerDialog(BuildContext context, Product product) async {
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
            await ApiService.instance.uploadProductImageBytes(context, product.id, bytes, image.name);
          } else {
            // Mobile platform - use file path
            await ApiService.instance.uploadProductImage(context, product.id, image.path);
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
    'Boot-Adult': ['5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11'],
    'Boot-Kids': ['-13', '-12', '-11', '1', '2', '3', '4'],
    'Boot-Imp': ['5', '5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11'],
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
    'GK Glove': ['5.5', '6', '6.5', '7', '7.5', '8', '8.5', '9', '9.5', '10', '10.5', '11'],
    'Trophy': ['Small', 'Medium', 'Large'],
  };

  Future<void> _showQuantityUpdateDialog(BuildContext context, Product product) async {
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
      ProductSizeBase? existingSize;
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
                    children: standardControllers.entries.map((entry) => SizedBox(
                      width: 130,
                      child: TextField(
                        controller: entry.value,
                        decoration: InputDecoration(
                          labelText: '${entry.key} Quantity',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    )).toList(),
                  )
                else
                  const Text('No standard sizes for this category', style: TextStyle(color: Colors.grey)),
                
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
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
                      customSizeControllers['custom_$nextIndex'] = TextEditingController();
                      customQtyControllers['custom_$nextIndex'] = TextEditingController(text: '0');
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
            updatedSizeMap[sizeName] = int.tryParse(customQtyControllers[key]?.text ?? '0') ?? 0;
          }
        }

        await ApiService.instance.updateSizeMap(context, product.id, updatedSizeMap);
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

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        ApiService.instance.getFullImageUrl(product.imageUrl),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow('ID', product.id.toString()),
                      if (product.category != null) _DetailRow('Category', product.category!.name),
                      if (product.description != null) _DetailRow('Description', product.description!),
                      _DetailRow('Unit Price', '₹${product.unitPrice}'),
                      _DetailRow('Selling Price', '₹${product.sellingPrice}'),
                      if (product.discountedPrice != null) _DetailRow('Discounted Price', '₹${product.discountedPrice}'),
                      if (product.offerId != null) _DetailRow('Offer ID', product.offerId.toString()),
                      if (product.offerPrice != null) _DetailRow('Offer Price', '₹${product.offerPrice}'),
                      if (product.offerName != null) _DetailRow('Offer', product.offerName!),
                      _DetailRow('Status', product.isActive ? 'Active' : 'Inactive'),
                      _DetailRow('Can be Listed', product.canListed ? 'Yes' : 'No'),
                      if (product.sizeMap != null) _DetailRow(
                        'Sizes Available', 
                        product.sizeMap!.isEmpty 
                            ? 'No sizes available' 
                            : product.sizeMap!.map((s) => '${s.size}: ${s.quantity}').join(', ')
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

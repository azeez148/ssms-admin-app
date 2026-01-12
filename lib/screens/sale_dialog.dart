import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_admin_app/models/sale.dart';
import 'package:flutter_admin_app/models/product.dart';
import 'package:flutter_admin_app/services/sale_service.dart';
import 'package:flutter_admin_app/services/product_service.dart';
import 'package:flutter_admin_app/services/api_service.dart';

class SaleDialog extends StatefulWidget {
  final Sale? sale;
  final Function(SaleCreate) onSaleCreated;

  const SaleDialog({
    Key? key,
    this.sale,
    required this.onSaleCreated,
  }) : super(key: key);

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  // Services
  final SaleService _saleService = SaleService();
  final ProductService _productService = ProductService();

  // Controllers
  late TextEditingController customerNameController;
  late TextEditingController customerAddressController;
  late TextEditingController customerMobileController;
  late TextEditingController customerEmailController;
  late TextEditingController dateController;
  late TextEditingController paymentRefController;
  late TextEditingController totalPriceController;
  late TextEditingController searchController;

  // Data
  List<Product> allProducts = [];
  List<SaleItem> allSaleItems = [];
  List<SaleItem> filteredSaleItems = [];
  List<SaleItem> selectedItems = [];
  List<PaymentType> paymentTypes = [];
  List<DeliveryType> deliveryTypes = [];
  Set<String> categories = {};
  Map<int, String?> productImages = {};

  // State Variables
  String selectedCategory = 'All';
  PaymentType? selectedPaymentType;
  DeliveryType? selectedDeliveryType;
  DateTime selectedDate = DateTime.now();

  bool isLoading = true;
  bool isSaving = false;
  bool isTotalPriceEdited = false;

  // Totals
  double subTotal = 0;
  double deliveryCharge = 0;
  double totalDiscount = 0;
  double totalPrice = 0;

  // Styling Constants
  final Color primaryColor = const Color(0xFF2A2D3E);
  final Color accentColor = const Color(0xFF2196F3);
  final Color surfaceColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    customerNameController =
        TextEditingController(text: widget.sale?.customerName ?? '');
    customerAddressController =
        TextEditingController(text: widget.sale?.customerAddress ?? '');
    customerMobileController =
        TextEditingController(text: widget.sale?.customerMobile ?? '');
    customerEmailController =
        TextEditingController(text: widget.sale?.customerEmail ?? '');
    dateController = TextEditingController(
        text: widget.sale?.date ??
            DateFormat('yyyy-MM-dd').format(DateTime.now()));
    paymentRefController =
        TextEditingController(text: widget.sale?.paymentReferenceNumber ?? '');
    totalPriceController = TextEditingController(
        text: (widget.sale?.totalPrice ?? 0).toStringAsFixed(2));
    searchController = TextEditingController();
  }

  Future<void> _loadData() async {
    try {
      final products = await _productService.getProducts();
      final paymentTypesList = await _saleService.getPaymentTypes();
      final deliveryTypesList = await _saleService.getDeliveryTypes();

      _convertProductsToSaleItems(products);

      if (widget.sale != null && (widget.sale!.saleItems?.isNotEmpty == true)) {
        selectedItems = List<SaleItem>.from(widget.sale!.saleItems ?? []);
        isTotalPriceEdited = true;
        totalPrice = widget.sale!.totalPrice;
      }

      setState(() {
        allProducts = products;
        paymentTypes = paymentTypesList;
        deliveryTypes = deliveryTypesList;

        selectedPaymentType =
            widget.sale?.paymentType ?? paymentTypes.firstOrNull;
        selectedDeliveryType =
            widget.sale?.deliveryType ?? deliveryTypes.firstOrNull;

        filteredSaleItems = List.from(allSaleItems);
        isLoading = false;
      });

      _updateTotals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => isLoading = false);
      }
    }
  }

  void _convertProductsToSaleItems(List<Product> products) {
    allSaleItems = [];
    categories.clear();
    categories.add('All'); // Add default
    productImages.clear();

    for (final p in products) {
      if (p.category?.name != null) categories.add(p.category!.name);
      productImages[p.id] = p.imageUrl;

      if (p.sizeMap == null || p.sizeMap!.isEmpty) {
        allSaleItems.add(SaleItem(
          productId: p.id,
          productName: p.name,
          productCategory: p.category?.name ?? '',
          size: 'Free Size',
          quantityAvailable: 1,
          quantity: 1,
          salePrice:
              p.discountedPrice?.toDouble() ?? p.sellingPrice.toDouble(),
          totalPrice: 0,
        ));
      } else {
        for (final s in p.sizeMap!) {
          if (s.quantity > 0) {
            allSaleItems.add(SaleItem(
              productId: p.id,
              productName: p.name,
              productCategory: p.category?.name ?? '',
              size: s.size,
              quantityAvailable: s.quantity,
              quantity: 1,
              salePrice: p.discountedPrice?.toDouble() ??
                  p.sellingPrice.toDouble(),
              totalPrice: 0,
            ));
          }
        }
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredSaleItems = allSaleItems.where((item) {
        final matchCategory = selectedCategory == 'All'
            ? true
            : item.productCategory == selectedCategory;
        final matchSearch = item.productName
            .toLowerCase()
            .contains(searchController.text.toLowerCase());
        return matchCategory && matchSearch;
      }).toList();
    });
  }

  void _addToCart(SaleItem item) {
    final existingIndex = selectedItems.indexWhere(
        (i) => i.productId == item.productId && i.size == item.size);

    setState(() {
      if (existingIndex != -1) {
        // Item exists, increment
        if (selectedItems[existingIndex].quantity < item.quantityAvailable) {
          selectedItems[existingIndex].quantity++;
          selectedItems[existingIndex].totalPrice =
              selectedItems[existingIndex].quantity *
                  selectedItems[existingIndex].salePrice;
        }
      } else {
        // New item
        selectedItems.add(
          item.copyWith(
            quantity: 1,
            totalPrice: item.salePrice,
          ),
        );
      }
      _updateTotals();
    });
  }

  void _removeFromCart(SaleItem item) {
    setState(() {
      selectedItems.removeWhere(
          (i) => i.productId == item.productId && i.size == item.size);
      _updateTotals();
    });
  }

  void _updateItemQuantity(SaleItem item, int delta) {
    setState(() {
      if (delta > 0) {
        if (item.quantity < item.quantityAvailable) {
          item.quantity++;
        }
      } else {
        if (item.quantity > 1) {
          item.quantity--;
        } else {
          _removeFromCart(item);
          return; // Exit early as item is removed
        }
      }
      item.totalPrice = item.quantity * item.salePrice;
      _updateTotals();
    });
  }

  void _updateTotals() {
    subTotal = selectedItems.fold(0, (s, i) => s + (i.salePrice * i.quantity));
    deliveryCharge = (selectedDeliveryType?.charge ?? 0).toDouble();

    if (!isTotalPriceEdited) {
      totalPrice = subTotal + deliveryCharge;
      totalPriceController.text = totalPrice.toStringAsFixed(2);
    } else {
      // If manually edited, keep the manual value but calculate discount relative to it
    }

    // Logic: Actual Total (Sub+Del) - Charged Total = Discount Given
    totalDiscount = (subTotal + deliveryCharge) - totalPrice;
  }

  void _save() async {
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cart is empty. Add items to proceed.')));
      return;
    }
    if (customerNameController.text.trim().isEmpty ||
        customerMobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Customer Name and Mobile are required.')));
      return;
    }

    setState(() => isSaving = true);

    final saleItems = selectedItems.map((item) {
      return SaleItemCreate(
        productId: item.productId,
        productName: item.productName,
        productCategory: item.productCategory,
        size: item.size,
        quantityAvailable: item.quantityAvailable,
        quantity: item.quantity,
        salePrice: item.salePrice,
        totalPrice: item.salePrice * item.quantity,
      );
    }).toList();

    final saleCreate = SaleCreate(
      date: dateController.text,
      totalQuantity: selectedItems.fold(0, (sum, i) => sum + i.quantity),
      totalPrice: totalPrice,
      paymentTypeId: selectedPaymentType!.id,
      paymentReferenceNumber: paymentRefController.text.isEmpty
          ? null
          : paymentRefController.text,
      deliveryTypeId: selectedDeliveryType!.id,
      shopId: 1,
      customerId: 0,
      customerName: customerNameController.text.trim(),
      customerAddress: customerAddressController.text.trim().isEmpty
          ? null
          : customerAddressController.text.trim(),
      customerMobile: customerMobileController.text.trim(),
      customerEmail: customerEmailController.text.trim().isEmpty
          ? null
          : customerEmailController.text.trim(),
      saleItems: saleItems,
      status: SaleStatus.completed,
    );

    try {
      await _saleService.addSale(saleCreate);
      widget.onSaleCreated(saleCreate);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsiveness
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 900; // Breakpoint for Mobile/Tablet

    return Dialog(
      insetPadding: isMobile
          ? EdgeInsets.zero // Fullscreen on mobile
          : const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 0 : 16)),
      backgroundColor: surfaceColor,
      child: isLoading
          ? const SizedBox(
              height: 300, child: Center(child: CircularProgressIndicator()))
          : isMobile
              ? _buildMobileLayout(size)
              : _buildDesktopLayout(size),
    );
  }

  // --- Layouts ---

  Widget _buildDesktopLayout(Size size) {
    return SizedBox(
      width: size.width * 0.95,
      height: size.height * 0.9,
      child: Row(
        children: [
          // LEFT SIDE: Product Catalog
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopTopBar(),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  _buildProductGrid(),
                ],
              ),
            ),
          ),
          // Vertical Divider
          Container(width: 1, color: Colors.grey[300]),
          // RIGHT SIDE: Cart / Order Ticket
          Expanded(
            flex: 3,
            child: _buildCartSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Size size) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: surfaceColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text("New Sale", style: TextStyle(color: Colors.black)),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
          bottom: TabBar(
            labelColor: accentColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: accentColor,
            tabs: [
              const Tab(text: "Products"),
              Tab(
                  text: selectedItems.isEmpty
                      ? "Cart"
                      : "Cart (${selectedItems.length})"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Catalog
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildSearchBar(),
                  ),
                  _buildCategorySelector(),
                  const SizedBox(height: 10),
                  _buildProductGrid(),
                ],
              ),
            ),
            // Tab 2: Cart
            _buildCartSection(),
          ],
        ),
      ),
    );
  }

  // --- Components ---

  Widget _buildDesktopTopBar() {
    return Row(
      children: [
        const Icon(Icons.point_of_sale, size: 28, color: Colors.black87),
        const SizedBox(width: 12),
        const Text(
          "New Sale",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        // Search Bar
        SizedBox(
          width: 300,
          height: 45,
          child: _buildSearchBar(),
        ),
        const SizedBox(width: 16),
        IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      onChanged: (_) => _applyFilters(),
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = categories.elementAt(index);
          final isSelected = selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() {
                selectedCategory = cat;
                _applyFilters();
              });
            },
            selectedColor: accentColor,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: surfaceColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (filteredSaleItems.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 64, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text("No products found",
                  style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    // Dynamic Grid Count based on width
    int crossAxisCount = 3;
    double width = MediaQuery.of(context).size.width;
    if (width < 600) crossAxisCount = 2; // Mobile
    if (width > 1200) crossAxisCount = 4; // Large Desktop

    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: filteredSaleItems.length,
        itemBuilder: (context, index) {
          final item = filteredSaleItems[index];
          final hasImage = productImages[item.productId] != null &&
              productImages[item.productId]!.isNotEmpty;

          return InkWell(
            onTap: () => _addToCart(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Container(
                        color: Colors.grey[100],
                        child: hasImage
                            ? Image.network(
                                ApiService.instance.getFullImageUrl(
                                    productImages[item.productId]!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 40),
                              )
                            : const Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Info
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(item.size,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.black54)),
                              ),
                              Text(
                                "₹${item.salePrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Right Side / Cart Widgets ---

  Widget _buildCartSection() {
    return Column(
      children: [
        // Customer Header
        _buildCustomerHeader(),
        const Divider(height: 1),
        // Cart Items List
        Expanded(child: _buildCartItemsList()),
        const Divider(height: 1),
        // Payment & Totals
        _buildCheckoutArea(),
      ],
    );
  }

  Widget _buildCustomerHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 20),
              const SizedBox(width: 8),
              const Text("Customer Details",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  customerNameController.text = "In-store Customer";
                  customerAddressController.text = "In-store";
                  customerMobileController.text = "0000000000";
                },
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: const Text("Walk-in"),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customerNameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: customerMobileController,
                  decoration: const InputDecoration(
                    labelText: "Mobile",
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemsList() {
    if (selectedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text("Cart is empty", style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
    }

    return Container(
      color: surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: selectedItems.length,
        itemBuilder: (context, index) {
          final item = selectedItems[index];
          return Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Qty Controls
                  Column(
                    children: [
                      InkWell(
                        onTap: () => _updateItemQuantity(item, 1),
                        child: Icon(Icons.keyboard_arrow_up,
                            size: 20, color: Colors.grey[600]),
                      ),
                      Text(
                        "${item.quantity}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      InkWell(
                        onTap: () => _updateItemQuantity(item, -1),
                        child: Icon(Icons.keyboard_arrow_down,
                            size: 20, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Item Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          "${item.size}  •  ₹${item.salePrice.toStringAsFixed(0)}",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${(item.salePrice * item.quantity).toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                          onTap: () => _removeFromCart(item),
                          child: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.redAccent)),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          // Selectors
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Payment Method
                ...paymentTypes.map((pt) {
                  final isSelected = selectedPaymentType == pt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(pt.name),
                      selected: isSelected,
                      onSelected: (val) =>
                          setState(() => selectedPaymentType = pt),
                      checkmarkColor: Colors.white,
                      selectedColor: primaryColor,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Delivery Method
                ...deliveryTypes.map((dt) {
                  final isSelected = selectedDeliveryType == dt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(dt.name),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          selectedDeliveryType = dt;
                          _updateTotals();
                        });
                      },
                      checkmarkColor: Colors.white,
                      selectedColor: Colors.orange,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const Divider(height: 24),

          // Financials
          _buildSummaryRow("Subtotal", subTotal),
          if (deliveryCharge > 0)
            _buildSummaryRow("Delivery", deliveryCharge, color: Colors.orange),
          if (totalDiscount > 0)
            _buildSummaryRow("Discount", -totalDiscount, color: Colors.green),

          const SizedBox(height: 12),
          // Grand Total Editable
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: totalPriceController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 20),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixText: "₹",
                  ),
                  onChanged: (v) {
                    isTotalPriceEdited = true;
                    totalPrice = double.tryParse(v) ?? totalPrice;
                    _updateTotals();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("COMPLETE SALE",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            "₹${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
                fontWeight: FontWeight.w600, color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
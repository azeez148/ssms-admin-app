import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_admin_app/models/sale.dart';
import 'package:flutter_admin_app/models/product.dart';
import 'package:flutter_admin_app/services/sale_service.dart';
import 'package:flutter_admin_app/services/product_service.dart';

class SaleDialog extends StatefulWidget {
  final Sale? sale;
  final Function(Sale) onSaleCreated;

  const SaleDialog({
    Key? key,
    this.sale,
    required this.onSaleCreated,
  }) : super(key: key);

  @override
  State<SaleDialog> createState() => _SaleDialogState();
}

class _SaleDialogState extends State<SaleDialog> {
  final SaleService _saleService = SaleService();
  final ProductService _productService = ProductService();

  late TextEditingController customerNameController;
  late TextEditingController customerAddressController;
  late TextEditingController customerMobileController;
  late TextEditingController customerEmailController;
  late TextEditingController dateController;
  late TextEditingController paymentRefController;

  List<Product> allProducts = [];
  List<SaleItem> selectedItems = [];
  List<PaymentType> paymentTypes = [];
  List<DeliveryType> deliveryTypes = [];

  PaymentType? selectedPaymentType;
  DeliveryType? selectedDeliveryType;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool isSaving = false;

  double subTotal = 0;
  double deliveryCharge = 0;
  double totalDiscount = 0;
  double totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    customerNameController = TextEditingController(
      text: widget.sale?.customerName ?? '',
    );
    customerAddressController = TextEditingController(
      text: widget.sale?.customerAddress ?? '',
    );
    customerMobileController = TextEditingController(
      text: widget.sale?.customerMobile ?? '',
    );
    customerEmailController = TextEditingController(
      text: widget.sale?.customerEmail ?? '',
    );
    dateController = TextEditingController(
      text: widget.sale?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    paymentRefController = TextEditingController(
      text: widget.sale?.paymentReferenceNumber ?? '',
    );
    selectedDate = DateTime.parse(dateController.text);
  }

  Future<void> _loadData() async {
    try {
      final products = await _productService.getProducts();
      final paymentTypesList = await _saleService.getPaymentTypes();
      final deliveryTypesList = await _saleService.getDeliveryTypes();

      setState(() {
        allProducts = products;
        paymentTypes = paymentTypesList;
        deliveryTypes = deliveryTypesList;
        
        if (widget.sale != null) {
          selectedItems = widget.sale!.saleItems ?? [];
          selectedPaymentType = widget.sale?.paymentType;
          selectedDeliveryType = widget.sale?.deliveryType;
        } else {
          selectedPaymentType = paymentTypesList.isNotEmpty ? paymentTypesList[0] : null;
          selectedDeliveryType = deliveryTypesList.isNotEmpty ? deliveryTypesList[0] : null;
        }
        
        isLoading = false;
      });

      _updateTotalSummary();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  void _updateTotalSummary() {
    double subtotal = 0;

    for (var item in selectedItems) {
      subtotal += item.salePrice * item.quantity;
    }

    deliveryCharge = selectedDeliveryType?.charge ?? 0;
    subTotal = subtotal;
    totalPrice = subTotal + deliveryCharge - totalDiscount;

    setState(() {});
  }

  void _removeItem(SaleItem item) {
    setState(() {
      selectedItems.removeWhere(
        (e) => e.productId == item.productId && e.size == item.size,
      );
    });
    _updateTotalSummary();
  }

  void _addProductToSale(Product product, String size) {
    final existingItem = selectedItems.firstWhere(
      (item) => item.productId == product.id && item.size == size,
      orElse: () => SaleItem(
        productId: product.id,
        productName: product.name,
        productCategory: product.category?.name ?? 'N/A',
        size: size,
        quantityAvailable: product.sizeMap
                ?.firstWhere(
                  (s) => s.size == size,
                  orElse: () => ProductSizeBase(size: size, quantity: 0),
                )
                .quantity ??
            0,
        quantity: 1,
        salePrice: product.sellingPrice.toDouble(),
        totalPrice: product.sellingPrice.toDouble(),
      ),
    );

    if (selectedItems.contains(existingItem)) {
      // Item already exists, increase quantity
      existingItem.quantity++;
      existingItem.totalPrice = existingItem.quantity * existingItem.salePrice;
    } else {
      // Add new item
      selectedItems.add(existingItem);
    }

    setState(() {});
    _updateTotalSummary();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ($size) added to sale'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveSale() async {
    if (customerNameController.text.isEmpty ||
        customerMobileController.text.isEmpty ||
        selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields and select items'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final saleItemsCreate = selectedItems.map((item) {
        return SaleItemCreate(
          productId: item.productId,
          productName: item.productName,
          productCategory: item.productCategory,
          size: item.size,
          quantityAvailable: item.quantityAvailable,
          quantity: item.quantity,
          salePrice: item.salePrice,
          totalPrice: item.totalPrice,
        );
      }).toList();

      final saleCreate = SaleCreate(
        date: dateController.text,
        totalQuantity: selectedItems.fold(0, (sum, item) => sum + item.quantity),
        totalPrice: totalPrice,
        paymentTypeId: selectedPaymentType?.id ?? 0,
        paymentReferenceNumber: paymentRefController.text.isEmpty ? null : paymentRefController.text,
        deliveryTypeId: selectedDeliveryType?.id ?? 0,
        shopId: 1, // TODO: Get from app state
        customerId: 1, // TODO: Get from app state
        customerName: customerNameController.text,
        customerAddress: customerAddressController.text,
        customerMobile: customerMobileController.text,
        customerEmail: customerEmailController.text,
        saleItems: saleItemsCreate,
      );

      Sale result;
      if (widget.sale != null) {
        result = await _saleService.updateSale(widget.sale!.id.toString(), saleCreate);
      } else {
        result = await _saleService.addSale(saleCreate);
      }

      if (mounted) {
        widget.onSaleCreated(result);
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving sale: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _fillDummyCustomer() {
    setState(() {
      customerNameController.text = 'In-store Customer';
      customerAddressController.text = 'In-store';
      customerMobileController.text = '0000000000';
      customerEmailController.text = '';
    });
  }

  @override
  void dispose() {
    customerNameController.dispose();
    customerAddressController.dispose();
    customerMobileController.dispose();
    customerEmailController.dispose();
    dateController.dispose();
    paymentRefController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: Text(widget.sale != null ? 'Update Sale' : 'Create Sale'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Customer Details
              _buildSection(
                title: 'Customer Details',
                children: [
                  TextField(
                    controller: customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customerAddressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customerMobileController,
                          decoration: InputDecoration(
                            labelText: 'Mobile *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _fillDummyCustomer,
                        child: const Text('Dummy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customerEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sale Configuration
              _buildSection(
                title: 'Sale Configuration',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                                dateController.text =
                                    DateFormat('yyyy-MM-dd').format(date);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<DeliveryType>(
                    value: selectedDeliveryType,
                    decoration: InputDecoration(
                      labelText: 'Delivery Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: deliveryTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedDeliveryType = value);
                      _updateTotalSummary();
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PaymentType>(
                    value: selectedPaymentType,
                    decoration: InputDecoration(
                      labelText: 'Payment Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: paymentTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedPaymentType = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: paymentRefController,
                    decoration: InputDecoration(
                      labelText: 'Payment Reference Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Product Selection
              _buildSection(
                title: 'Select Products',
                children: [
                  SizedBox(
                    height: 300,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Product Name')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Size')),
                          DataColumn(label: Text('Available')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: allProducts.expand((product) {
                          if (product.sizeMap == null || product.sizeMap!.isEmpty) {
                            return [
                              DataRow(cells: [
                                DataCell(Text(product.id.toString())),
                                DataCell(Text(product.name)),
                                DataCell(Text(product.category?.name ?? 'N/A')),
                                DataCell(const Text('-')),
                                DataCell(const Text('-')),
                                DataCell(Text('₹${product.sellingPrice}')),
                                DataCell(
                                  ElevatedButton(
                                    onPressed: () => _addProductToSale(product, 'Free Size'),
                                    child: const Text('Add'),
                                  ),
                                ),
                              ]),
                            ];
                          }
                          return product.sizeMap!
                              .where((size) => size.quantity > 0)
                              .map((size) {
                            return DataRow(cells: [
                              DataCell(Text(product.id.toString())),
                              DataCell(Text(product.name)),
                              DataCell(Text(product.category?.name ?? 'N/A')),
                              DataCell(Text(size.size)),
                              DataCell(Text(size.quantity.toString())),
                              DataCell(Text('₹${product.sellingPrice}')),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () => _addProductToSale(product, size.size),
                                  child: const Text('Add'),
                                ),
                              ),
                            ]);
                          }).toList();
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selected Items
              _buildSection(
                title: 'Selected Items (${selectedItems.length})',
                children: [
                  if (selectedItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No items selected'),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Size')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Total')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: selectedItems.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item.productName)),
                            DataCell(Text(item.size)),
                            DataCell(
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(
                                    text: item.quantity.toString(),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      item.quantity = int.parse(value);
                                      _updateTotalSummary();
                                    }
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  controller: TextEditingController(
                                    text: item.salePrice.toStringAsFixed(2),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      item.salePrice = double.parse(value);
                                      _updateTotalSummary();
                                    }
                                  },
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '₹${(item.quantity * item.salePrice).toStringAsFixed(2)}',
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeItem(item),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Summary
              _buildSection(
                title: 'Summary',
                children: [
                  _summaryRow('Sub Total', subTotal),
                  _summaryRow('Delivery Charge', deliveryCharge),
                  _summaryRow('Total Discount', totalDiscount),
                  const Divider(),
                  _summaryRow(
                    'Total Price',
                    totalPrice,
                    isBold: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _saveSale,
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _summaryRow(String label, double value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

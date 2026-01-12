import 'package:flutter/material.dart';
import 'package:flutter_admin_app/screens/sale_detail_dialog.dart';
import 'package:flutter_admin_app/screens/sale_dialog.dart';
import 'package:flutter_admin_app/screens/status_update_dialog.dart';
import 'package:intl/intl.dart';
import 'package:flutter_admin_app/models/sale.dart';
import 'package:flutter_admin_app/services/sale_service.dart';
import 'package:flutter_admin_app/widgets/shipping_label_widget.dart';
// Ensure this path matches where you saved the previous file
// Assuming these exist in your project structure

class SalesScreen extends StatefulWidget {
  const SalesScreen({Key? key}) : super(key: key);

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final SaleService _saleService = SaleService();

  List<Sale> allSales = [];
  List<Sale> filteredSales = [];
  bool isLoading = true;
  String? errorMessage;

  // Filter variables
  String selectedDateFilter = 'all';
  String customerNameFilter = '';
  DateTime? customStartDate;
  DateTime? customEndDate;

  // Pagination
  int currentPage = 1;
  static const int itemsPerPage = 10;
  int _pendingSalesCount = 0;

  // Summary
  SaleSummary? todaysSaleSummary;

  // Styling Constants
  final Color primaryColor = const Color(0xFF2A2D3E);
  final Color accentColor = const Color(0xFF2196F3);
  final Color surfaceColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final sales = await _saleService.getSales();
      final pendingCount = await _saleService.getPendingSalesCount();

      setState(() {
        allSales = sales..sort((a, b) => b.id.compareTo(a.id));
        _applyFilters();
        isLoading = false;
        _pendingSalesCount = pendingCount;
      });

      _calculateTodaysSaleSummary();
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading sales: $e';
        isLoading = false;
      });
    }
  }

  void _calculateTodaysSaleSummary() {
    final today = DateTime.now();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final todaysSales = allSales.where((sale) {
      final saleDate = DateTime.parse(sale.date);
      final todayStart = DateTime(today.year, today.month, today.day);
      return saleDate.isAfter(todayStart) && saleDate.isBefore(endOfDay);
    }).toList();

    double totalRevenue = 0;
    int totalItems = 0;

    for (var sale in todaysSales) {
      totalRevenue += sale.totalPrice;
      totalItems += sale.totalQuantity;
    }

    setState(() {
      todaysSaleSummary = SaleSummary(
        totalCount: todaysSales.length,
        totalRevenue: totalRevenue,
        totalItemsSold: totalItems,
      );
    });
  }

  void _applyFilters() {
    List<Sale> filtered = List.from(allSales);

    // Apply date filter
    filtered = _applyDateFilter(filtered);

    // Apply customer name filter
    if (customerNameFilter.isNotEmpty) {
      filtered = filtered
          .where((sale) => sale.customerName
              .toLowerCase()
              .contains(customerNameFilter.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredSales = filtered;
      currentPage = 1; // Reset to first page
    });
  }

  List<Sale> _applyDateFilter(List<Sale> sales) {
    final today = DateTime.now();

    switch (selectedDateFilter) {
      case 'today':
        return sales.where((sale) {
          final saleDate = DateTime.parse(sale.date);
          return saleDate.year == today.year &&
              saleDate.month == today.month &&
              saleDate.day == today.day;
        }).toList();

      case 'yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return sales.where((sale) {
          final saleDate = DateTime.parse(sale.date);
          return saleDate.year == yesterday.year &&
              saleDate.month == yesterday.month &&
              saleDate.day == yesterday.day;
        }).toList();

      case 'this_week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return sales.where((sale) {
          final saleDate = DateTime.parse(sale.date);
          return saleDate.isAfter(startOfWeek);
        }).toList();

      case 'this_month':
        final startOfMonth = DateTime(today.year, today.month, 1);
        return sales.where((sale) {
          final saleDate = DateTime.parse(sale.date);
          return saleDate.isAfter(startOfMonth);
        }).toList();

      case 'custom':
        if (customStartDate != null && customEndDate != null) {
          return sales.where((sale) {
            final saleDate = DateTime.parse(sale.date);
            return saleDate.isAfter(customStartDate!) &&
                saleDate
                    .isBefore(customEndDate!.add(const Duration(days: 1)));
          }).toList();
        }
        return sales;

      default:
        return sales;
    }
  }

  // --- Actions ---

  void _openCreateSaleDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to close via button
      builder: (BuildContext context) {
        return SaleDialog(
          onSaleCreated: (sale) {
            _loadSales(); // Reload to show new sale
            // Dialog closes itself in its _save method usually, or handled here?
            // If SaleDialog pops itself, we don't need to pop here.
          },
        );
      },
    );
  }

  void _openUpdateSaleDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SaleDialog(
          sale: sale,
          onSaleCreated: (updatedSale) {
            _loadSales();
            // Assuming SaleDialog pops itself or we rely on user closing it
          },
        );
      },
    );
  }

  void _openUpdateStatusDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatusUpdateDialog(
          sale: sale,
          onStatusUpdated: (newStatus) {
            _loadSales();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _openSaleDetailsDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SaleDetailDialog(sale: sale);
      },
    );
  }

  Future<void> _cancelSale(Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Sale'),
          content: Text(
              'Are you sure you want to cancel sale with ID: ${sale.id}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      try {
        await _saleService.cancelSale(sale.id);
        _loadSales();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sale cancelled successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling sale: $e')),
          );
        }
      }
    }
  }

  void _printReceipt(Sale sale) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print receipt functionality coming soon')),
    );
  }

  void _printShippingLabel(Sale sale) {
    ShippingLabelWidget.print(context, sale);
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel export functionality coming soon')),
    );
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;
    
    // Pagination logic
    final totalPages = (filteredSales.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredSales.length);
    final paginatedSales = filteredSales.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // 1. Header & Summary Section
          Container(
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
                      'Sales Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_pendingSalesCount > 0)
                      Badge(
                        label: Text('$_pendingSalesCount New'),
                        child: IconButton(
                          onPressed: _loadSales,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Refresh Data',
                        ),
                      )
                    else
                      IconButton(
                        onPressed: _loadSales,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh Data',
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                // Summary Cards
                if (todaysSaleSummary != null)
                  isMobile
                      ? Column(
                          children: [
                            _buildSummaryCard(
                                "Today's Revenue",
                                "₹${todaysSaleSummary!.totalRevenue.toStringAsFixed(0)}",
                                Icons.attach_money,
                                Colors.greenAccent),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryCard(
                                      "Sales Count",
                                      "${todaysSaleSummary!.totalCount}",
                                      Icons.receipt_long,
                                      Colors.blueAccent),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildSummaryCard(
                                      "Items Sold",
                                      "${todaysSaleSummary!.totalItemsSold}",
                                      Icons.shopping_bag,
                                      Colors.orangeAccent),
                                ),
                              ],
                            )
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                  "Today's Revenue",
                                  "₹${todaysSaleSummary!.totalRevenue.toStringAsFixed(2)}",
                                  Icons.attach_money,
                                  Colors.greenAccent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                  "Sales Count",
                                  "${todaysSaleSummary!.totalCount}",
                                  Icons.receipt_long,
                                  Colors.blueAccent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildSummaryCard(
                                  "Items Sold",
                                  "${todaysSaleSummary!.totalItemsSold}",
                                  Icons.shopping_bag,
                                  Colors.orangeAccent),
                            ),
                          ],
                        ),
              ],
            ),
          ),

          // 2. Filters & Actions Bar
          Transform.translate(
            offset: const Offset(0, -25), // Overlap effect
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchField(),
                        const SizedBox(height: 12),
                        _buildDateFilterDropdown(),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _openCreateSaleDialog,
                          icon: const Icon(Icons.add),
                          label: const Text("New Sale"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 2, child: _buildSearchField()),
                        const SizedBox(width: 16),
                        Expanded(flex: 1, child: _buildDateFilterDropdown()),
                        const SizedBox(width: 16),
                        if (selectedDateFilter == 'custom') ...[
                          Expanded(child: _buildDatePicker(true)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildDatePicker(false)),
                          const SizedBox(width: 16),
                        ],
                        ElevatedButton.icon(
                          onPressed: _openCreateSaleDialog,
                          icon: const Icon(Icons.add),
                          label: const Text("New Sale"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                         OutlinedButton.icon(
                          onPressed: _exportToExcel,
                          icon: const Icon(Icons.download),
                          label: const Text("Export"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                             shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // 3. Sales List / Table
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                    : filteredSales.isEmpty
                        ? _buildEmptyState()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: isMobile
                                      ? ListView.builder(
                                          padding: EdgeInsets.zero,
                                          itemCount: paginatedSales.length,
                                          itemBuilder: (ctx, i) =>
                                              _buildMobileSaleCard(
                                                  paginatedSales[i]),
                                        )
                                      : Card(
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          clipBehavior: Clip.hardEdge,
                                          child: SingleChildScrollView(
                                            child: _buildDataTable(paginatedSales),
                                          ),
                                        ),
                                ),
                                if (totalPages > 1)
                                  _buildPaginationControls(totalPages),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // --- Components ---

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search by Customer Name',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: surfaceColor,
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
      onChanged: (val) {
        setState(() => customerNameFilter = val);
        _applyFilters();
      },
    );
  }

  Widget _buildDateFilterDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedDateFilter,
      decoration: InputDecoration(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All Time')),
        DropdownMenuItem(value: 'today', child: Text('Today')),
        DropdownMenuItem(value: 'yesterday', child: Text('Yesterday')),
        DropdownMenuItem(value: 'this_week', child: Text('This Week')),
        DropdownMenuItem(value: 'this_month', child: Text('This Month')),
        DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
      ],
      onChanged: (val) {
        setState(() => selectedDateFilter = val ?? 'all');
        _applyFilters();
      },
    );
  }

  Widget _buildDatePicker(bool isStart) {
    final date = isStart ? customStartDate : customEndDate;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              customStartDate = picked;
            } else {
              customEndDate = picked;
            }
          });
          _applyFilters();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null ? DateFormat('MMM dd').format(date) : (isStart ? 'Start' : 'End'),
              style: TextStyle(color: date != null ? Colors.black : Colors.grey),
            ),
            const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No sales records found",
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Sale> sales) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
      dataRowHeight: 60,
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Date')),
        DataColumn(label: Text('Qty')),
        DataColumn(label: Text('Total')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      rows: sales.map((sale) {
        return DataRow(cells: [
          DataCell(Text('#${sale.id}',
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sale.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(sale.customerMobile,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )),
          DataCell(Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(sale.date)))),
          DataCell(Text('${sale.totalQuantity}')),
          DataCell(Text('₹${sale.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green))),
          DataCell(_buildStatusBadge(sale.status)),
          DataCell(Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 20),
                color: Colors.blueGrey,
                tooltip: 'View',
                onPressed: () => _openSaleDetailsDialog(sale),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: accentColor,
                tooltip: 'Edit',
                onPressed: () => _openUpdateSaleDialog(sale),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'status') _openUpdateStatusDialog(sale);
                  if (value == 'cancel') _cancelSale(sale);
                  if (value == 'print') _printReceipt(sale);
                  if (value == 'shipping') _printShippingLabel(sale);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'status', child: Text('Update Status')),
                  const PopupMenuItem(value: 'print', child: Text('Print Receipt')),
                  const PopupMenuItem(value: 'shipping', child: Text('Print Shipping Label')),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel Sale', style: TextStyle(color: Colors.red)),
                  ),
                ],
              )
            ],
          )),
        ]);
      }).toList(),
    );
  }

  Widget _buildMobileSaleCard(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${sale.id}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 16)),
              _buildStatusBadge(sale.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sale.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(sale.date)),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${sale.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 16)),
                  Text('${sale.totalQuantity} Items',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openSaleDetailsDialog(sale),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text("View"),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _openUpdateSaleDialog(sale),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text("Edit"),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SaleStatus? status) {
    Color color;
    String text = status?.toString().split('.').last.toUpperCase() ?? 'N/A';

    switch (status) {
      case SaleStatus.completed:
        color = Colors.green;
        break;
      case SaleStatus.pending:
        color = Colors.orange;
        break;
      case SaleStatus.cancelled:
        color = Colors.red;
        break;
      case SaleStatus.shipped:
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1
                ? () => setState(() => currentPage--)
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text("Page $currentPage of $totalPages"),
          IconButton(
            onPressed: currentPage < totalPages
                ? () => setState(() => currentPage++)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_admin_app/models/sale.dart';
import 'package:flutter_admin_app/services/sale_service.dart';
import 'sale_dialog.dart';
import 'sale_detail_dialog.dart';
import 'status_update_dialog.dart';

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
  String productNameFilter = '';
  String customerNameFilter = '';
  String? selectedCategoryId;
  DateTime? customStartDate;
  DateTime? customEndDate;
  
  // Pagination
  int currentPage = 1;
  static const int itemsPerPage = 10;
  
  // Summary
  SaleSummary? todaysSaleSummary;

  @override
  void initState() {
    super.initState();
    _loadSales();
    _calculateTodaysSaleSummary();
  }

  Future<void> _loadSales() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      final sales = await _saleService.getSales();
      
      setState(() {
        allSales = sales..sort((a, b) => b.id.compareTo(a.id));
        _applyFilters();
        isLoading = false;
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
      filtered = filtered.where((sale) =>
        sale.customerName.toLowerCase().contains(customerNameFilter.toLowerCase())
      ).toList();
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
                   saleDate.isBefore(customEndDate!.add(const Duration(days: 1)));
          }).toList();
        }
        return sales;
        
      default:
        return sales;
    }
  }

  void _openCreateSaleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SaleDialog(
          onSaleCreated: (sale) {
            _loadSales();
            Navigator.of(context).pop();
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
            Navigator.of(context).pop();
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
          content: Text('Are you sure you want to cancel sale with ID: ${sale.id}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    
    if (confirmed ?? false) {
      try {
        await _saleService.cancelSale(sale.id);
        _loadSales();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale cancelled successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling sale: $e')),
        );
      }
    }
  }

  void _printReceipt(Sale sale) {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print receipt functionality coming soon')),
    );
  }

  void _exportToExcel() {
    // TODO: Implement Excel export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excel export functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final totalPages = (filteredSales.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filteredSales.length);
    final paginatedSales = filteredSales.sublist(startIndex, endIndex);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Sales',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Today's Sale Summary
            _buildSaleSummary(isMobile),
            const SizedBox(height: 16),

            // Filters
            _buildFiltersSection(isMobile),
            const SizedBox(height: 16),

            // Sales Table or List
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage != null)
              Center(
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (filteredSales.isEmpty)
              const Center(
                child: Text('No sales found'),
              )
            else if (isMobile)
              _buildSalesList(paginatedSales)
            else
              _buildSalesTable(paginatedSales),

            // Pagination
            if (!isLoading && filteredSales.isNotEmpty)
              _buildPagination(totalPages, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleSummary(bool isMobile) {
    if (todaysSaleSummary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Sale Summary",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCardMobile(
                      'Total Sales',
                      todaysSaleSummary!.totalCount.toString(),
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryCardMobile(
                      'Total Revenue',
                      '₹${todaysSaleSummary!.totalRevenue.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryCardMobile(
                      'Total Items Sold',
                      todaysSaleSummary!.totalItemsSold.toString(),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryCard(
                      'Total Sales',
                      todaysSaleSummary!.totalCount.toString(),
                    ),
                    _summaryCard(
                      'Total Revenue',
                      '₹${todaysSaleSummary!.totalRevenue.toStringAsFixed(2)}',
                    ),
                    _summaryCard(
                      'Total Items Sold',
                      todaysSaleSummary!.totalItemsSold.toString(),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCardMobile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filters',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Customer Name Filter
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Customer Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => customerNameFilter = value);
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 10),

                  // Date Filter Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedDateFilter,
                    decoration: InputDecoration(
                      labelText: 'Date Filter',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Time')),
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(value: 'yesterday', child: Text('Yesterday')),
                      DropdownMenuItem(value: 'this_week', child: Text('This Week')),
                      DropdownMenuItem(value: 'this_month', child: Text('This Month')),
                      DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedDateFilter = value ?? 'all');
                      _applyFilters();
                    },
                  ),

                  // Custom Date Pickers
                  if (selectedDateFilter == 'custom') ...[
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: customStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => customStartDate = date);
                          _applyFilters();
                        }
                      },
                      controller: TextEditingController(
                        text: customStartDate != null
                            ? DateFormat('yyyy-MM-dd').format(customStartDate!)
                            : '',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: customEndDate ?? DateTime.now(),
                          firstDate: customStartDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => customEndDate = date);
                          _applyFilters();
                        }
                      },
                      controller: TextEditingController(
                        text: customEndDate != null
                            ? DateFormat('yyyy-MM-dd').format(customEndDate!)
                            : '',
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadSales,
                    child: const Text('Refresh'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openCreateSaleDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Create New Sale'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _exportToExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Export to Excel'),
                  ),
                ],
              )
            : Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Customer Name Filter
                  SizedBox(
                    width: 250,
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Customer Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => customerNameFilter = value);
                        _applyFilters();
                      },
                    ),
                  ),

                  // Date Filter Dropdown
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: selectedDateFilter,
                      decoration: InputDecoration(
                        labelText: 'Date Filter',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Time')),
                        DropdownMenuItem(value: 'today', child: Text('Today')),
                        DropdownMenuItem(
                            value: 'yesterday', child: Text('Yesterday')),
                        DropdownMenuItem(
                            value: 'this_week', child: Text('This Week')),
                        DropdownMenuItem(
                            value: 'this_month', child: Text('This Month')),
                        DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedDateFilter = value ?? 'all');
                        _applyFilters();
                      },
                    ),
                  ),

                  // Custom Date Pickers
                  if (selectedDateFilter == 'custom') ...[
                    SizedBox(
                      width: 200,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: customStartDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => customStartDate = date);
                            _applyFilters();
                          }
                        },
                        controller: TextEditingController(
                          text: customStartDate != null
                              ? DateFormat('yyyy-MM-dd')
                                  .format(customStartDate!)
                              : '',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: customEndDate ?? DateTime.now(),
                            firstDate:
                                customStartDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => customEndDate = date);
                            _applyFilters();
                          }
                        },
                        controller: TextEditingController(
                          text: customEndDate != null
                              ? DateFormat('yyyy-MM-dd').format(customEndDate!)
                              : '',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        const SizedBox(height: 12),
        if (!isMobile)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _loadSales,
                child: const Text('Refresh'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _openCreateSaleDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Create New Sale'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _exportToExcel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Export to Excel'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSalesTable(List<Sale> sales) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Customer')),
          DataColumn(label: Text('Total Qty')),
          DataColumn(label: Text('Total Price')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: sales.map((sale) {
          return DataRow(cells: [
            DataCell(Text(sale.id.toString())),
            DataCell(Text(sale.customerName)),
            DataCell(Text(sale.totalQuantity.toString())),
            DataCell(Text('₹${sale.totalPrice.toStringAsFixed(2)}')),
            DataCell(Text(DateFormat('MMM d, y').format(DateTime.parse(sale.date)))),
            DataCell(_buildStatusBadge(sale.status)),
            DataCell(_buildActionButtons(sale)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildSalesList(List<Sale> sales) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sales.length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${sale.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sale.customerName,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(sale.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qty: ${sale.totalQuantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${sale.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(DateTime.parse(sale.date)),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMobileActionButtons(sale),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(SaleStatus? status) {
    final statusText = status?.toString().split('.').last.toUpperCase() ?? 'PENDING';
    Color backgroundColor;

    switch (status) {
      case SaleStatus.pending:
        backgroundColor = Colors.orange.shade100;
        break;
      case SaleStatus.completed:
        backgroundColor = Colors.green.shade100;
        break;
      case SaleStatus.shipped:
        backgroundColor = Colors.blue.shade100;
        break;
      case SaleStatus.returned:
        backgroundColor = Colors.red.shade100;
        break;
      case SaleStatus.cancelled:
        backgroundColor = Colors.grey.shade300;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(statusText),
    );
  }

  Widget _buildActionButtons(Sale sale) {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View'),
          onPressed: () => _openSaleDetailsDialog(sale),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Update'),
          onPressed: () => _openUpdateSaleDialog(sale),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.update, size: 16),
          label: const Text('Status'),
          onPressed: () => _openUpdateStatusDialog(sale),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.cancel, size: 16),
          label: const Text('Cancel'),
          onPressed: () => _cancelSale(sale),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.print, size: 16),
          label: const Text('Print'),
          onPressed: () => _printReceipt(sale),
        ),
      ],
    );
  }

  Widget _buildMobileActionButtons(Sale sale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('View'),
                onPressed: () => _openSaleDetailsDialog(sale),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit'),
                onPressed: () => _openUpdateSaleDialog(sale),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.update, size: 14),
                label: const Text('Status'),
                onPressed: () => _openUpdateStatusDialog(sale),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel, size: 14),
                label: const Text('Cancel'),
                onPressed: () => _cancelSale(sale),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPagination(int totalPages, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (currentPage > 1)
              ElevatedButton(
                onPressed: () => setState(() => currentPage--),
                child: const Text('Previous'),
              ),
            const SizedBox(width: 8),
            ...List.generate(
              totalPages > 5
                  ? 5
                  : totalPages, // Show max 5 pages on mobile
              (index) {
                int pageNum;
                if (totalPages > 5) {
                  if (currentPage <= 3) {
                    pageNum = index + 1;
                  } else if (currentPage >= totalPages - 2) {
                    pageNum = totalPages - 4 + index;
                  } else {
                    pageNum = currentPage - 2 + index;
                  }
                } else {
                  pageNum = index + 1;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    onPressed: currentPage == pageNum
                        ? null
                        : () => setState(() => currentPage = pageNum),
                    child: Text(pageNum.toString()),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            if (currentPage < totalPages)
              ElevatedButton(
                onPressed: () => setState(() => currentPage++),
                child: const Text('Next'),
              ),
          ],
        ),
      ),
    );
  }
}

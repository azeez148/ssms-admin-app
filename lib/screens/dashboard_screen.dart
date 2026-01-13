import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/sale_service.dart';
import '../services/product_service.dart';
// import '../services/purchase_service.dart';
// import '../models/purchase.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Services
  final SaleService _saleService = SaleService();
  final ProductService _productService = ProductService();

  // Data State
  Dashboard? _dashboardData;
  List<Sale> _allSales = [];
  List<Product> _allProducts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Calculated Metrics
  double _totalStockValue = 0;
  double _projectedSaleValue = 0;
  double _projectedProfitValue = 0;
  int _totalPendingSales = 0;

  // Today's Summaries
  final Map<String, dynamic> _todayCompleted = {
    'count': 0,
    'revenue': 0.0,
    'items': 0
  };
  final Map<String, dynamic> _todayPending = {
    'count': 0,
    'revenue': 0.0,
    'items': 0
  };
  final Map<String, dynamic> _todayShipped = {
    'count': 0,
    'revenue': 0.0,
    'items': 0
  };

  // Styling Constants
  final Color primaryColor = const Color(0xFF2A2D3E);
  final Color accentColor = const Color(0xFF2196F3);
  final Color surfaceColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dashboardJson = await ApiService.instance.getDashboardData(context);
      final dashboard = Dashboard.fromJson(dashboardJson);
      final sales = await _saleService.getSales();
      final products = await _productService.getProducts();
      final pendingCount = await _saleService.getPendingSalesCount();

      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _allSales = sales;
          _allProducts = products;
          _totalPendingSales = pendingCount;

          _calculateStockValues();
          _calculateTodaysMetrics();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
      print('Error loading dashboard: $e');
    }
  }

  void _calculateStockValues() {
    double stockVal = 0;
    double saleVal = 0;

    for (var product in _allProducts) {
      int qty = 0;
      if (product.sizeMap != null) {
        qty = product.sizeMap!.fold(0, (sum, size) => sum + size.quantity);
      }
      // Fallback if needed: qty = product.quantity;

      stockVal += (product.unitPrice * qty);
      saleVal += (product.sellingPrice * qty);
    }

    _totalStockValue = stockVal;
    _projectedSaleValue = saleVal;
    _projectedProfitValue = saleVal - stockVal;
  }

  void _calculateTodaysMetrics() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todaysSales = _allSales.where((s) {
      final d = DateTime.parse(s.date);
      return d.isAfter(todayStart) &&
          d.isBefore(todayEnd) &&
          s.status != SaleStatus.cancelled;
    }).toList();

    void aggregate(List<Sale> sales, Map<String, dynamic> target) {
      target['count'] = sales.length;
      target['revenue'] = sales.fold(0.0, (sum, s) => sum + s.totalPrice);
      target['items'] = sales.fold(0, (sum, s) => sum + s.totalQuantity);
    }

    aggregate(todaysSales.where((s) => s.status == SaleStatus.completed).toList(),
        _todayCompleted);
    aggregate(todaysSales.where((s) => s.status == SaleStatus.pending).toList(),
        _todayPending);
    aggregate(todaysSales.where((s) => s.status == SaleStatus.shipped).toList(),
        _todayShipped);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: _buildErrorState(_errorMessage));
    }

    if (_dashboardData == null) {
      return const Scaffold(body: Center(child: Text("No Data")));
    }

    return Scaffold(
      backgroundColor: surfaceColor,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header & KPIs
              _buildHeader(isMobile),

              // 2. Floating Action Bar
              _buildActionBar(isMobile),

              // 3. Main Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Breakdown
                    _buildSectionTitle("Today's Performance", Icons.today),
                    const SizedBox(height: 16),
                    _buildTodaySummaryGrid(isMobile),
                    const SizedBox(height: 24),

                    // Total Sales / Purchases & Counts
                    _buildTotalsAndCountsGrid(isMobile),
                    const SizedBox(height: 32),

                    // Tables
                    _buildSectionTitle(
                        'Recent Sales (Last 10)', Icons.receipt_long),
                    const SizedBox(height: 16),
                    _buildRecentSalesTable(_dashboardData!, isMobile),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                        'Top Performing Items', Icons.trending_up),
                    const SizedBox(height: 16),
                    _buildMostSoldItems(_dashboardData!, isMobile),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                        'Recent Purchases', Icons.shopping_bag_outlined),
                    const SizedBox(height: 16),
                    _buildRecentPurchasesTable(_dashboardData!, isMobile),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
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
                'Business Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _loadAllData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Data',
              )
            ],
          ),
          const SizedBox(height: 24),
          // KPI Grid inside Header
          _buildKPIGrid(isMobile),
          const SizedBox(height: 20), // Extra space for overlap
        ],
      ),
    );
  }

  Widget _buildKPIGrid(bool isMobile) {
    List<Widget> cards = [
      _buildHeaderMetricCard(
          "Stock Value", _totalStockValue, Icons.inventory, Colors.greenAccent),
      _buildHeaderMetricCard("Proj. Sales", _projectedSaleValue,
          Icons.trending_up, Colors.orangeAccent),
      _buildHeaderMetricCard("Proj. Profit", _projectedProfitValue,
          Icons.attach_money, Colors.lightBlueAccent),
    ];

    if (isMobile) {
      return Column(
          children: cards
              .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12), child: c))
              .toList());
    }

    return Row(
      children: cards
          .map((c) => Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: c)))
          .toList(),
    );
  }

  Widget _buildHeaderMetricCard(
      String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${value.toStringAsFixed(0)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
                children: _buildActionButtons(),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: _buildActionButtons(),
              ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      ElevatedButton.icon(
        onPressed: () {
          /* TODO: Open Sale Dialog */
        },
        icon: const Icon(Icons.add_shopping_cart, size: 18),
        label: const Text("Quick Sale"),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(width: 12, height: 12),
      OutlinedButton.icon(
        onPressed: () {
          /* TODO: Open Purchase Dialog */
        },
        icon: const Icon(Icons.add_business, size: 18),
        label: const Text("Quick Purchase"),
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(width: 12, height: 12),
      ElevatedButton.icon(
        onPressed: () {
          /* TODO: Open Day Management */
        },
        icon: const Icon(Icons.settings, size: 18),
        label: const Text("Day Mgmt"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ];
  }

  Widget _buildTodaySummaryGrid(bool isMobile) {
    final pendingSummary = {
      'count': _totalPendingSales,
      'revenue': _todayPending['revenue'],
      'items': _todayPending['items'],
    };
    List<Widget> cards = [
      _buildDetailSummaryCard("Completed", _todayCompleted, Colors.teal),
      _buildDetailSummaryCard(
          "Pending", pendingSummary, Colors.orange, "All Pending Orders"),
      _buildDetailSummaryCard("Shipped", _todayShipped, Colors.blue),
    ];

    if (isMobile) {
      return Column(
          children: cards
              .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12), child: c))
              .toList());
    }
    return Row(
      children: cards
          .map((c) => Expanded(
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c)))
          .toList(),
    );
  }

  Widget _buildDetailSummaryCard(
      String title, Map<String, dynamic> data, Color color,
      [String? customTitle]) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(customTitle ?? "Today's Sales — $title",
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat("Orders", "${data['count']}"),
                _buildMiniStat(
                    "Revenue", "₹${data['revenue'].toStringAsFixed(0)}"),
                _buildMiniStat("Items", "${data['items']}"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTotalsAndCountsGrid(bool isMobile) {
    // Total Sales & Purchases
    Widget totalSales = _buildDetailSummaryCardBig(
        "Total Sales",
        _dashboardData?.total_sales?['total_count'] ?? 0,
        _dashboardData?.total_sales?['total_revenue'] ?? 0,
        _dashboardData?.total_sales?['total_items_sold'] ?? 0,
        Colors.blue);

    Widget totalPurchases = _buildDetailSummaryCardBig(
        "Total Purchases",
        _dashboardData?.total_purchases?['total_count'] ?? 0,
        _dashboardData?.total_purchases?['total_cost'] ??
            0, // Assuming API returns 'total_cost' or 'total'
        _dashboardData?.total_purchases?['total_items_purchased'] ?? 0,
        Colors.green);

    // Products & Categories Counts
    Widget totalProducts = _buildInfoCard(
        "Total Products", "${_dashboardData?.total_products ?? 0}");
    Widget totalCats = _buildInfoCard(
        "Total Categories", "${_dashboardData?.total_categories ?? 0}");

    if (isMobile) {
      return Column(
        children: [
          totalSales,
          const SizedBox(height: 12),
          totalPurchases,
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: totalProducts),
            const SizedBox(width: 12),
            Expanded(child: totalCats)
          ]),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: totalSales),
            const SizedBox(width: 16),
            Expanded(child: totalPurchases),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: totalProducts),
            const SizedBox(width: 16),
            Expanded(child: totalCats),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailSummaryCardBig(
      String title, int count, num revenue, int items, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat("Transactions", "$count"),
              _buildMiniStat("Value", "₹${revenue.toStringAsFixed(0)}"),
              _buildMiniStat("Items", "$items"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  // --- Tables & Helpers (Preserved and refined) ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                color: primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentSalesTable(Dashboard dashboard, bool isMobile) {
    if (dashboard.recent_sales == null || dashboard.recent_sales!.isEmpty) {
      return _buildEmptyState('No recent sales data');
    }
    return _buildDataTable(
      columns: ['Product', 'Qty', 'Amount', 'Date'],
      rows: dashboard.recent_sales!.take(10).map((sale) => DataRow(cells: [
            DataCell(Text(
                sale.getProductName() ?? 'Product #${sale.product_id}',
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text('${sale.getQuantity()}')),
            DataCell(Text('₹${sale.getAmount()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green))),
            DataCell(Text(_formatDate(sale.getDate()))),
          ])).toList(),
    );
  }

  Widget _buildRecentPurchasesTable(Dashboard dashboard, bool isMobile) {
    if (dashboard.recent_purchases == null ||
        dashboard.recent_purchases!.isEmpty) {
      return _buildEmptyState('No recent purchase data');
    }
    return _buildDataTable(
      columns: ['Product', 'Qty', 'Cost', 'Date'],
      rows: dashboard.recent_purchases!.take(10).map((p) => DataRow(cells: [
            DataCell(Text(
                p.product_name ?? 'Product #${p.product_id}',
                style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text('${p.quantity}')),
            DataCell(Text('₹${p.getAmount()}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange))),
            DataCell(Text(_formatDate(p.getDate()))),
          ])).toList(),
    );
  }

  Widget _buildDataTable(
      {required List<String> columns, required List<DataRow> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          dataRowHeight: 60,
          horizontalMargin: 24,
          columnSpacing: 30,
          columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
          rows: rows,
        ),
      ),
    );
  }

  Widget _buildMostSoldItems(Dashboard dashboard, bool isMobile) {
    final items = dashboard.most_sold_items ?? {};
    if (items.isEmpty) return _buildEmptyState('No data available');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final item = items.entries.elementAt(index);
          final data = _parseItemData(item.value);
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text('#${index + 1}',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            title: Text(data['product_name'] ?? 'Unknown',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Category: ${data['product_category'] ?? 'N/A'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${data['total_quantity'] ?? 0} Sold',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green)),
                Text('₹${data['total_revenue'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(children: [
        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(color: Colors.grey[400]))
      ]),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Error loading dashboard',
              style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAllData,
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _parseItemData(dynamic itemValue) {
    if (itemValue is String) {
      try {
        final regexName = RegExp(r'product_name:\s*([^,}]+)');
        final regexCategory = RegExp(r'product_category:\s*([^,}]+)');
        final regexQty = RegExp(r'total_quantity:\s*(\d+)');
        final regexRevenue = RegExp(r'total_revenue:\s*(\d+)');
        return {
          'product_name':
              regexName.firstMatch(itemValue)?.group(1)?.trim() ?? 'Unknown',
          'product_category':
              regexCategory.firstMatch(itemValue)?.group(1)?.trim() ?? 'N/A',
          'total_quantity':
              int.tryParse(regexQty.firstMatch(itemValue)?.group(1) ?? '0') ??
                  0,
          'total_revenue': int.tryParse(
                  regexRevenue.firstMatch(itemValue)?.group(1) ?? '0') ??
              0,
        };
      } catch (e) {
        return {};
      }
    } else if (itemValue is Map) {
      return {
        'product_name': itemValue['product_name'] ?? 'Unknown',
        'product_category': itemValue['product_category'] ?? 'N/A',
        'total_quantity': itemValue['total_quantity'] ?? 0,
        'total_revenue': itemValue['total_revenue'] ?? 0,
      };
    }
    return {};
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
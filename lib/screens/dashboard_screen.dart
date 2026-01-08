import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Dashboard> _dashboardFuture;
  
  // Styling Constants
  final Color primaryColor = const Color(0xFF2A2D3E);
  final Color accentColor = const Color(0xFF2196F3);
  final Color surfaceColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    _dashboardFuture = _fetchDashboardData();
  }

  Future<Dashboard> _fetchDashboardData() async {
    try {
      final data = await ApiService.instance.getDashboardData(context);
      return Dashboard.fromJson(data);
    } catch (e) {
      print('Error fetching dashboard: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: FutureBuilder<Dashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final dashboard = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _loadDashboard());
              await _dashboardFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header & Metrics
                  _buildHeader(dashboard, isMobile),
                  
                  // 2. Content Sections
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Recent Sales
                        _buildSectionTitle('Recent Sales (Last 10)', Icons.receipt_long),
                        const SizedBox(height: 16),
                        _buildRecentSalesTable(dashboard, isMobile),
                        const SizedBox(height: 32),

                        // Most Sold Items
                        _buildSectionTitle('Top Performing Items', Icons.trending_up),
                        const SizedBox(height: 16),
                        _buildMostSoldItems(dashboard, isMobile),
                        const SizedBox(height: 32),

                        // Recent Purchases
                        _buildSectionTitle('Recent Purchases', Icons.shopping_bag_outlined),
                        const SizedBox(height: 16),
                        _buildRecentPurchasesTable(dashboard, isMobile),
                        const SizedBox(height: 32), // Bottom padding
                      ],
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

  Widget _buildHeader(Dashboard dashboard, bool isMobile) {
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
                'Dashboard Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _loadDashboard()),
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Refresh Data',
              )
            ],
          ),
          const SizedBox(height: 24),
          // Metrics Grid
          if (isMobile)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Total Products', '${dashboard.total_products ?? 0}', Icons.inventory_2, Colors.blueAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricCard('Categories', '${dashboard.total_categories ?? 0}', Icons.category, Colors.purpleAccent)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Total Revenue', '₹${dashboard.total_sales?['total_revenue'] ?? 0}', Icons.attach_money, Colors.greenAccent)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricCard('Total Purchases', '₹${dashboard.total_purchases?['total'] ?? 0}', Icons.shopping_cart, Colors.orangeAccent)),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(child: _buildMetricCard('Total Products', '${dashboard.total_products ?? 0}', Icons.inventory_2, Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Categories', '${dashboard.total_categories ?? 0}', Icons.category, Colors.purpleAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Total Revenue', '₹${dashboard.total_sales?['total_revenue'] ?? 0}', Icons.attach_money, Colors.greenAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard('Total Purchases', '₹${dashboard.total_purchases?['total'] ?? 0}', Icons.shopping_cart, Colors.orangeAccent)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSalesTable(Dashboard dashboard, bool isMobile) {
    if (dashboard.recent_sales == null || dashboard.recent_sales!.isEmpty) {
      return _buildEmptyState('No recent sales data');
    }

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          dataRowHeight: 60,
          horizontalMargin: 24,
          columnSpacing: 30,
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Date')),
          ],
          rows: dashboard.recent_sales!
              .take(10)
              .map((sale) => DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        sale.getProductName()?.isNotEmpty == true ? sale.getProductName()! : 'Product #${sale.product_id ?? sale.id ?? '?'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text('${sale.getQuantity()}')),
                  DataCell(Text(
                    '₹${sale.getAmount()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  )),
                  DataCell(Text(
                    _formatDate(sale.getDate()),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )),
                ],
              )).toList(),
        ),
      ),
    );
  }

  Widget _buildRecentPurchasesTable(Dashboard dashboard, bool isMobile) {
    if (dashboard.recent_purchases == null || dashboard.recent_purchases!.isEmpty) {
      return _buildEmptyState('No recent purchase data');
    }

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
          dataRowHeight: 60,
          horizontalMargin: 24,
          columnSpacing: 30,
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Qty')),
            DataColumn(label: Text('Cost')),
            DataColumn(label: Text('Date')),
          ],
          rows: dashboard.recent_purchases!
              .take(10)
              .map((purchase) => DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        purchase.product_name?.isNotEmpty == true ? purchase.product_name! : 'Product #${purchase.product_id ?? '?'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text('${purchase.quantity ?? 0}')),
                  DataCell(Text(
                    '₹${purchase.getAmount()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  )),
                  DataCell(Text(
                    _formatDate(purchase.getDate()),
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )),
                ],
              )).toList(),
        ),
      ),
    );
  }

  Widget _buildMostSoldItems(Dashboard dashboard, bool isMobile) {
    final items = dashboard.most_sold_items ?? {};
    if (items.isEmpty) {
      return _buildEmptyState('No data available');
    }

    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final item = items.entries.elementAt(index);
          final data = _parseItemData(item.value);
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              data['product_name'] ?? 'Unknown Product',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Category: ${data['product_category'] ?? 'N/A'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data['total_quantity'] ?? 0} Sold',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                ),
                Text(
                  '₹${data['total_revenue'] ?? 0}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
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
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Error loading dashboard', style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error.toString(), style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _loadDashboard()),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Helpers
  Map<String, dynamic> _parseItemData(dynamic itemValue) {
    if (itemValue is String) {
      try {
        final regexName = RegExp(r'product_name:\s*([^,}]+)');
        final regexCategory = RegExp(r'product_category:\s*([^,}]+)');
        final regexQty = RegExp(r'total_quantity:\s*(\d+)');
        final regexRevenue = RegExp(r'total_revenue:\s*(\d+)');

        return {
          'product_name': regexName.firstMatch(itemValue)?.group(1)?.trim() ?? 'Unknown',
          'product_category': regexCategory.firstMatch(itemValue)?.group(1)?.trim() ?? 'N/A',
          'total_quantity': int.tryParse(regexQty.firstMatch(itemValue)?.group(1) ?? '0') ?? 0,
          'total_revenue': int.tryParse(regexRevenue.firstMatch(itemValue)?.group(1) ?? '0') ?? 0,
        };
      } catch (e) {
        return {'product_name': 'Unknown', 'product_category': 'N/A', 'total_quantity': 0, 'total_revenue': 0};
      }
    } else if (itemValue is Map) {
      return {
        'product_name': itemValue['product_name'] ?? 'Unknown',
        'product_category': itemValue['product_category'] ?? 'N/A',
        'total_quantity': itemValue['total_quantity'] ?? 0,
        'total_revenue': itemValue['total_revenue'] ?? 0,
      };
    }
    return {'product_name': 'Unknown', 'product_category': 'N/A', 'total_quantity': 0, 'total_revenue': 0};
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
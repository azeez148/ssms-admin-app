import 'package:flutter/material.dart';
import '../models/dashboard.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Dashboard> _dashboardFuture;

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
      // print('Dashboard API Response: $data');
      Dashboard dashboardData = Dashboard.fromJson(data);
      // print('Parsed Dashboard: recent_sales=${dashboardData.recent_sales}, recent_purchases=${dashboardData.recent_purchases}');
      return dashboardData;
    } catch (e) {
      print('Error fetching dashboard: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _loadDashboard());
      },
      child: FutureBuilder<Dashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading dashboard: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() => _loadDashboard()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final dashboard = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key Metrics
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _MetricCard(
                      title: 'Total Products',
                      value: (dashboard.total_products ?? 0).toString(),
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                    _MetricCard(
                      title: 'Total Categories',
                      value: (dashboard.total_categories ?? 0).toString(),
                      icon: Icons.category,
                      color: Colors.purple,
                    ),
                    _MetricCard(
                      title: 'Total Sales',
                      value: '₹${dashboard.total_sales?['total_revenue'] ?? dashboard.total_sales?['total'] ?? 0}',
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                    ),
                    _MetricCard(
                      title: 'Total Purchases',
                      value: '₹${dashboard.total_purchases?['total'] ?? 0}',
                      icon: Icons.shopping_bag,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Sales Section
                Text(
                  'Recent Sales (Last 10)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (dashboard.recent_sales == null || dashboard.recent_sales!.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No recent sales data available'),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Product')),
                              DataColumn(label: Text('Qty')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Date')),
                            ],
                            rows: dashboard.recent_sales!
                                .take(10)
                                .map(
                                  (sale) => DataRow(
                                    cells: [
                                      DataCell(Text(
                                        sale.getProductName()?.isNotEmpty == true ? sale.getProductName()! : 'Product #${sale.product_id ?? sale.id ?? '?'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DataCell(Text(sale.getQuantity().toString())),
                                      DataCell(Text('₹${sale.getAmount()}')),
                                      DataCell(Text(_formatDate(sale.getDate()))),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Total Sales: ${dashboard.recent_sales!.length} transactions',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Most Sold Items
                Text(
                  'Most Sold Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildMostSoldItems(dashboard),
                const SizedBox(height: 24),

                // Recent Purchases
                Text(
                  'Recent Purchases (Last 10)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (dashboard.recent_purchases == null || dashboard.recent_purchases!.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No recent purchases data available'),
                    ),
                  )
                else
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Product')),
                              DataColumn(label: Text('Qty')),
                              DataColumn(label: Text('Amount')),
                              DataColumn(label: Text('Date')),
                            ],
                            rows: dashboard.recent_purchases!
                                .take(10)
                                .map(
                                  (purchase) => DataRow(
                                    cells: [
                                      DataCell(Text(
                                        purchase.product_name?.isNotEmpty == true ? purchase.product_name! : 'Product #${purchase.product_id ?? '?'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                      DataCell(Text((purchase.quantity ?? 0).toString())),
                                      DataCell(Text('₹${purchase.getAmount()}')),
                                      DataCell(Text(_formatDate(purchase.getDate()))),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Total Purchases: ${dashboard.recent_purchases!.length} transactions',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMostSoldItems(Dashboard dashboard) {
    final items = dashboard.most_sold_items ?? {};
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No data available'),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = items.entries.elementAt(index);
          final data = _parseItemData(item.value);
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              data['product_name'] ?? 'Unknown Product',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Category: ${data['product_category'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sold: ${data['total_quantity'] ?? 0} units',
                        style: const TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ),
                    Text(
                      'Revenue: ₹${data['total_revenue'] ?? 0}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${data['total_quantity'] ?? 0}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _parseItemData(dynamic itemValue) {
    if (itemValue is String) {
      // Parse string format: {product_name: X, product_category: Y, total_quantity: Z, total_revenue: W}
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
        return {
          'product_name': 'Unknown',
          'product_category': 'N/A',
          'total_quantity': 0,
          'total_revenue': 0,
        };
      }
    } else if (itemValue is Map) {
      // Handle if it's already a Map
      return {
        'product_name': itemValue['product_name'] ?? 'Unknown',
        'product_category': itemValue['product_category'] ?? 'N/A',
        'total_quantity': itemValue['total_quantity'] ?? 0,
        'total_revenue': itemValue['total_revenue'] ?? 0,
      };
    }
    
    return {
      'product_name': 'Unknown',
      'product_category': 'N/A',
      'total_quantity': 0,
      'total_revenue': 0,
    };
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

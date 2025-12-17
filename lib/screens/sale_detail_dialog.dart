import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_admin_app/models/sale.dart';

class SaleDetailDialog extends StatelessWidget {
  final Sale sale;

  const SaleDetailDialog({Key? key, required this.sale}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sale Details - ID: ${sale.id}'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Information
              _buildSection(
                'Customer Information',
                [
                  _buildDetailRow('Name', sale.customerName),
                  _buildDetailRow('Mobile', sale.customerMobile),
                  _buildDetailRow('Email', sale.customerEmail),
                  _buildDetailRow('Address', sale.customerAddress),
                ],
              ),
              const Divider(),

              // Sale Information
              _buildSection(
                'Sale Information',
                [
                  _buildDetailRow('Date', DateFormat('MMM d, y').format(DateTime.parse(sale.date))),
                  _buildDetailRow('Status', sale.status?.toString().split('.').last.toUpperCase() ?? 'N/A'),
                  _buildDetailRow('Payment Type', sale.paymentType?.name ?? 'N/A'),
                  if (sale.paymentReferenceNumber != null)
                    _buildDetailRow('Payment Ref', sale.paymentReferenceNumber!),
                  _buildDetailRow('Delivery Type', sale.deliveryType?.name ?? 'N/A'),
                ],
              ),
              const Divider(),

              // Items
              _buildSection(
                'Items (${sale.saleItems?.length ?? 0})',
                [
                  if (sale.saleItems != null && sale.saleItems!.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Size')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Price')),
                          DataColumn(label: Text('Total')),
                        ],
                        rows: sale.saleItems!
                            .map((item) => DataRow(cells: [
                          DataCell(Text(item.productName)),
                          DataCell(Text(item.size)),
                          DataCell(Text(item.quantity.toString())),
                          DataCell(Text('₹${item.salePrice.toStringAsFixed(2)}')),
                          DataCell(Text('₹${item.totalPrice.toStringAsFixed(2)}')),
                        ]))
                            .toList(),
                      ),
                    )
                  else
                    const Text('No items'),
                ],
              ),
              const Divider(),

              // Summary
              _buildSection(
                'Summary',
                [
                  _buildSummaryRow('Total Quantity', '${sale.totalQuantity}'),
                  _buildSummaryRow('Total Price', '₹${sale.totalPrice.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

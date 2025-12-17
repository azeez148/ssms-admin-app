import 'package:flutter/material.dart';
import 'package:flutter_admin_app/models/sale.dart';
import 'package:flutter_admin_app/services/sale_service.dart';

class StatusUpdateDialog extends StatefulWidget {
  final Sale sale;
  final Function(SaleStatus) onStatusUpdated;

  const StatusUpdateDialog({
    Key? key,
    required this.sale,
    required this.onStatusUpdated,
  }) : super(key: key);

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  final SaleService _saleService = SaleService();
  
  late SaleStatus selectedStatus;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.sale.status ?? SaleStatus.pending;
  }

  Future<void> _updateStatus() async {
    setState(() => isUpdating = true);

    try {
      await _saleService.updateSaleStatus(
        widget.sale.id.toString(),
        SaleStatusUpdate(status: selectedStatus),
      );
      
      if (mounted) {
        widget.onStatusUpdated(selectedStatus);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    } finally {
      setState(() => isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Sale Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sale ID: ${widget.sale.id}'),
            const SizedBox(height: 8),
            Text('Current Status: ${widget.sale.status?.toString().split('.').last.toUpperCase()}'),
            const SizedBox(height: 16),
            const Text('Select New Status:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<SaleStatus>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: SaleStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.toString().split('.').last.toUpperCase(),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedStatus = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isUpdating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isUpdating ? null : _updateStatus,
          child: isUpdating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

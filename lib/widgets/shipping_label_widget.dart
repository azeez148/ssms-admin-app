import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_admin_app/models/sale.dart';

/// Widget for generating and printing thermal shipping labels
class ShippingLabelWidget {
  /// Generate thermal shipping label PDF
  static Future<Uint8List> generateThermalLabelPdf(Sale sale) async {
    // Calculate shipping charge
    double shippingCharge = 0;
    if (sale.deliveryType != null &&
        sale.deliveryType!.name != 'Store Pickup') {
      shippingCharge = sale.deliveryType!.charge;
    }

    // Calculate sub total
    final subTotal = sale.saleItems?.fold<double>(
          0,
          (acc, item) => acc + item.totalPrice,
        ) ??
        0;

    // Calculate total discount
    final totalDiscount =
        (subTotal + shippingCharge - sale.totalPrice).abs();

    // Build sale items table rows
    final List<pw.TableRow> itemRows = [];
    if (sale.saleItems != null && sale.saleItems!.isNotEmpty) {
      for (var item in sale.saleItems!) {
        itemRows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  '${item.productName} (${item.size})',
                  style: pw.TextStyle(fontSize: 8),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  '${item.quantity}',
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  'Rs ${item.salePrice.toStringAsFixed(0)}',
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  'Rs ${item.totalPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }
    }

    // Create PDF document for 80mm thermal label
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          80 * PdfPageFormat.mm,
          150 * PdfPageFormat.mm,
        ),
        margin: const pw.EdgeInsets.all(2),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with store name
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(bottom: 3),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 1),
                  ),
                ),
                child: pw.Text(
                  'ADrenaline Sports Store',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 3),

              // Addresses section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 0.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Ship From:',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'ADrenaline Sports\nIGC Jn, Nellikuzhy\nKothamanagalam, 686691\nMobile: 8089325733',
                            style: pw.TextStyle(fontSize: 7),
                            maxLines: 5,
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 2),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(3),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 1),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Ship To:',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            sale.customerName,
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            sale.customerAddress,
                            style: pw.TextStyle(fontSize: 7),
                            maxLines: 2,
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Mobile: ${sale.customerMobile}',
                            style: pw.TextStyle(fontSize: 7),
                          ),
                          if (sale.customerEmail.isNotEmpty)
                            pw.Text(
                              'Email: ${sale.customerEmail}',
                              style: pw.TextStyle(fontSize: 7),
                              maxLines: 1,
                              overflow: pw.TextOverflow.clip,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),

              // Order details section
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(width: 0.5),
                    bottom: pw.BorderSide(width: 0.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Order ID: #${sale.id}',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      'Date: ${sale.date.substring(0, 10)}',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      'Items: ${sale.totalQuantity}',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),

              // Items table section
              pw.Text(
                'Order Contents',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(0.8),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          'Item',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          'Qty',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          'Price',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text(
                          'Total',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  // Data rows
                  ...itemRows,
                ],
              ),
              pw.SizedBox(height: 2),

              // Summary section
              pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Sub Total:',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'Rs ${subTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Delivery Charge:',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          'Rs ${shippingCharge.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                    if (totalDiscount > 0)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total Discount:',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            '-Rs ${totalDiscount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    pw.Divider(height: 2),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Paid:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Rs ${sale.totalPrice.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),

              // Footer
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(top: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(width: 0.5),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank you for shopping with ADrenaline Sports Store',
                      style: pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'For latest updates, visit: adrenalinesportsstore.in',
                      style: pw.TextStyle(fontSize: 7),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print thermal shipping label to device printer
  static Future<void> print(BuildContext context, Sale sale) async {
    try {
      final pdfBytes = await generateThermalLabelPdf(sale);

      // Show confirmation dialog before printing
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Shipping Label Preview'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${sale.id}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Date: ${sale.date.substring(0, 10)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Shipping Address
                    const Text(
                      'Ship To:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sale.customerAddress,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mobile: ${sale.customerMobile}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (sale.customerEmail.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Email: ${sale.customerEmail}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order Items Summary
                    const Text(
                      'Items:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...?sale.saleItems?.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.productName} (${item.size})',
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Rs ${item.totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Total Amount
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Rs ${sale.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Review the details above before printing',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _sendToPrinter(context, pdfBytes, sale.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Proceed to Print'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error Generating Label'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Failed to generate shipping label:'),
                    const SizedBox(height: 12),
                    Text(
                      e.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  /// Send PDF to printer after user confirmation
  static Future<void> _sendToPrinter(
    BuildContext context,
    Uint8List pdfBytes,
    int orderId,
  ) async {
    try {
      // Show printing layout dialog with printer selection
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'Shipping_Label_Order_$orderId',
        format: PdfPageFormat(
          80 * PdfPageFormat.mm,
          150 * PdfPageFormat.mm,
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shipping label sent to printer'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Print Error'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unable to send to printer:'),
                    const SizedBox(height: 12),
                    Text(
                      e.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ensure the printer is connected and available.',
                      style: TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}

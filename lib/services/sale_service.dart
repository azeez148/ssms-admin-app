import 'package:flutter_admin_app/models/sale.dart';
import 'package:flutter_admin_app/services/api_service.dart';

class SaleService {
  late final _dio = ApiService.instance.dio;

  // Get all sales
  Future<List<Sale>> getSales() async {
    try {
      final response = await _dio.get('/sales/all');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Sale.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch sales: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sales: $e');
    }
  }

  // Get recent sales
  Future<List<Sale>> getRecentSales() async {
    try {
      final response = await _dio.get('/sales/recent');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Sale.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch recent sales: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching recent sales: $e');
    }
  }

  // Get most sold items
  Future<dynamic> getMostSoldItems() async {
    try {
      final response = await _dio.get('/sales/most-sold');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to fetch most sold items: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching most sold items: $e');
    }
  }

  // Get total sales
  Future<double> getTotalSales() async {
    try {
      final response = await _dio.get('/sales/total');
      if (response.statusCode == 200) {
        return (response.data['total_sales'] as num).toDouble();
      } else {
        throw Exception('Failed to fetch total sales: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching total sales: $e');
    }
  }

  // Create a new sale
  Future<Sale> addSale(SaleCreate sale) async {
    try {
      final response = await _dio.post(
        '/sales/addSale',
        data: sale.toJson(),
      );
      if (response.statusCode == 200) {
        return Sale.fromJson(response.data);
      } else {
        throw Exception('Failed to create sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating sale: $e');
    }
  }

  // Update sale
  Future<Sale> updateSale(String saleId, SaleCreate sale) async {
    try {
      final response = await _dio.post(
        '/sales/$saleId/updateSale',
        data: sale.toJson(),
      );
      if (response.statusCode == 200) {
        return Sale.fromJson(response.data);
      } else {
        throw Exception('Failed to update sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating sale: $e');
    }
  }

  // Complete a sale
  Future<Sale> completeSale(int saleId) async {
    try {
      final response = await _dio.put(
        '/sales/$saleId/complete',
      );
      if (response.statusCode == 200) {
        return Sale.fromJson(response.data);
      } else {
        throw Exception('Failed to complete sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error completing sale: $e');
    }
  }

  // Cancel a sale
  Future<Sale> cancelSale(int saleId) async {
    try {
      final response = await _dio.put(
        '/sales/$saleId/cancel',
      );
      if (response.statusCode == 200) {
        return Sale.fromJson(response.data);
      } else {
        throw Exception('Failed to cancel sale: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error cancelling sale: $e');
    }
  }

  // Update sale status
  Future<Sale> updateSaleStatus(String saleId, SaleStatusUpdate status) async {
    try {
      final response = await _dio.put(
        '/sales/$saleId/updateStatus',
        data: status.toJson(),
      );
      if (response.statusCode == 200) {
        return Sale.fromJson(response.data);
      } else {
        throw Exception('Failed to update sale status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating sale status: $e');
    }
  }

  // Get payment types (this might be in a different endpoint)
  Future<List<PaymentType>> getPaymentTypes() async {
    try {
      final response = await _dio.get('/paymentType/all');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PaymentType.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch payment types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payment types: $e');
    }
  }

  // Get delivery types
  Future<List<DeliveryType>> getDeliveryTypes() async {
    try {
      final response = await _dio.get('/deliveryType/all');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DeliveryType.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch delivery types: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching delivery types: $e');
    }
  }
}

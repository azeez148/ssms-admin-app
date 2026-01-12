import 'package:dio/dio.dart';
import 'package:flutter_admin_app/services/api_service.dart';
import '../models/customer.dart';
// Assuming ApiService is imported from your project core
// import '../core/api_service.dart'; 

class CustomerService {
  // Accessing your project's central Dio instance
  late final Dio _dio = ApiService.instance.dio;

  /// GET /customers/all
  Future<List<Customer>> getCustomers() async {
    try {
      final response = await _dio.get('/customers/all');
      
      // Dio automatically decodes JSON strings into Maps/Lists
      final List<dynamic> data = response.data;
      return data.map((json) => Customer.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST /customers/create
  Future<void> createCustomer(Customer customer) async {
    try {
      await _dio.post(
        '/customers/create',
        data: {
          'name': customer.name,
          'address': customer.address,
          'mobile': customer.mobile,
          'email': customer.email,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT /customers/update/{id}
  Future<void> updateCustomer(Customer customer) async {
    try {
      await _dio.put(
        '/customers/update/${customer.id}',
        data: {
          'name': customer.name,
          'address': customer.address,
          'mobile': customer.mobile,
          'email': customer.email,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE /customers/delete/{id}
  Future<void> deleteCustomer(int id) async {
    try {
      await _dio.delete('/customers/delete/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Centralized Error Handling for Dio
  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return "Connection timed out. Check your internet.";
    } else if (e.response?.statusCode == 404) {
      return "Requested resource not found.";
    } else if (e.response?.statusCode == 500) {
      return "Internal Server Error. Please try again later.";
    }
    return e.message ?? "An unexpected error occurred.";
  }
}
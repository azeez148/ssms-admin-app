import 'package:flutter/material.dart';
import 'package:flutter_admin_app/models/product.dart';
import 'package:flutter_admin_app/services/api_service.dart';

class ProductService {
  late final _dio = ApiService.instance.dio;

  Future<List<Product>> getProducts() async {
    try {
      final response = await _dio.get('/products/all');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<Product> addProduct(BuildContext context, Product product) async {
    try {
      // If you need to convert to snake_case, do it here. Assuming product.toJson() is correct.
      final response = await _dio.post('/products/addProduct', data: product.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Product.fromJson(response.data);
      } else {
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }
}

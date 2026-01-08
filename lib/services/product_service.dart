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
        return data.map((json) {
          // Ensure null integer values are converted to 0
          if (json is Map<String, dynamic>) {
            json['unit_price'] = json['unit_price'] ?? 0;
            json['selling_price'] = json['selling_price'] ?? 0;
            json['category_id'] = json['category_id'] ?? 0;
            json['discounted_price'] = json['discounted_price'] ?? 0;
            json['offer_price'] = json['offer_price'] ?? 0;
          }
          return Product.fromJson(json);
        }).toList();
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
        final json = response.data as Map<String, dynamic>;
        // Ensure null integer values are converted to 0
        json['unit_price'] = json['unit_price'] ?? 0;
        json['selling_price'] = json['selling_price'] ?? 0;
        json['category_id'] = json['category_id'] ?? 0;
        json['discounted_price'] = json['discounted_price'] ?? 0;
        json['offer_price'] = json['offer_price'] ?? 0;
        return Product.fromJson(json);
      } else {
        throw Exception('Failed to fetch product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<Product> addProduct(BuildContext context, Product product) async {
    try {
      final response = await _dio.post('/products/addProduct', data: product.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = response.data as Map<String, dynamic>;
        // Ensure null integer values are converted to 0
        json['unit_price'] = json['unit_price'] ?? 0;
        json['selling_price'] = json['selling_price'] ?? 0;
        json['category_id'] = json['category_id'] ?? 0;
        json['discounted_price'] = json['discounted_price'] ?? 0;
        json['offer_price'] = json['offer_price'] ?? 0;
        return Product.fromJson(json);
      } else {
        throw Exception('Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding product: $e');
    }
  }

  Future<Product> updateProduct(BuildContext context, int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/products/updateProduct', data: {...data, 'id': id});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = response.data as Map<String, dynamic>;
        // Ensure null integer values are converted to 0
        json['unit_price'] = json['unit_price'] ?? 0;
        json['selling_price'] = json['selling_price'] ?? 0;
        json['category_id'] = json['category_id'] ?? 0;
        json['discounted_price'] = json['discounted_price'] ?? 0;
        json['offer_price'] = json['offer_price'] ?? 0;
        return Product.fromJson(json);
      } else {
        throw Exception('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }
}

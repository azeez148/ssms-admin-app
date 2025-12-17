import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ApiService {
  final Dio _dio;
  // static const String defaultBaseUrl = 'https://api.adrenalinesportsstore.in/';
  static const String defaultBaseUrl = 'http://127.0.0.1:8000/';

  // Expose _dio for other services
  Dio get dio => _dio;

  ApiService._({String? baseUrl})
      : _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? defaultBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static ApiService? _instance;

  static ApiService get instance {
    _instance ??= ApiService._(
      baseUrl: const String.fromEnvironment(
        'API_URL',
        defaultValue: defaultBaseUrl,
      ),
    );
    return _instance!;
  }

  static void resetInstance([String? baseUrl]) {
    _instance = ApiService._(baseUrl: baseUrl);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    String baseUrl = _dio.options.baseUrl.endsWith('/') ? _dio.options.baseUrl : '${_dio.options.baseUrl}/';
    String path = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
    String url = '$baseUrl$path';
    return url;
  }

  void showSnackBar(
      BuildContext context,
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getProducts(BuildContext context) async {
    try {
      final response = await _dio.get('/products/all');
      if (response.statusCode == 200) {
        showSnackBar(context, 'Products loaded successfully');
        if (response.data is Map) {
          return response.data['products'] as List;
        }
        return response.data as List;
      }
      throw _badResponse(response, '/products/all');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProduct(
      BuildContext context,
      int id,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await _dio.post(
        '/products/updateProduct',
        data: {...data, 'id': id},
      );

      if (response.statusCode == 200) {
        showSnackBar(context, 'Product updated successfully');
        return response.data;
      }
      throw _badResponse(response, '/products/updateProduct');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getDashboardData(BuildContext context) async {
    try {
      final response = await _dio.get('/dashboard/all');
      if (response.statusCode == 200) {
        showSnackBar(context, 'Dashboard loaded successfully');
        return response.data;
      }
      throw _badResponse(response, '/dashboard/all');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Categories / Stock / Sales
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getCategories(BuildContext context) async {
    try {
      final response = await _dio.get('/api/categories/');
      showSnackBar(context, 'Categories loaded successfully');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStock(BuildContext context) async {
    try {
      final response = await _dio.get('/api/stock/');
      showSnackBar(context, 'Stock loaded successfully');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSales(BuildContext context) async {
    try {
      final response = await _dio.get('/api/sales/');
      showSnackBar(context, 'Sales loaded successfully');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Uploads
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> uploadProductImageBytes(
      BuildContext context,
      int productId,
      List<int> bytes,
      String fileName,
      ) async {
    try {
      final formData = FormData()
        ..files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(bytes, filename: fileName),
          ),
        );

      final response = await _dio.post(
        '/products/upload-images?product_id=$productId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200) {
        showSnackBar(context, 'Image uploaded successfully');
        return response.data;
      }
      throw _badResponse(response, '/products/upload-images');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> uploadProductImage(
      BuildContext context,
      int productId,
      String imagePath,
      ) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;

      return uploadProductImageBytes(
        context,
        productId,
        bytes,
        fileName,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateSizeMap(
      BuildContext context,
      int productId,
      Map<String, int> sizeMap,
      ) async {
    try {
      final response = await _dio.post(
        '/products/updateSizeMap',
        data: {
          'product_id': productId,
          'size_map': sizeMap,
        },
      );

      if (response.statusCode == 200) {
        showSnackBar(context, 'Size map updated successfully');
        return response.data;
      }
      throw _badResponse(response, '/products/updateSizeMap');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Error Handling
  // ---------------------------------------------------------------------------

  DioException _badResponse(Response response, String path) {
    return DioException(
      type: DioExceptionType.badResponse,
      response: response,
      requestOptions: RequestOptions(path: path),
    );
  }

  Exception _handleError(dynamic error) {
    String message = 'Something went wrong. Please try again.';

    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode;

      String? backendMessage;
      if (response?.data != null) {
        if (response!.data is Map) {
          backendMessage =
              response.data['message'] ??
                  response.data['detail'] ??
                  response.data['error'];
        } else if (response.data is String) {
          backendMessage = response.data;
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Server is taking too long to respond.';
          break;

        case DioExceptionType.badResponse:
          if (backendMessage != null && backendMessage.isNotEmpty) {
            message = backendMessage;
          } else if (statusCode == 401) {
            message = 'Session expired. Please login again.';
          } else if (statusCode == 403) {
            message = 'You don’t have permission to perform this action.';
          } else if (statusCode == 404) {
            message = 'Requested resource was not found.';
          } else if (statusCode != null && statusCode >= 500) {
            message = 'Server error. Please try again later.';
          }
          break;

        case DioExceptionType.connectionError:
          message =
          'Unable to connect to server. Please check your internet connection.';
          break;

        case DioExceptionType.cancel:
          message = 'Request cancelled.';
          break;

        default:
          message = backendMessage ?? error.message ?? message;
      }

      debugPrint(
        'DioError → type=${error.type}, '
            'status=$statusCode, '
            'message=${error.message}, '
            'data=${response?.data}',
      );

      return Exception(message);
    }

    return Exception(error.toString());
  }

  // ---------------------------------------------------------------------------
  // Health Check
  // ---------------------------------------------------------------------------

  Future<bool> checkServerAvailability() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

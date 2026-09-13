import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/order_model.dart';

class ApiService {
  static String get baseUrl {
    // 127.0.0.1 works for physical devices (with `adb reverse tcp:8000 tcp:8000`) and Desktop/Web
    return 'http://127.0.0.1:8000/api';
  }

  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Network Error: $e');
      throw Exception('Network Error: $e');
    }
  }

  static Future<List<Product>> getFeaturedProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/featured'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load featured products');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static Future<List<OrderModel>> getOrders({List<String>? orderNumbers, String? phone}) async {
    try {
      final queryParams = <String, String>{};
      if (orderNumbers != null && orderNumbers.isNotEmpty) {
        queryParams['order_numbers'] = orderNumbers.join(',');
      }
      if (phone != null && phone.trim().isNotEmpty) {
        queryParams['phone'] = phone.trim();
      }

      final uri = Uri.parse('$baseUrl/orders').replace(
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Network Error: $e');
      throw Exception('Network Error: $e');
    }
  }

  static Future<OrderModel> trackOrder(String orderNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/track/$orderNumber'));
      if (response.statusCode == 200) {
        return OrderModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to track order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static Future<List<OrderModel>> getAdminOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/orders'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load admin orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Network Error: $e');
      return [];
    }
  }

  static Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Failed to update status: $e');
      return false;
    }
  }
}

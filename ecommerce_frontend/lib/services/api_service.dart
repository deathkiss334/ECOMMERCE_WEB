import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'dart:io' show Platform;

class ApiService {
  // Use 10.0.2.2 for Android Emulator to connect to localhost
  static String get baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';
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

  static Future<List<OrderModel>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));
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
}

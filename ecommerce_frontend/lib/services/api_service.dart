import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/order_model.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

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

  static Future<List<OrderModel>> getOrders({List<String>? orderNumbers, String? phone, String? email}) async {
    try {
      final queryParams = <String, String>{};
      if (orderNumbers != null && orderNumbers.isNotEmpty) {
        queryParams['order_numbers'] = orderNumbers.join(',');
      }
      if (phone != null && phone.trim().isNotEmpty) {
        queryParams['phone'] = phone.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        queryParams['email'] = email.trim();
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

  static Future<OrderModel> trackOrder(String orderNumber, {String? email}) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/track/$orderNumber').replace(
        queryParameters: email != null && email.trim().isNotEmpty ? {'email': email.trim()} : null,
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return OrderModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'This order belongs to a registered customer. Please sign in to view it.');
      } else {
        throw Exception('Order not found ($orderNumber)');
      }
    } catch (e) {
      if (e is Exception) rethrow;
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

  static Future<bool> updateOrderStatus(dynamic orderId, String status, {String? trackingUrl}) async {
    try {
      final payload = {
        'status': status,
        if (trackingUrl != null && trackingUrl.isNotEmpty) 'lalamove_tracking_url': trackingUrl,
      };
      final patchResp = await http.patch(
        Uri.parse('$baseUrl/admin/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      );
      if (patchResp.statusCode == 200) return true;

      final postResp = await http.post(
        Uri.parse('$baseUrl/admin/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode(payload),
      );
      return postResp.statusCode == 200;
    } catch (e) {
      print('Failed to update status: $e');
      return false;
    }
  }

  static Future<bool> saveTrackingUrl(dynamic orderId, String trackingUrl) async {
    try {
      final payload = json.encode({
        'tracking_url': trackingUrl,
        'lalamove_tracking_url': trackingUrl,
      });
      final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
      
      final response = await http.patch(
        Uri.parse('$baseUrl/orders/$orderId/tracking'),
        headers: headers,
        body: payload,
      );
      if (response.statusCode == 200) return true;

      final fallback = await http.post(
        Uri.parse('$baseUrl/admin/orders/$orderId/tracking'),
        headers: headers,
        body: payload,
      );
      return fallback.statusCode == 200;
    } catch (e) {
      print('Failed to save tracking url: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> verifyOrder({
    required dynamic orderId,
    required String action,
    String? notes,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/orders/$orderId/verify'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'action': action,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Failed to verify order: $e');
      rethrow;
    }
  }

  /// Live Order Chat: Fetch all messages for an order
  static Future<List<dynamic>> getOrderChats(dynamic orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/chats'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['messages'] as List? ?? [];
      }
      return [];
    } catch (e) {
      print('Failed to load order chats: $e');
      return [];
    }
  }

  /// Live Order Chat: Send a message from Customer or Admin
  static Future<bool> sendOrderChat({
    required dynamic orderId,
    required String senderRole,
    required String senderName,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/chats'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'sender_role': senderRole,
          'sender_name': senderName,
          'message': message,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Failed to send order chat: $e');
      return false;
    }
  }

  /// Post-Order Rating: Fetch existing review for an order
  static Future<Map<String, dynamic>?> getOrderReview(dynamic orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/review'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['review'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Failed to fetch order review: $e');
      return null;
    }
  }

  /// Post-Order Rating: Submit 1-5 star rating and feedback
  static Future<bool> submitOrderReview({
    required dynamic orderId,
    required int rating,
    String? feedback,
    int? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/review'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'rating': rating,
          'feedback': feedback,
          if (userId != null) 'user_id': userId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Failed to submit order review: $e');
      return false;
    }
  }
}

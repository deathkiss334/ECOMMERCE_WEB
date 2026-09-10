import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class OrderService {
  static Future<List<dynamic>> getOrderHistory() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}/orders'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load orders');
    } catch (e) {
      print('Network Error (Orders): $e');
      return [];
    }
  }

  static Future<void> submitReview(int orderId, int rating, String comment) async {
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/orders/reviews'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'order_id': orderId,
          'product_id': 1,
          'rating': rating,
          'comment': comment
        }),
      );
    } catch (e) {
      print('Review Error: $e');
    }
  }
}

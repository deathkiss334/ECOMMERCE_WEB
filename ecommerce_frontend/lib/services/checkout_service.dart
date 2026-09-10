import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CheckoutService {
  static Future<Map<String, dynamic>> submitOrder({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/checkout'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'items': items,
          'payment_method': paymentMethod,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'delivery_address': deliveryAddress,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }

  /// Confirm payment once QR is scanned/paid by the customer
  static Future<Map<String, dynamic>> confirmQrPayment({
    required String orderNumber,
    String? referenceNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payments/qr-confirm'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'order_number': orderNumber,
          'reference_number': referenceNumber ?? 'QR-REF-${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('QR Payment confirmation failed: $e');
    }
  }
}

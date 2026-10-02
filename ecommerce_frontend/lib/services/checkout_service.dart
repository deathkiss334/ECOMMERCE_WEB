import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class CheckoutService {
  static Future<Map<String, dynamic>> submitOrder({
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String orderType = 'delivery',
    required String customerName,
    required String customerPhone,
    required String deliveryAddress,
    String? firstName,
    String? secondName,
    String? middleName,
    String? birthday,
    String? emailAddress,
    bool isVerified = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/checkout'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'items': items,
          'payment_method': paymentMethod,
          'order_type': orderType,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'delivery_address': deliveryAddress,
          'first_name': firstName ?? customerName,
          'second_name': secondName ?? '',
          'middle_name': middleName ?? '',
          'birthday': birthday ?? '',
          'email_address': emailAddress ?? '',
          'is_verified': isVerified,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Checkout failed: $e');
    }
  }

  /// Upload GCash Payment Receipt screenshot with optional reference number
  static Future<Map<String, dynamic>> uploadReceipt({
    required String orderNumber,
    required List<int> imageBytes,
    required String fileName,
    String? gcashRefNumber,
  }) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/orders/$orderNumber/upload-receipt');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Accept': 'application/json',
      });

      if (gcashRefNumber != null && gcashRefNumber.trim().isNotEmpty) {
        request.fields['gcash_ref_number'] = gcashRefNumber.trim();
      }

      request.fields['receipt_base64'] = base64Encode(imageBytes);

      request.files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          imageBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload GCash receipt: $e');
    }
  }

  /// Submit GCash Reference Number for manual/admin verification
  static Future<Map<String, dynamic>> submitReferenceNumber({
    required String orderNumber,
    required String referenceNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/payments/submit-reference'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json.encode({
          'order_number': orderNumber,
          'reference_number': referenceNumber,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to submit reference number: $e');
    }
  }

  /// Poll real-time order status to detect payment settlement and verification
  static Future<Map<String, dynamic>> checkOrderStatus({
    required String orderNumber,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/orders/$orderNumber/status'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Fallback to tracking endpoint if status not found
        final fallback = await http.get(
          Uri.parse('${ApiService.baseUrl}/orders/track/$orderNumber'),
          headers: {'Accept': 'application/json'},
        );
        if (fallback.statusCode == 200) {
          return json.decode(fallback.body);
        }
        throw Exception('Status check returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to check order status: $e');
    }
  }
}

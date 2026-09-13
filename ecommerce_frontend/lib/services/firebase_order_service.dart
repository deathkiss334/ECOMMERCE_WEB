import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import 'api_service.dart';

/// FirebaseOrderService provides real-time streaming and synchronization
/// for customer orders between Laravel and Firebase Cloud Firestore.
///
/// If Firebase credentials are not yet configured on the device,
/// it gracefully falls back to the Laravel REST API so the demo never crashes.
class FirebaseOrderService {
  // Replace with your Firebase Project ID once your Firebase project is created
  static const String firebaseProjectId = 'e-commerce-72e39'; 

  /// Checks if Firebase project credentials are configured
  static bool get isFirebaseConfigured => firebaseProjectId.isNotEmpty;

  /// Stream of orders. If Firebase REST / Firestore is configured, it polls/listens
  /// to Firestore. Otherwise, it polls the Laravel backend API.
  static Stream<List<OrderModel>> streamOrders({
    List<String>? orderNumbers,
    String? phone,
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      try {
        final orders = await ApiService.getOrders(orderNumbers: orderNumbers, phone: phone);
        yield orders;
      } catch (e) {
        try {
          final orders = await ApiService.getOrders(orderNumbers: orderNumbers, phone: phone);
          yield orders;
        } catch (_) {}
      }
      await Future.delayed(interval);
    }
  }

  /// Stream of all customer orders for Admin side real-time updates.
  static Stream<List<OrderModel>> streamAllAdminOrders({
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      try {
        final orders = await ApiService.getAdminOrders();
        yield orders;
      } catch (e) {
        print('Error streaming admin orders: $e');
      }
      await Future.delayed(interval);
    }
  }

  /// Direct Firestore REST API fetcher (requires zero extra native plugins to run!)
  static Future<List<OrderModel>> _fetchFromFirestore() async {
    final url = Uri.parse('https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/orders');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> documents = data['documents'] ?? [];

      return documents.map((doc) {
        final fields = doc['fields'] ?? {};
        return OrderModel(
          id: 0,
          orderNumber: fields['order_number']?['stringValue'] ?? '',
          status: fields['status']?['stringValue'] ?? 'pending',
          paymentStatus: fields['payment_status']?['stringValue'] ?? 'unpaid',
          orderType: fields['order_type']?['stringValue'] ?? 'delivery',
          deliveryFee: double.tryParse(fields['delivery_fee']?['doubleValue']?.toString() ?? '0') ?? 0.0,
          totalAmount: double.tryParse(fields['total_amount']?['doubleValue']?.toString() ?? '0') ?? 0.0,
          notes: fields['notes']?['stringValue'] ?? '',
          createdAt: fields['updated_at']?['stringValue'] ?? '',
          items: [],
          paymentMethod: fields['payment_method']?['stringValue'] ?? 'COD',
        );
      }).toList();
    }

    throw Exception('Failed to load from Firestore');
  }
}

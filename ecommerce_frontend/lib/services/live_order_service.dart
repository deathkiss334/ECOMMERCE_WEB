import 'dart:async';
import '../models/order_model.dart';
import 'api_service.dart';

/// LiveOrderService provides real-time streaming and synchronization
/// for customer and admin orders directly from the Laravel + SQLite backend.
class LiveOrderService {
  /// Stream of customer orders with live status updates (polls every 4 seconds)
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

  /// Stream of all customer orders for Admin side real-time live kitchen updates.
  static Stream<List<OrderModel>> streamAllAdminOrders({
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      try {
        final orders = await ApiService.getAdminOrders();
        yield orders;
      } catch (e) {
        // Suppress transient network polling error
      }
      await Future.delayed(interval);
    }
  }
}

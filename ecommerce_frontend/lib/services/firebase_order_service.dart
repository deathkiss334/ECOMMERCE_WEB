import 'dart:async';
import '../models/order_model.dart';
import 'live_order_service.dart';

/// Backward-compatibility alias during migration
class FirebaseOrderService {
  static Stream<List<OrderModel>> streamOrders({
    List<String>? orderNumbers,
    String? phone,
    Duration interval = const Duration(seconds: 4),
  }) => LiveOrderService.streamOrders(
        orderNumbers: orderNumbers,
        phone: phone,
        interval: interval,
      );

  static Stream<List<OrderModel>> streamAllAdminOrders({
    Duration interval = const Duration(seconds: 4),
  }) => LiveOrderService.streamAllAdminOrders(interval: interval);
}

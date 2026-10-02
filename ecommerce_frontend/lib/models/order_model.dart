class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentStatus;
  final String orderType;
  final double deliveryFee;
  final double totalAmount;
  final String notes;
  final String createdAt;
  final List<OrderItemModel> items;
  final String paymentMethod;
  final bool isRead;
  final String? customerName;
  final String? customerEmail;
  final String? gcashRefNumber;
  final String? receiptImageUrl;
  final String? adminNotes;
  final String? rejectionReason;
  final String? verifiedAt;
  final String? lalamoveTrackingUrl;
  final String? userId;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    this.orderType = 'delivery',
    this.deliveryFee = 0.0,
    required this.totalAmount,
    required this.notes,
    required this.createdAt,
    required this.items,
    required this.paymentMethod,
    this.isRead = false,
    this.customerName,
    this.customerEmail,
    this.gcashRefNumber,
    this.receiptImageUrl,
    this.adminNotes,
    this.rejectionReason,
    this.verifiedAt,
    this.lalamoveTrackingUrl,
    this.userId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    var latestPayment = json['latest_payment'] as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? json['orderId'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      orderType: json['order_type'] ?? 'DELIVERY',
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse((json['total_amount'] ?? json['totalAmount'] ?? '0').toString()) ?? 0.0,
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? json['createdAt'] ?? '',
      items: rawItems.map((i) => OrderItemModel.fromJson(i)).toList(),
      paymentMethod: latestPayment['payment_method'] ?? json['payment_method'] ?? 'GCash / QR',
      isRead: json['is_read'] ?? false,
      customerName: json['customer_name'] ?? json['customerName'],
      customerEmail: json['customer_email'] ?? json['customerEmail'],
      gcashRefNumber: json['gcash_ref_number'] ?? json['gcashRefNumber'],
      receiptImageUrl: json['receipt_image_url'] ?? json['receiptImageUrl'],
      adminNotes: json['admin_notes'] ?? json['adminNotes'],
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      verifiedAt: json['verified_at'] ?? json['verifiedAt'],
      lalamoveTrackingUrl: json['lalamove_tracking_url'] ?? json['tracking_url'] ?? json['lalamoveTrackingUrl'],
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
    );
  }

  OrderModel copyWith({
    int? id,
    String? orderNumber,
    String? status,
    String? paymentStatus,
    String? orderType,
    double? deliveryFee,
    double? totalAmount,
    String? notes,
    String? createdAt,
    List<OrderItemModel>? items,
    String? paymentMethod,
    bool? isRead,
    String? customerName,
    String? customerEmail,
    String? gcashRefNumber,
    String? receiptImageUrl,
    String? adminNotes,
    String? rejectionReason,
    String? verifiedAt,
    String? lalamoveTrackingUrl,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderType: orderType ?? this.orderType,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRead: isRead ?? this.isRead,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      gcashRefNumber: gcashRefNumber ?? this.gcashRefNumber,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      lalamoveTrackingUrl: lalamoveTrackingUrl ?? this.lalamoveTrackingUrl,
    );
  }

  DateTime? get parsedCreatedAt {
    if (createdAt.isEmpty) return null;
    return DateTime.tryParse(createdAt);
  }

  int get elapsedMinutes {
    final dt = parsedCreatedAt;
    if (dt == null) return 0;
    return DateTime.now().difference(dt.toLocal()).inMinutes;
  }

  bool get isOverdue {
    final s = status.toLowerCase();
    return (s == 'pending' || s == 'awaiting_verification') && elapsedMinutes >= 5;
  }

  String get orderTypeDisplay {
    final t = orderType.toUpperCase();
    if (t == 'DINE_IN' || t == 'DINE-IN' || t == 'DINE IN' || t == 'PICKUP' || t == 'TAKEOUT') {
      return '🍽️ Dine-in';
    }
    return '🛵 Delivery';
  }

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'AWAITING_VERIFICATION':
        return 'Awaiting Verification ⏳';
      case 'PAYMENT_REJECTED':
        return 'Payment Rejected ❌';
      case 'PREPARING':
        return 'Preparing / Kitchen 🍳';
      case 'OUT_FOR_DELIVERY':
      case 'DISPATCHED':
        return 'Out for Delivery 🛵';
      case 'RIDER_ARRIVED':
        return 'Rider Arrived 📍';
      case 'DELIVERED':
        return 'Delivered 🎉';
      case 'CANCELLED':
        return 'Cancelled / Closed ✖️';
      case 'PENDING':
      default:
        return 'Awaiting Verification ⏳';
    }
  }

  int get stepIndex {
    switch (status.toUpperCase()) {
      case 'AWAITING_VERIFICATION':
      case 'PENDING':
        return 0;
      case 'PREPARING':
        return 1;
      case 'OUT_FOR_DELIVERY':
      case 'DISPATCHED':
        return 2;
      case 'RIDER_ARRIVED':
        return 3;
      case 'DELIVERED':
        return 4;
      default:
        return -1;
    }
  }
}

class OrderItemModel {
  final int id;
  final String productName;
  final String variantName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  OrderItemModel({
    required this.id,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] ?? 0,
      productName: json['product_name_snapshot'] ?? '',
      variantName: json['variant_name_snapshot'] ?? '',
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      quantity: json['quantity'] ?? 1,
      totalPrice: double.tryParse(json['total_price'].toString()) ?? 0.0,
    );
  }
}

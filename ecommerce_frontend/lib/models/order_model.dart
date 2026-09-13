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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    var latestPayment = json['latest_payment'] as Map<String, dynamic>? ?? {};

    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      orderType: json['order_type'] ?? 'delivery',
      deliveryFee: double.tryParse(json['delivery_fee']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
      items: rawItems.map((i) => OrderItemModel.fromJson(i)).toList(),
      paymentMethod: latestPayment['payment_method'] ?? 'COD',
      isRead: json['is_read'] ?? false,
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
    return status.toLowerCase() == 'pending' && elapsedMinutes >= 5;
  }

  String get orderTypeDisplay {
    switch (orderType.toLowerCase()) {
      case 'dine_in':
        return '🍽️ Dine In';
      case 'takeout':
        return '🛍️ Takeout';
      case 'delivery':
      default:
        return '🛵 Delivery';
    }
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Confirmation';
      case 'preparing':
        return 'Preparing / Packing';
      case 'dispatched':
        return 'Out for Delivery 🛵';
      case 'delivered':
        return 'Delivered 🎉';
      case 'cancelled':
        return 'Cancelled / Refunded';
      default:
        return status;
    }
  }

  int get stepIndex {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'preparing':
        return 1;
      case 'dispatched':
        return 2;
      case 'delivered':
        return 3;
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

class ProductTableModel {
  final String productId;
  final int productQuantity;
  final String productType;
  final double productPrice;
  final String productImage;

  ProductTableModel({
    required this.productId,
    required this.productQuantity,
    required this.productType,
    required this.productPrice,
    this.productImage = '',
  });

  /// Create model from standard JSON map
  factory ProductTableModel.fromJson(Map<String, dynamic> json) {
    return ProductTableModel(
      productId: json['product_id']?.toString() ?? '',
      productQuantity: json['product_quantity'] is int
          ? json['product_quantity']
          : int.tryParse(json['product_quantity']?.toString() ?? '0') ?? 0,
      productType: json['product_type']?.toString() ?? '',
      productPrice: json['product_price'] is double
          ? json['product_price']
          : double.tryParse(json['product_price']?.toString() ?? '0.0') ?? 0.0,
      productImage: json['product_image']?.toString() ?? json['image_url']?.toString() ?? '',
    );
  }

  /// Convert model to standard JSON map
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_quantity': productQuantity,
      'product_type': productType,
      'product_price': productPrice,
      'product_image': productImage,
    };
  }

  /// Create model from Firestore REST API document format
  factory ProductTableModel.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] ?? {};
    final namePath = doc['name']?.toString() ?? '';
    final docId = namePath.split('/').last;

    return ProductTableModel(
      productId: fields['product_id']?['stringValue'] ?? docId,
      productQuantity: fields['product_quantity']?['integerValue'] != null
          ? int.tryParse(fields['product_quantity']['integerValue'].toString()) ?? 0
          : (fields['product_quantity']?['stringValue'] != null
              ? int.tryParse(fields['product_quantity']['stringValue']) ?? 0
              : 0),
      productType: fields['product_type']?['stringValue'] ?? '',
      productPrice: fields['product_price']?['doubleValue'] != null
          ? (fields['product_price']['doubleValue'] as num).toDouble()
          : (fields['product_price']?['integerValue'] != null
              ? (fields['product_price']['integerValue'] as num).toDouble()
              : double.tryParse(fields['product_price']?['stringValue'] ?? '0.0') ?? 0.0),
      productImage: fields['product_image']?['stringValue'] ?? fields['image_url']?['stringValue'] ?? '',
    );
  }

  /// Convert to Firestore REST API payload fields format
  Map<String, dynamic> toFirestoreFields() {
    return {
      'fields': {
        'product_id': {'stringValue': productId},
        'product_quantity': {'integerValue': productQuantity},
        'product_type': {'stringValue': productType},
        'product_price': {'doubleValue': productPrice},
        'product_image': {'stringValue': productImage},
      }
    };
  }
}


class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double basePrice;
  final double ratingAvg;
  final int totalReviews;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.basePrice,
    required this.ratingAvg,
    required this.totalReviews,
    required this.variants,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var variantsList = json['variants'] as List? ?? [];
    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'] ?? '',
      basePrice: double.parse(json['base_price'].toString()),
      ratingAvg: double.parse(json['rating_avg'].toString()),
      totalReviews: json['total_reviews'] ?? 0,
      variants: variantsList.map((v) => ProductVariant.fromJson(v)).toList(),
    );
  }
}

class ProductVariant {
  final int id;
  final String sku;
  final String name;
  final double price;
  final int stockQuantity;

  ProductVariant({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stockQuantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      sku: json['sku'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      stockQuantity: json['stock_quantity'] ?? 0,
    );
  }
}

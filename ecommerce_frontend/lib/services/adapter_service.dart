import '../models/product_model.dart';

// Because main.dart expects FoodItem, we map our Backend 'Product' to 'FoodItem'.
class AdapterService {
  static Map<String, dynamic> convertProductToFoodItem(Product product) {
    return {
      'id': product.id,
      'name': product.name,
      'restaurant': 'Storehouse Pickup', // Since we removed Nearby Restaurants for now
      'price': product.basePrice.toInt(),
      'rating': product.ratingAvg,
      'sold': product.totalReviews * 4, // Simulated sales numbers for UI metrics
      'badge': product.id <= 2 ? 'BESTSELLER' : '', // Top 2 get badge
      'category': _mapCategory(product.slug),
      'image': 'assets/food1.jpg', // Placeholder until S3/Local Storage images
      'description': product.description,
    };
  }

  static String _mapCategory(String slug) {
    if (slug.contains('meal')) return 'Rice Dishes';
    if (slug.contains('snack')) return 'Merienda';
    if (slug.contains('beverage')) return 'Drinks';
    return 'All';
  }
}

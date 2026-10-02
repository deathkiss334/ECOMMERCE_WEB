class FoodItem {
  final int id;
  final String name;
  final String restaurant;
  final int price;
  final double rating;
  final int sold;
  final String badge;
  final String category;
  final String image;
  final String description;

  const FoodItem({
    required this.id,
    required this.name,
    required this.restaurant,
    required this.price,
    required this.rating,
    required this.sold,
    required this.badge,
    required this.category,
    required this.image,
    required this.description,
  });
}

class CartItem {
  final FoodItem item;
  int qty;

  CartItem({required this.item, this.qty = 1});
}

final List<FoodItem> defaultFoodCatalog = const [
  FoodItem(
    id: 1,
    name: 'Adobong Manok',
    restaurant: 'Storehouse Pickup',
    price: 189,
    rating: 4.8,
    sold: 120,
    badge: 'BESTSELLER',
    category: 'Rice Dishes',
    image: 'assets/assets1.jpg',
    description: 'Classic savory garlic-soy chicken adobo served with steamed rice.',
  ),
  FoodItem(
    id: 2,
    name: 'Pork Sisig',
    restaurant: 'Storehouse Pickup',
    price: 220,
    rating: 4.9,
    sold: 210,
    badge: 'BESTSELLER',
    category: 'Rice Dishes',
    image: 'assets/assets1.jpg',
    description: 'Sizzling crispy pork sisig topped with chili and calamansi.',
  ),
  FoodItem(
    id: 3,
    name: 'Beef Bulalo',
    restaurant: 'Storehouse Pickup',
    price: 350,
    rating: 4.7,
    sold: 85,
    badge: '',
    category: 'Soups',
    image: 'assets/assets1.jpg',
    description: 'Rich slow-cooked beef shank soup with corn and cabbage.',
  ),
  FoodItem(
    id: 4,
    name: 'Halo-Halo Special',
    restaurant: 'Storehouse Pickup',
    price: 120,
    rating: 4.9,
    sold: 340,
    badge: 'POPULAR',
    category: 'Desserts',
    image: 'assets/assets1.jpg',
    description: 'Shaved ice with sweet beans, leche flan, ube halaya, and ice cream.',
  ),
  FoodItem(
    id: 5,
    name: 'Kare-Kare',
    restaurant: 'Storehouse Pickup',
    price: 290,
    rating: 4.8,
    sold: 95,
    badge: '',
    category: 'Rice Dishes',
    image: 'assets/assets1.jpg',
    description: 'Savory peanut stew with tender beef and bagoong on the side.',
  ),
];

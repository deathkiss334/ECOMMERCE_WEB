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
  // 1. Monggo - ₱20
  FoodItem(
    id: 1,
    name: 'Ginisang Monggo',
    restaurant: "Vanessa's Carinderia",
    price: 20,
    rating: 4.8,
    sold: 140,
    badge: 'POPULAR',
    category: 'Gulay & Sabaw',
    image: 'assets/dish_monggo.webp',
    description:
        'Comforting sautéed mung bean stew with spinach, garlic, and savory chicharon.',
  ),
  // 2. Beef Steak - ₱60
  FoodItem(
    id: 2,
    name: 'Bistek Tagalog (Beef Steak)',
    restaurant: "Vanessa's Carinderia",
    price: 60,
    rating: 4.9,
    sold: 230,
    badge: 'BESTSELLER',
    category: 'Ulam',
    image: 'assets/dish_beef_steak.webp',
    description:
        'Tender beef slices simmered in savory soy sauce, calamansi, and sweet onions.',
  ),
  // 3. Giniling - ₱60
  FoodItem(
    id: 3,
    name: 'Pork Giniling',
    restaurant: "Vanessa's Carinderia",
    price: 60,
    rating: 4.8,
    sold: 180,
    badge: 'POPULAR',
    category: 'Ulam',
    image: 'assets/dish_giniling.webp',
    description:
        'Savory minced pork with potatoes, carrots, and sweet green peas in tomato sauce.',
  ),
  // 4. Lumpia - ₱10/pc
  FoodItem(
    id: 4,
    name: 'Lumpiang Shanghai',
    restaurant: "Vanessa's Carinderia",
    price: 10,
    rating: 4.9,
    sold: 450,
    badge: 'BESTSELLER',
    category: 'Sides',
    image: 'assets/dish_lumpia.webp',
    description:
        'Crispy golden pork spring rolls served with sweet & sour dipping sauce (₱10/pc).',
  ),
  // 5. Sopas - ₱20
  FoodItem(
    id: 5,
    name: 'Creamy Chicken Sopas',
    restaurant: "Vanessa's Carinderia",
    price: 20,
    rating: 4.7,
    sold: 165,
    badge: '',
    category: 'Gulay & Sabaw',
    image: 'assets/dish_sopas.webp',
    description:
        'Heartwarming macaroni soup with shredded chicken in rich evaporated milk broth.',
  ),
  // 6. Spaghetti - ₱20
  FoodItem(
    id: 6,
    name: 'Pinoy Sweet Spaghetti',
    restaurant: "Vanessa's Carinderia",
    price: 20,
    rating: 4.8,
    sold: 210,
    badge: 'POPULAR',
    category: 'Meryenda & Desserts',
    image: 'assets/dish_spaghetti.webp',
    description:
        'Classic sweet-style party spaghetti topped with sliced hotdogs and grated cheese.',
  ),
  // 7. Dinakdakan - ₱120
  FoodItem(
    id: 7,
    name: 'Authentic Dinakdakan',
    restaurant: "Vanessa's Carinderia",
    price: 120,
    rating: 4.9,
    sold: 195,
    badge: 'CHEF PICK',
    category: 'Ulam',
    image: 'assets/dish_dinakdakan.webp',
    description:
        'Char-grilled pork tossed with calamansi, ginger, red onions, and rich creamy dressing.',
  ),
  // 8. Pakbet - ₱40
  FoodItem(
    id: 8,
    name: 'Pinakbet (Pakbet)',
    restaurant: "Vanessa's Carinderia",
    price: 40,
    rating: 4.7,
    sold: 130,
    badge: '',
    category: 'Gulay & Sabaw',
    image: 'assets/dish_pakbet.webp',
    description:
        'Traditional mixed veggies: squash, eggplant, okra, and sitaw sautéed in bagoong.',
  ),
  // 9. Dinuguan - ₱60
  FoodItem(
    id: 9,
    name: 'Special Dinuguan',
    restaurant: "Vanessa's Carinderia",
    price: 60,
    rating: 4.9,
    sold: 220,
    badge: 'BESTSELLER',
    category: 'Ulam',
    image: 'assets/dish_dinuguan.webp',
    description:
        'Hearty and savory pork blood stew with vinegar, garlic, and sili haba.',
  ),
  // 10. Pansit - ₱20
  FoodItem(
    id: 10,
    name: 'Pansit Guisado',
    restaurant: "Vanessa's Carinderia",
    price: 20,
    rating: 4.8,
    sold: 280,
    badge: '',
    category: 'Meryenda & Desserts',
    image: 'assets/dish_pansit.webp',
    description:
        'Stir-fried noodles with crisp vegetables, pork bits, and savory seasonings.',
  ),
  // 11. Curry - ₱60
  FoodItem(
    id: 11,
    name: 'Pinoy Chicken Curry',
    restaurant: "Vanessa's Carinderia",
    price: 60,
    rating: 4.7,
    sold: 145,
    badge: '',
    category: 'Ulam',
    image: 'assets/dish_curry.webp',
    description:
        'Fragrant Filipino-style curry with tender chicken, potatoes, and bell peppers.',
  ),
  // 12. Ginataan Bilo-Bilo - ₱150
  FoodItem(
    id: 12,
    name: 'Ginataang Bilo-Bilo',
    restaurant: "Vanessa's Carinderia",
    price: 150,
    rating: 4.9,
    sold: 110,
    badge: 'SPECIAL',
    category: 'Meryenda & Desserts',
    image: 'assets/dish_ginataan_bilobilo.webp',
    description:
        'Warm sweet coconut stew with chewy glutinous rice balls, sago, and langka.',
  ),
  // 13. Fried Chicken - ₱50
  FoodItem(
    id: 13,
    name: 'Crispy Fried Chicken',
    restaurant: "Vanessa's Carinderia",
    price: 50,
    rating: 4.9,
    sold: 310,
    badge: 'BESTSELLER',
    category: 'Ulam',
    image: 'assets/dish_fried_chicken.webp',
    description:
        'Golden-crispy seasoned fried chicken served with savory homestyle gravy.',
  ),
  // 14. Hotdog - ₱10/pc
  FoodItem(
    id: 14,
    name: 'Pinoy Red Hotdog',
    restaurant: "Vanessa's Carinderia",
    price: 10,
    rating: 4.8,
    sold: 400,
    badge: '',
    category: 'Sides',
    image: 'assets/dish_hotdog.webp',
    description:
        'Classic tender Filipino red hotdog cooked to juicy perfection (₱10/pc).',
  ),
];

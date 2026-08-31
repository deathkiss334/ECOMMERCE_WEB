import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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

final List<FoodItem> foodItemsData = [
  const FoodItem(
    id: 1,
    name: 'Adobong Manok',
    restaurant: 'Lutong Bahay ni Ate',
    price: 89,
    rating: 4.9,
    sold: 1243,
    badge: 'BESTSELLER',
    category: 'Rice Dishes',
    image: 'assets/food1.jpg',
    description:
        'A beloved Filipino classic, prepared fresh daily using traditional recipes. Rich in savory soy and garlic flavor with tender chicken pieces.',
  ),
  const FoodItem(
    id: 2,
    name: 'Sinigang na Baboy',
    restaurant: 'Kainan sa Daan',
    price: 130,
    rating: 4.8,
    sold: 876,
    badge: 'BESTSELLER',
    category: 'Soups',
    image: 'assets/food2.jpg',
    description:
        'Tangy tamarind broth with tender pork ribs and crisp native vegetables like kangkong, radish, and string beans.',
  ),
  const FoodItem(
    id: 3,
    name: 'Lechon Kawali',
    restaurant: 'Kuya Lechon',
    price: 145,
    rating: 4.9,
    sold: 654,
    badge: 'BESTSELLER',
    category: 'Grilled',
    image: 'assets/food3.jpg',
    description:
        'Crispy deep-fried pork belly with golden crackling skin and juicy meat inside. Served with our signature spiced liver sauce.',
  ),
  const FoodItem(
    id: 4,
    name: 'Pancit Canton',
    restaurant: 'Mang Kanor',
    price: 80,
    rating: 4.8,
    sold: 987,
    badge: 'BESTSELLER',
    category: 'Noodles',
    image: 'assets/food1.jpg',
    description:
        'Stir-fried egg noodles tossed with fresh market vegetables, tender pork strips, and juicy shrimp.',
  ),
  const FoodItem(
    id: 5,
    name: 'Crispy Pata',
    restaurant: 'Kuya Lechon',
    price: 280,
    rating: 4.9,
    sold: 312,
    badge: 'BESTSELLER',
    category: 'Grilled',
    image: 'assets/food2.jpg',
    description:
        'Whole pork knuckle deep-fried to maximum crunchiness. Best paired with our special chili soy-vinegar dip.',
  ),
  const FoodItem(
    id: 6,
    name: 'Bulalo',
    restaurant: 'Kainan sa Daan',
    price: 195,
    rating: 4.9,
    sold: 567,
    badge: 'BESTSELLER',
    category: 'Soups',
    image: 'assets/food3.jpg',
    description:
        'Slow-simmered beef shank and bone marrow stew with sweet corn on the cob, cabbage, and pechay.',
  ),
  const FoodItem(
    id: 7,
    name: 'Bistek Tagalog',
    restaurant: 'Lutong Bahay ni Ate',
    price: 135,
    rating: 4.7,
    sold: 521,
    badge: '',
    category: 'Rice Dishes',
    image: 'assets/food1.jpg',
    description:
        'Thinly sliced beef sirloin marinated in citrusy kalamansi and soy sauce, topped with abundant caramelized sweet onion rings.',
  ),
  const FoodItem(
    id: 8,
    name: 'Pinakbet',
    restaurant: 'Mang Kanor',
    price: 95,
    rating: 4.6,
    sold: 389,
    badge: '',
    category: 'Rice Dishes',
    image: 'assets/food2.jpg',
    description:
        'Medley of local squash, bitter melon, eggplant, and okra stewed in fragrant fermented shrimp paste and crispy pork cracklings.',
  ),
  const FoodItem(
    id: 9,
    name: 'Pork Nilaga',
    restaurant: 'Kainan sa Daan',
    price: 120,
    rating: 4.8,
    sold: 445,
    badge: '',
    category: 'Soups',
    image: 'assets/food3.jpg',
    description:
        'Clean, comforting pork soup boiled with potatoes, green saba bananas, and fresh leafy greens.',
  ),
  const FoodItem(
    id: 10,
    name: 'Pancit Bihon',
    restaurant: 'Mang Kanor',
    price: 75,
    rating: 4.7,
    sold: 678,
    badge: '',
    category: 'Noodles',
    image: 'assets/food1.jpg',
    description:
        'Delicate rice vermicelli noodles sautéed with seasoned pork, chicken, and shredded crisp cabbage.',
  ),
  const FoodItem(
    id: 11,
    name: 'Kare-Kare',
    restaurant: 'Lutong Bahay ni Ate',
    price: 160,
    rating: 4.7,
    sold: 432,
    badge: '',
    category: 'Rice Dishes',
    image: 'assets/food2.jpg',
    description:
        'Hearty stew in rich peanut sauce with tender beef, tripe, eggplant, and banana blossom. Served with authentic bagoong alamang.',
  ),
  const FoodItem(
    id: 12,
    name: 'Liempo Inihaw',
    restaurant: 'Kuya Lechon',
    price: 150,
    rating: 4.8,
    sold: 734,
    badge: 'BESTSELLER',
    category: 'Grilled',
    image: 'assets/food3.jpg',
    description:
        'Marinated pork belly grilled over charcoal to smoky perfection, basted with sweet-savory barbecue glaze.',
  ),
  const FoodItem(
    id: 13,
    name: 'Dinuguan',
    restaurant: 'Lutong Bahay ni Ate',
    price: 85,
    rating: 4.6,
    sold: 298,
    badge: '',
    category: 'Rice Dishes',
    image: 'assets/food1.jpg',
    description:
        'Rich and savory pork stew simmered in spiced vinegar and pork blood with green finger chilies.',
  ),
  const FoodItem(
    id: 14,
    name: 'Palabok',
    restaurant: 'Mang Kanor',
    price: 90,
    rating: 4.7,
    sold: 412,
    badge: 'NEW',
    category: 'Noodles',
    image: 'assets/food2.jpg',
    description:
        'Thick rice noodles smothered in golden shrimp gravy, topped with crushed chicharon, hard-boiled eggs, toasted garlic, and scallions.',
  ),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color brandColor = Color(0xFFE8411E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandColor,
          primary: brandColor,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color brandColor = Color(0xFFE8411E);

  final List<String> categories = const [
    'All',
    'Rice Dishes',
    'Noodles',
    'Soups',
    'Grilled',
    'Merienda',
    'Desserts',
    'Drinks',
  ];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Best Match';
  int _currentNavIndex = 0;
  final Set<int> _savedItemIds = {};
  final List<CartItem> _cart = [];

  int get cartCount => _cart.fold(0, (sum, item) => sum + item.qty);
  int get cartTotal => _cart.fold(0, (sum, item) => sum + (item.item.price * item.qty));

  List<FoodItem> get filteredItems {
    return foodItemsData.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.restaurant.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _toggleSave(int id) {
    setState(() {
      if (_savedItemIds.contains(id)) {
        _savedItemIds.remove(id);
      } else {
        _savedItemIds.add(id);
      }
    });
  }

  void _addToCart(FoodItem item, int qty) {
    setState(() {
      final index = _cart.indexWhere((c) => c.item.id == item.id);
      if (index != -1) {
        _cart[index].qty += qty;
      } else {
        _cart.add(CartItem(item: item, qty: qty));
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${item.name} (x$qty) to Cart'),
        duration: const Duration(seconds: 1),
        backgroundColor: brandColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeFromCart(int id) {
    setState(() {
      _cart.removeWhere((c) => c.item.id == id);
    });
  }

  void _showItemDetailModal(FoodItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemDetailBottomSheet(
        item: item,
        isSaved: _savedItemIds.contains(item.id),
        onToggleSave: () => _toggleSave(item.id),
        onAddToCart: (qty) {
          _addToCart(item, qty);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return _CartBottomSheet(
            cart: _cart,
            cartTotal: cartTotal,
            cartCount: cartCount,
            onRemove: (id) {
              _removeFromCart(id);
              setSheetState(() {});
            },
            onCheckout: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed successfully! 🚀'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              setState(() {
                _cart.clear();
              });
            },
          );
        },
      ),
    );
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ProfileBottomSheet(),
    );
  }

  void _showNearbyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _NearbyRestaurantsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            _buildTopHeader(isDesktop),

            // Search Bar
            _buildSearchBar(),

            // Category Pills
            _buildCategoryPills(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Hero Banner
                      _buildHeroBanner(),
                      const SizedBox(height: 12),

                      // Feature Cards (Made Fresh / Easy Ordering)
                      _buildFeatureCards(),
                      const SizedBox(height: 20),

                      // Today's Picks (Horizontal scroll)
                      _buildTodaysPicks(),
                      const SizedBox(height: 20),

                      // Nearby Restaurants (Preview list)
                      _buildNearbySection(),
                      const SizedBox(height: 20),

                      // Popular Right Now (Grid)
                      _buildPopularSection(isDesktop),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopHeader(bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deliver to',
                style: TextStyle(fontSize: 10, color: Color(0xFF9E9E9E), height: 1),
              ),
              const SizedBox(height: 2),
              Row(
                children: const [
                  Text(
                    'Dasmariñas, Cavite',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF424242)),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Cart Button in Header for fast access
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _showCartModal,
                icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF212121), size: 24),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: brandColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search food, restaurants...',
                  hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = cat),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? brandColor : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 165,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/assets1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: brandColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '🇵🇭 LOCAL FAVORITES',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authentic Filipino Food\nDelivered to You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'From Dasmariñas kitchens to your door.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Made Fresh
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_outline, color: Color(0xFF7C3AED), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Made Fresh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                        SizedBox(height: 1),
                        Text('Cooked to order', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Easy Ordering
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brandColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Easy Ordering', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(height: 1),
                        Text('Browse, pick, enjoy', style: TextStyle(fontSize: 10, color: Colors.white70), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysPicks() {
    final picks = foodItemsData.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "⭐ Today's Picks",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: const Text('See all →', style: TextStyle(color: brandColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: picks.length,
            itemBuilder: (context, index) {
              final item = picks[index];
              final isSaved = _savedItemIds.contains(item.id);
              return Container(
                width: 145,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _showItemDetailModal(item),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image & Badges
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: Image.asset(
                                item.image,
                                height: 95,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (item.badge.isNotEmpty)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.badge,
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () => _toggleSave(item.id),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isSaved ? Icons.favorite : Icons.favorite_border,
                                    size: 13,
                                    color: isSaved ? brandColor : const Color(0xFF9E9E9E),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Details
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.restaurant,
                                style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱${item.price}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandColor),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 11),
                                      const SizedBox(width: 1),
                                      Text(
                                        '${item.rating}',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNearbySection() {
    final restaurants = ['Lutong Bahay ni Ate', 'Kainan sa Daan', 'Kuya Lechon', 'Mang Kanor'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🗺️ Nearby Restaurants',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              TextButton(
                onPressed: _showNearbyModal,
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                child: const Text('See all →', style: TextStyle(color: brandColor, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 135,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final name = restaurants[index];
              return Container(
                width: 145,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: _showNearbyModal,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          child: Center(
                            child: Icon(Icons.storefront, color: Colors.grey.shade400, size: 28),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: const [
                                  Icon(Icons.star, color: Colors.amber, size: 10),
                                  SizedBox(width: 2),
                                  Text('4.8 · 1.2 km', style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSection(bool isDesktop) {
    final list = filteredItems;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    '🔥 Popular Right Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${list.length})',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6B7280)),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                  items: const [
                    DropdownMenuItem(value: 'Best Match', child: Text('Best Match')),
                    DropdownMenuItem(value: 'Price: Low', child: Text('Price: Low')),
                    DropdownMenuItem(value: 'Rating', child: Text('Rating')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sortBy = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final isSaved = _savedItemIds.contains(item.id);
              return InkWell(
                onTap: () => _showItemDetailModal(item),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image & Badges
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                            child: Image.asset(
                              item.image,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (item.badge.isNotEmpty)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.badge == 'NEW' ? Colors.green.shade600 : Colors.amber.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.badge,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: () => _toggleSave(item.id),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSaved ? Icons.favorite : Icons.favorite_border,
                                  size: 13,
                                  color: isSaved ? brandColor : const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.restaurant,
                                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item.rating}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '· ${item.sold} sold',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₱${item.price}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: brandColor),
                                  ),
                                  InkWell(
                                    onTap: () => _addToCart(item, 1),
                                    borderRadius: BorderRadius.circular(15),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: brandColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 2) {
            _showCartModal();
          } else if (index == 3) {
            _showProfileModal();
          }
        },
        selectedItemColor: brandColor,
        unselectedItemColor: const Color(0xFF9CA3AF),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined),
                if (cartCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Text(
                        '$cartCount',
                        style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── BOTTOM SHEETS ──

class _ItemDetailBottomSheet extends StatefulWidget {
  final FoodItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final Function(int qty) onAddToCart;

  const _ItemDetailBottomSheet({
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    required this.onAddToCart,
  });

  @override
  State<_ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends State<_ItemDetailBottomSheet> {
  static const Color brandColor = Color(0xFFE8411E);
  int qty = 1;
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      child: Column(
        children: [
          // Image Header
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.asset(
                  widget.item.image,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF374151)),
                  ),
                ),
              ),
            ],
          ),
          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.restaurant, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 2),
                  Text(widget.item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('${widget.item.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 6),
                      Text('· ${widget.item.sold} sold', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.item.description,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  const Text('Special Instructions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'E.g. no spice, extra sauce, less salt...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: brandColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                // Quantity Selector
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (qty > 1) setState(() => qty--);
                        },
                        icon: const Icon(Icons.remove, size: 16),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      IconButton(
                        onPressed: () => setState(() => qty++),
                        icon: const Icon(Icons.add, size: 16),
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Add Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onAddToCart(qty),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add to Cart', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('₱${widget.item.price * qty}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartBottomSheet extends StatelessWidget {
  final List<CartItem> cart;
  final int cartTotal;
  final int cartCount;
  final Function(int id) onRemove;
  final VoidCallback onCheckout;

  const _CartBottomSheet({
    required this.cart,
    required this.cartTotal,
    required this.cartCount,
    required this.onRemove,
    required this.onCheckout,
  });

  static const Color brandColor = Color(0xFFE8411E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Your Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          // Items list or Empty State
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 64, color: Color(0xFFD1D5DB)),
                        const SizedBox(height: 12),
                        const Text('Your cart is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
                        const SizedBox(height: 4),
                        const Text('Add something delicious to get started.', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Browse Menu →', style: TextStyle(color: brandColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(item.item.image, width: 56, height: 56, fit: BoxFit.cover),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.item.restaurant, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                                  Text(item.item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                                  const SizedBox(height: 2),
                                  Text('₱${item.item.price} × ${item.qty}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: brandColor)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => onRemove(item.item.id),
                              icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Checkout Section
          if (cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total ($cartCount items)', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                      Text('₱$cartTotal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Place Order', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileBottomSheet extends StatelessWidget {
  const _ProfileBottomSheet();

  static const Color brandColor = Color(0xFFE8411E);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Guest User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  Text('Sign in / Register →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brandColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),
          _buildMenuItem(Icons.receipt_long_outlined, 'My Orders', () => Navigator.pop(context)),
          _buildMenuItem(Icons.location_on_outlined, 'Saved Addresses', () => Navigator.pop(context)),
          _buildMenuItem(Icons.favorite_outline, 'Saved Items', () => Navigator.pop(context)),
          _buildMenuItem(Icons.settings_outlined, 'Settings', () => Navigator.pop(context)),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 4),
          _buildMenuItem(Icons.logout, 'Sign Out', () => Navigator.pop(context), isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? brandColor : const Color(0xFF4B5563), size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
          color: isDestructive ? brandColor : const Color(0xFF1F2937),
        ),
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
      onTap: onTap,
    );
  }
}

class _NearbyRestaurantsBottomSheet extends StatelessWidget {
  const _NearbyRestaurantsBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nearby Restaurants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final names = ['Lutong Bahay ni Ate', 'Kainan sa Daan', 'Kuya Lechon', 'Mang Kanor', 'Nanay’s Grill', 'Cavite Express'];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.restaurant, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(names[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                            const SizedBox(height: 2),
                            const Text('Filipino · Rice Dishes · Soups', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.star, color: Colors.amber, size: 12),
                                SizedBox(width: 2),
                                Text('4.8 (250+)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
                                SizedBox(width: 8),
                                Text('· 1.2 km · 20-30 mins', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

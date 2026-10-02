import 'services/guest_order_storage.dart';
import 'widgets/qr_payment_modal.dart';
import 'widgets/order_history_sheet.dart';
import 'services/checkout_service.dart';
import 'services/order_service.dart';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/adapter_service.dart';
import 'models/user_model.dart';
import 'services/firebase_user_service.dart';
import 'admin/admin_layout.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'landing_page.dart';


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

List<FoodItem> foodItemsData = [];

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color brandColor = Color(0xFFF36F21);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DasmaBITES - Your Favorite Bites, Just a Click Away!',
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
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/shop': (context) => const HomeScreen(),
        '/admin': (context) => const AdminLayout(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    GuestOrderStorage.getStoredOrderNumbers().then((stored) {
      if (mounted && stored.isNotEmpty) {
        setState(() {
          for (final o in stored) {
            if (!_sessionOrderNumbers.contains(o)) _sessionOrderNumbers.add(o);
          }
        });
      }
    });
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await ApiService.getProducts();
      if (products.isNotEmpty) {
        setState(() {
          foodItemsData = products.map((p) {
            final mapped = AdapterService.convertProductToFoodItem(p);
            return FoodItem(
              id: mapped['id'],
              name: mapped['name'],
              restaurant: mapped['restaurant'],
              price: mapped['price'],
              rating: mapped['rating'],
              sold: mapped['sold'],
              badge: mapped['badge'],
              category: mapped['category'],
              image: mapped['image'],
              description: mapped['description'],
            );
          }).toList();
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Laravel local server offline ($e). Operating with default catalog.');
    }

    if (mounted) {
      setState(() {
        foodItemsData = defaultFoodCatalog;
        isLoading = false;
      });
    }
  }

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

  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Best Match';
  int _currentNavIndex = 0;
  final Set<int> _savedItemIds = {};
  final List<CartItem> _cart = [];
  final List<String> _sessionOrderNumbers = [];
  UserModel _currentUser = FirebaseUserService.currentUser;

  int get cartCount => _cart.fold(0, (sum, item) => sum + item.qty);
  int get cartTotal => _cart.fold(0, (sum, item) => sum + (item.item.price * item.qty));

  List<FoodItem> get filteredItems {
    final query = _searchQuery.trim().toLowerCase();

    final items = foodItemsData.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.restaurant.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low':
        items.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Rating':
        items.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return items;
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
              if (_cart.isEmpty) return;
              Navigator.pop(ctx);
              _showCheckoutCustomerForm();
            },
          );
        },
      ),
    );
  }

  void _showCheckoutCustomerForm({
    String? initialFullName,
    String? initialEmail,
    String? initialAddress,
    String? initialOrderType,
  }) {
    if (_cart.isEmpty) return;

    final isVerified = _currentUser.isVerified;
    final defaultFullName = _currentUser.fullName.isNotEmpty
        ? _currentUser.fullName
        : '${_currentUser.firstName} ${_currentUser.secondName}'.trim();

    final fullNameCtrl = TextEditingController(text: initialFullName ?? (isVerified ? defaultFullName : ''));
    final emailCtrl = TextEditingController(text: initialEmail ?? (isVerified ? _currentUser.emailAddress : ''));
    final addressCtrl = TextEditingController(text: initialAddress ?? (isVerified ? _currentUser.address : ''));

    String selectedOrderType = initialOrderType ?? 'delivery';

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) {
          final isDelivery = selectedOrderType == 'delivery';

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Checkout Details',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dlgCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Notification Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isVerified ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isVerified ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isVerified ? Icons.verified_user : Icons.person_outline,
                            size: 18,
                            color: isVerified ? Colors.green[800] : Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isVerified
                                  ? '✨ Verified Customer: Name, Email & Address Auto-Filled!'
                                  : '👤 Express Checkout: Please provide your name and email.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isVerified ? Colors.green[900] : Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Form Fields (Scrollable)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Order Option Selector: Segmented Card-Style Toggle Buttons
                            const Text(
                              'Order Option',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // [ 🛵 Delivery ] Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setDlgState(() => selectedOrderType = 'delivery'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeInOut,
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isDelivery ? brandColor.withValues(alpha: 0.12) : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDelivery ? brandColor : const Color(0xFFE5E7EB),
                                          width: isDelivery ? 2 : 1,
                                        ),
                                        boxShadow: isDelivery
                                            ? [
                                                BoxShadow(
                                                  color: brandColor.withValues(alpha: 0.18),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Column(
                                        children: [
                                          const Text('🛵', style: TextStyle(fontSize: 22)),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Delivery',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: isDelivery ? brandColor : const Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+₱10 Delivery Fee',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDelivery ? brandColor : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // [ 🍽️ Dine-in ] Button
                                Expanded(
                                  child: InkWell(
                                    onTap: () => setDlgState(() => selectedOrderType = 'dine_in'),
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeInOut,
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: !isDelivery ? brandColor.withValues(alpha: 0.12) : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: !isDelivery ? brandColor : const Color(0xFFE5E7EB),
                                          width: !isDelivery ? 2 : 1,
                                        ),
                                        boxShadow: !isDelivery
                                            ? [
                                                BoxShadow(
                                                  color: brandColor.withValues(alpha: 0.18),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Column(
                                        children: [
                                          const Text('🍽️', style: TextStyle(fontSize: 22)),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Dine-in',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: !isDelivery ? brandColor : const Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Store Pickup / Dine-in',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: !isDelivery ? Colors.green[700] : const Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 2. Full Name
                            _buildFormField(
                              'Full Name',
                              fullNameCtrl,
                              Icons.person_outline,
                              hintText: 'e.g. Maria Santos',
                            ),
                            const SizedBox(height: 12),

                            // 3. Email Address
                            _buildFormField(
                              'Email Address',
                              emailCtrl,
                              Icons.email_outlined,
                              hintText: 'e.g. maria.santos@email.com',
                            ),

                            // 4. Delivery Address (with Delivery Notes / Landmark) - Hidden if Dine-in
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 250),
                              crossFadeState: isDelivery ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                              firstChild: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: _buildFormField(
                                  'Delivery Address (with Delivery Notes / Landmark)',
                                  addressCtrl,
                                  Icons.location_on_outlined,
                                  maxLines: 2,
                                  hintText: 'House/Room No., Street, Barangay, Landmark (e.g. Near Gate 1)',
                                ),
                              ),
                              secondChild: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final fullName = fullNameCtrl.text.trim();
                          final email = emailCtrl.text.trim();
                          final address = addressCtrl.text.trim();

                          if (fullName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter your Full Name'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid Email Address'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (isDelivery && address.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please provide your Delivery Address and landmark'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dlgCtx);

                          // Proceed to Step 2: Dedicated Order Summary Modal
                          _showOrderSummaryModal(
                            fullName: fullName,
                            email: email,
                            address: isDelivery ? address : 'Dine-in (Store)',
                            orderType: selectedOrderType,
                            isVerified: isVerified,
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Proceed to Order Summary',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOrderSummaryModal({
    required String fullName,
    required String email,
    required String address,
    required String orderType,
    required bool isVerified,
  }) {
    if (_cart.isEmpty) return;

    String selectedPaymentMethod = 'gcash';

    showDialog(
      context: context,
      builder: (summaryCtx) => StatefulBuilder(
        builder: (summaryCtx, setSummaryState) {
          final isDelivery = orderType == 'delivery' || orderType == 'DELIVERY';
          final int deliveryFee = isDelivery ? 10 : 0;
          final int checkoutTotal = cartTotal + deliveryFee;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, size: 20),
                              tooltip: 'Edit Details',
                              onPressed: () {
                                Navigator.pop(summaryCtx);
                                _showCheckoutCustomerForm(
                                  initialFullName: fullName,
                                  initialEmail: email,
                                  initialAddress: address,
                                  initialOrderType: orderType,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Order Summary',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(summaryCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Scrollable summary content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Customer & Order Option Card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: brandColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isDelivery ? '🛵 Delivery' : '🍽️ Dine-in',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: brandColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('📧 Email: $email', style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                                  if (isDelivery && address.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text('🏠 Address: $address', style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Itemized Cart Summary
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.shopping_bag_outlined, size: 16, color: brandColor),
                                          SizedBox(width: 6),
                                          Text(
                                            'Items Summary',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827)),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${_cart.length} ${_cart.length == 1 ? 'item' : 'items'}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                  const SizedBox(height: 8),
                                  ..._cart.map((cartItem) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${cartItem.qty}x  ${cartItem.item.name}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₱${(cartItem.item.price * cartItem.qty).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF111827), fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                      Text('₱${cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Delivery Fee', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                          if (!isDelivery)
                                            const Text(' (Waived)', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      Text(
                                        isDelivery ? '₱10.00' : '₱0.00',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDelivery ? const Color(0xFF374151) : Colors.green,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF111827))),
                                      Text(
                                        '₱${checkoutTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: brandColor),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Payment Method Selection
                            Row(
                              children: [
                                const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                ChoiceChip(
                                  label: const Text('GCash / QR'),
                                  selected: selectedPaymentMethod == 'gcash',
                                  onSelected: (_) => setSummaryState(() => selectedPaymentMethod = 'gcash'),
                                  selectedColor: brandColor.withValues(alpha: 0.2),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('COD'),
                                  selected: selectedPaymentMethod == 'cod',
                                  onSelected: (_) => setSummaryState(() => selectedPaymentMethod = 'cod'),
                                  selectedColor: brandColor.withValues(alpha: 0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final orderItems = _cart.map((c) => {'id': c.item.id, 'qty': c.qty}).toList();

                          Navigator.pop(summaryCtx);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            final submittedUser = UserModel(
                              firstName: fullName,
                              secondName: '',
                              middleName: '',
                              birthday: '',
                              address: address,
                              phoneNumber: _currentUser.phoneNumber,
                              emailAddress: email,
                              isVerified: isVerified,
                            );
                            setState(() => _currentUser = submittedUser);

                            final result = await CheckoutService.submitOrder(
                              items: orderItems,
                              paymentMethod: selectedPaymentMethod,
                              orderType: orderType,
                              customerName: fullName,
                              customerPhone: _currentUser.phoneNumber.isNotEmpty ? _currentUser.phoneNumber : '09123456789',
                              deliveryAddress: address,
                              firstName: fullName,
                              emailAddress: email,
                              isVerified: isVerified,
                            );

                            if (result.containsKey('order_number') || result.containsKey('orderId')) {
                              final newOrderNum = (result['order_number'] ?? result['orderId']).toString();
                              if (!_sessionOrderNumbers.contains(newOrderNum)) {
                                _sessionOrderNumbers.add(newOrderNum);
                              }
                              await GuestOrderStorage.saveOrderNumber(newOrderNum);
                            }

                            Navigator.pop(context); // Pop loading
                            setState(() => _cart.clear());

                            if (result.containsKey('qr_image_url')) {
                              showDialog(
                                context: context,
                                builder: (_) => QrPaymentModal(
                                  orderNumber: result['order_number'],
                                  totalAmount: (result['total_amount'] as num).toDouble(),
                                  qrImageUrl: result['qr_image_url'],
                                  orderType: orderType,
                                  subtotal: cartTotal.toDouble(),
                                  deliveryFee: deliveryFee.toDouble(),
                                  onPaymentComplete: () {
                                    _showOrdersModal();
                                  },
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order ${result['order_number']} Placed Successfully! 🎉'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context); // Pop loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Checkout Error: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Text(
                          'Place Order • ₱$checkoutTotal',
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              borderSide: BorderSide(color: brandColor),
            ),
          ),
        ),
      ],
    );
  }

  void _showOrdersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderHistorySheet(
        sessionOrderNumbers: _sessionOrderNumbers,
        userPhone: _currentUser.phoneNumber,
        userEmail: _currentUser.emailAddress,
        userName: _currentUser.firstName,
      ),
    );
  }

  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileBottomSheet(
        
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : Column(
          children: [
            // Top Header
            _buildTopHeader(isDesktop),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Hero Banner (Photo)
                          _buildHeroBanner(isDesktop),
                          const SizedBox(height: 12),

                          // Search Bar (Under Photo)
                          _buildSearchBar(),

                          // Category Filters (Under Search Bar)
                          _buildCategoryPills(),
                          const SizedBox(height: 12),

                          // Feature Cards (Made Fresh / Easy Ordering)
                          _buildFeatureCards(),
                          const SizedBox(height: 20),

                          // Today's Picks (Horizontal scroll)
                          _buildTodaysPicks(),
                          const SizedBox(height: 20),

                          // Popular Right Now (Grid)
                          _buildPopularSection(isDesktop),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
    );
  }

  Widget _buildTopHeader(bool isDesktop) {
    final horizontalPadding = isDesktop ? 24.0 : 16.0;

    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
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
          IconButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.home_outlined, color: Color(0xFF212121), size: 24),
            tooltip: 'Home Landing',
          ),
          // High-visibility My Orders List & Live Tracking Button
          ElevatedButton.icon(
            onPressed: _showOrdersModal,
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('My Orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
          if (_currentUser.isVerified) ...[
            if (_currentUser.isAdmin) ...[
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin'),
                icon: const Icon(Icons.dashboard, size: 14, color: Colors.white),
                label: const Text('Admin Portal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(width: 6),
            ],
            InkWell(
              onTap: _showOrdersModal,
              borderRadius: BorderRadius.circular(20),
              child: Tooltip(
                message: 'Click to view your orders',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        _currentUser.firstName.isNotEmpty ? _currentUser.firstName : 'Verified User',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.receipt_long, size: 12, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: () {
                setState(() => _currentUser = UserModel.guest());
                FirebaseUserService.setCurrentUser(_currentUser);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged Out successfully')),
                );
              },
              icon: const Icon(Icons.logout, size: 16, color: Colors.black54),
              label: const Text('Log Out', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/login');
                setState(() => _currentUser = FirebaseUserService.currentUser);
              },
              icon: const Icon(Icons.login, size: 18, color: Colors.black87),
              label: const Text('Log In', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/signup');
                setState(() => _currentUser = FirebaseUserService.currentUser);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: brandColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
            ),
          ],
        ],
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                focusNode: _searchFocusNode,
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
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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

  Widget _buildHeroBanner(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: isDesktop ? 260 : 165,
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
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
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
              Text(
                'Authentic Filipino Food\nDelivered to You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 26 : 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'From Dasmariñas kitchens to your door.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isDesktop ? 13 : 11,
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
          // My Orders & Live Tracking Feature Card
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showOrdersModal,
                borderRadius: BorderRadius.circular(14),
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
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('My Orders & Tracking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 1),
                            Text('Live status, map & chat →', style: TextStyle(fontSize: 10, color: Colors.white70), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          Builder(
            builder: (context) {
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth >= 1400 ? 5 : (screenWidth >= 1050 ? 4 : (screenWidth >= 700 ? 3 : 2));
              final childAspectRatio = screenWidth >= 700 ? 0.75 : 0.70;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
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
          if (index == 0) {
            setState(() {
              _selectedCategory = 'All';
              _searchQuery = '';
              _currentNavIndex = 0;
            });
            if (_scrollController.hasClients) {
              _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            }
            return;
          }
          if (index == 1) {
            setState(() => _currentNavIndex = 1);
            if (_scrollController.hasClients) {
              _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
            }
            _searchFocusNode.requestFocus();
            return;
          }
          if (index == 2) {
            _showCartModal();
            return;
          }
          if (index == 3) {
            _showOrdersModal();
            return;
          }
          setState(() => _currentNavIndex = index);
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
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'My Orders',
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
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
    ),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
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
    ),
      ),
    );
  }
}

class _ProfileBottomSheet extends StatefulWidget {
  const _ProfileBottomSheet();
  @override
  State<_ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<_ProfileBottomSheet> {
  List<dynamic> myOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final result = await OrderService.getOrderHistory();
    if(mounted) {
        setState(() {
          myOrders = result;
          isLoading = false;
        });
    }
  }

  void _showReviewDialog(int orderId) {
    TextEditingController _comment = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your order?'),
              const SizedBox(height: 10),
              TextField(
                controller: _comment,
                decoration: const InputDecoration(
                   hintText: 'Great food, arrived hot!',
                   border: OutlineInputBorder(),
                ),
                maxLines: 2,
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
               onPressed: () async {
                   Navigator.pop(ctx);
                   await OrderService.submitReview(orderId, 5, _comment.text);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted! Thank you.')));
               }, 
               child: const Text('Submit')
            )
          ],
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('👤 Profile & Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]
          ),
          const Divider(),
          const Text('Live Delivery Tracking & History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : myOrders.isEmpty 
                  ? const Center(child: Text('No orders found.')) 
                  : ListView.builder(
                      itemCount: myOrders.length,
                      itemBuilder: (context, index) {
                         final o = myOrders[index];
                         return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                               border: Border.all(color: Colors.grey.shade300),
                               borderRadius: BorderRadius.circular(12)
                            ),
                            child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(o['order_number'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: o['status'] == 'completed' ? Colors.green.shade100 : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(8)
                                        ),
                                        child: Text(o['status'].toString().toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
                                      )
                                    ]
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Total: ₱' + o['total_amount'].toString(), style: const TextStyle(color: Color(0xFFE8411E), fontWeight: FontWeight.bold)),
                                  if (o['status'] == 'completed') ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                           onPressed: () => _showReviewDialog(o['id']),
                                           child: const Text('Leave a Review (5⭐)')
                                        )
                                      )
                                  ]
                               ]
                            )
                         );
                      }
                  )
          )
        ],
      ),
    ),
      ),
    );
  }
}
// END OF FILE
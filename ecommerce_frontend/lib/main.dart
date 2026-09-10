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

  static const Color brandColor = Color(0xFFE8411E);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery Web UI',
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
      routes: {
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

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Best Match';
  int _currentNavIndex = 0;
  final Set<int> _savedItemIds = {};
  final List<CartItem> _cart = [];
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

  void _showCheckoutCustomerForm() {
    if (_cart.isEmpty) return;

    final isVerified = _currentUser.isVerified;

    final firstNameCtrl = TextEditingController(text: isVerified ? _currentUser.firstName : '');
    final secondNameCtrl = TextEditingController(text: isVerified ? _currentUser.secondName : '');
    final middleNameCtrl = TextEditingController(text: isVerified ? _currentUser.middleName : '');
    final birthdayCtrl = TextEditingController(text: isVerified ? _currentUser.birthday : '');
    final addressCtrl = TextEditingController(text: isVerified ? _currentUser.address : '');
    final phoneCtrl = TextEditingController(text: isVerified ? _currentUser.phoneNumber : '');
    final emailCtrl = TextEditingController(text: isVerified ? _currentUser.emailAddress : '');

    bool currentVerifiedMode = isVerified;
    String selectedPaymentMethod = 'gcash';

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setDlgState) {
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
                        color: currentVerifiedMode ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: currentVerifiedMode ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentVerifiedMode ? Icons.verified_user : Icons.person_outline,
                            size: 18,
                            color: currentVerifiedMode ? Colors.green[800] : Colors.orange[800],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentVerifiedMode
                                  ? '✨ Verified User: Name, Address & Phone Auto-Filled!'
                                  : '👤 Guest Mode: Please enter your personal details below to place your order.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: currentVerifiedMode ? Colors.green[900] : Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Form Fields (Scrollable)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildFormField('First Name', firstNameCtrl, Icons.person)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildFormField('Second (Last) Name', secondNameCtrl, Icons.person_outline)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildFormField('Middle Name', middleNameCtrl, Icons.badge)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildFormField('Birthday (YYYY-MM-DD)', birthdayCtrl, Icons.cake)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildFormField('Delivery Address', addressCtrl, Icons.home),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildFormField('Phone Number', phoneCtrl, Icons.phone)),
                                const SizedBox(width: 10),
                                Expanded(child: _buildFormField('Email Address', emailCtrl, Icons.email)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                ChoiceChip(
                                  label: const Text('GCash / QR'),
                                  selected: selectedPaymentMethod == 'gcash',
                                  onSelected: (_) => setDlgState(() => selectedPaymentMethod = 'gcash'),
                                  selectedColor: brandColor.withValues(alpha: 0.2),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('COD'),
                                  selected: selectedPaymentMethod == 'cod',
                                  onSelected: (_) => setDlgState(() => selectedPaymentMethod = 'cod'),
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
                          if (firstNameCtrl.text.trim().isEmpty ||
                              addressCtrl.text.trim().isEmpty ||
                              phoneCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in required fields (Name, Address, Phone)'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final orderItems = _cart.map((c) => {'id': c.item.id, 'qty': c.qty}).toList();
                          final customerFullName = '${firstNameCtrl.text} ${secondNameCtrl.text}'.trim();

                          Navigator.pop(dlgCtx);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            final submittedUser = UserModel(
                              firstName: firstNameCtrl.text,
                              secondName: secondNameCtrl.text,
                              middleName: middleNameCtrl.text,
                              birthday: birthdayCtrl.text,
                              address: addressCtrl.text,
                              phoneNumber: phoneCtrl.text,
                              emailAddress: emailCtrl.text,
                              isVerified: currentVerifiedMode,
                            );
                            setState(() => _currentUser = submittedUser);
                            FirebaseUserService.saveUserProfileToFirebase(submittedUser);

                            final result = await CheckoutService.submitOrder(
                              items: orderItems,
                              paymentMethod: selectedPaymentMethod,
                              customerName: customerFullName,
                              customerPhone: phoneCtrl.text,
                              deliveryAddress: addressCtrl.text,
                              firstName: firstNameCtrl.text,
                              secondName: secondNameCtrl.text,
                              middleName: middleNameCtrl.text,
                              birthday: birthdayCtrl.text,
                              emailAddress: emailCtrl.text,
                              isVerified: currentVerifiedMode,
                            );

                            Navigator.pop(context); // Pop loading
                            setState(() => _cart.clear());

                            if (result.containsKey('qr_image_url')) {
                              showDialog(
                                context: context,
                                builder: (_) => QrPaymentModal(
                                  orderNumber: result['order_number'],
                                  totalAmount: (result['total_amount'] as num).toDouble(),
                                  qrImageUrl: result['qr_image_url'],
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
                          'Place Order • ₱$cartTotal',
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

  Widget _buildFormField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(icon, size: 16, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: brandColor),
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
      builder: (ctx) => const OrderHistorySheet(),
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
                child: Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Hero Banner (Photo)
                      _buildHeroBanner(),
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
            Container(
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
                ],
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
          if (index == 2) {
            _showCartModal();
            return;
          }
          if (index == 3) {
            _showProfileModal();
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
    return Container(
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
    );
  }
}
// END OF FILE
import 'package:flutter/material.dart';
import 'auth/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery Web UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF1512F),
          primary: const Color(0xFFF1512F),
          surface: Colors.white,
          background: const Color(0xFFFAFAFA),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        fontFamily: 'Roboto', // Fallback font, assume standard sans-serif
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: CustomAppBar(),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: Color(0xFFEEEEEE)),
                CategoriesRow(),
                Divider(height: 1, color: Color(0xFFEEEEEE)),
                SizedBox(height: 24),
                BannersSection(),
                SizedBox(height: 32),
                TodaysPicksSection(),
                SizedBox(height: 40),
                PopularRightNowSection(),
                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            // Logo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Placeholder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 32),
            // Location
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 18),
                const SizedBox(width: 4),
                const Text(
                  'Dasmariñas, Cavite',
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 18),
              ],
            ),
            const SizedBox(width: 24),
            // Search Bar
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.black54, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search food, restaurants...',
                          hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Profile & Cart
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {},
              color: Colors.black87,
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.white,),
              label: const Text('Cart', style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              icon: const Icon(Icons.login, size: 18, color: Colors.black87),
              label: const Text('Log In', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoriesRow extends StatelessWidget {
  const CategoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Rice Dishes', 'Noodles', 'Soups', 'Grilled', 'Merienda', 'Desserts', 'Drinks'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = cat == 'All';
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BannersSection extends StatelessWidget {
  const BannersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Banner
        Expanded(
          flex: 2,
          child: Container(
            height: 280,
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
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('LOCAL FAVORITES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Authentic Filipino Food\nDelivered to You',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'From Dasmariñas kitchens to your door.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Right Banners
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDFDFD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Made Fresh', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                            SizedBox(height: 4),
                            Text('Every dish cooked to order', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.egg_alt_outlined, color: Colors.orange, size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Easy Ordering', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4),
                            Text('Browse, pick, enjoy', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TodaysPicksSection extends StatelessWidget {
  const TodaysPicksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Adobong Manok', 'subtitle': 'Lutong Bahay ni Ate', 'price': '89', 'rating': '4.9', 'image': 'assets/food1.jpg', 'bestseller': true},
      {'title': 'Sinigang na Baboy', 'subtitle': 'Kainan sa Daan', 'price': '130', 'rating': '4.8', 'image': 'assets/food2.jpg', 'bestseller': true},
      {'title': 'Lechon Kawali', 'subtitle': 'Kuya Lechon', 'price': '145', 'rating': '4.9', 'image': 'assets/food3.jpg', 'bestseller': true},
      {'title': 'Pancit Canton', 'subtitle': 'Mang Kanor', 'price': '80', 'rating': '4.8', 'image': 'assets/food1.jpg', 'bestseller': true},
      {'title': 'Crispy Pata', 'subtitle': 'Kuya Lechon', 'price': '280', 'rating': '4.9', 'image': 'assets/food2.jpg', 'bestseller': true},
      {'title': 'Bulalo', 'subtitle': 'Kainan sa Daan', 'price': '195', 'rating': '4.9', 'image': 'assets/food3.jpg', 'bestseller': true},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Text('Today\'s Picks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: Text('See all →', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            )
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FoodCard(item: item, isSmall: true),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PopularRightNowSection extends StatelessWidget {
  const PopularRightNowSection({super.key});

  @override
  Widget build(BuildContext context) {
     final items = [
      {'title': 'Adobong Manok', 'subtitle': 'Lutong Bahay ni Ate', 'price': '89', 'rating': '4.9', 'sold': '1243', 'image': 'assets/food1.jpg', 'bestseller': true, 'isNew': false},
      {'title': 'Sinigang na Baboy', 'subtitle': 'Kainan sa Daan', 'price': '130', 'rating': '4.8', 'sold': '876', 'image': 'assets/food2.jpg', 'bestseller': true, 'isNew': false},
      {'title': 'Lechon Kawali', 'subtitle': 'Kuya Lechon', 'price': '145', 'rating': '4.9', 'sold': '654', 'image': 'assets/food3.jpg', 'bestseller': true, 'isNew': false},
      {'title': 'Kare-Kare', 'subtitle': 'Lutong Bahay ni Ate', 'price': '160', 'rating': '4.7', 'sold': '432', 'image': 'assets/food1.jpg', 'bestseller': false, 'isNew': false},
      {'title': 'Pancit Canton', 'subtitle': 'Mang Kanor', 'price': '80', 'rating': '4.8', 'sold': '987', 'image': 'assets/food2.jpg', 'bestseller': true, 'isNew': false},
      {'title': 'Bistek Tagalog', 'subtitle': 'Lutong Bahay ni Ate', 'price': '135', 'rating': '4.7', 'sold': '521', 'image': 'assets/food3.jpg', 'bestseller': false, 'isNew': false},
      {'title': 'Crispy Pata', 'subtitle': 'Kuya Lechon', 'price': '280', 'rating': '4.9', 'sold': '312', 'image': 'assets/food1.jpg', 'bestseller': true, 'isNew': false},
      {'title': 'Pinakbet', 'subtitle': 'Mang Kanor', 'price': '95', 'rating': '4.6', 'sold': '389', 'image': 'assets/food2.jpg', 'bestseller': false, 'isNew': false},
      {'title': 'Pork Nilaga', 'subtitle': 'Kainan sa Daan', 'price': '120', 'rating': '4.8', 'sold': '445', 'image': 'assets/food3.jpg', 'bestseller': false, 'isNew': true},
      {'title': 'Pancit Bihon', 'subtitle': 'Mang Kanor', 'price': '75', 'rating': '4.7', 'sold': '678', 'image': 'assets/food1.jpg', 'bestseller': false, 'isNew': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Popular Right Now', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Text('(14)', style: TextStyle(fontSize: 14, color: Colors.black54)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text('Best Match', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 18),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return FoodCard(item: items[index], isSmall: false);
          },
        ),
      ],
    );
  }
}

class FoodCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSmall;

  const FoodCard({super.key, required this.item, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isSmall ? 200 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  item['image'],
                  height: isSmall ? 130 : 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (item['bestseller'] == true)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('BESTSELLER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              if (item['isNew'] == true)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('NEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_border, size: 16, color: Colors.black54),
                ),
              ),
            ],
          ),
          // Details Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['subtitle'],
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['title'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  if (!isSmall && item['sold'] != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(item['rating'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('· ${item['sold']} sold', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₱${item['price']}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                      if (isSmall)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(item['rating'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

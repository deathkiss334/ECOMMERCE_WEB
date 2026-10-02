import 'package:flutter/material.dart';
import 'models/product_model.dart';
import 'services/api_service.dart';

void main() => runApp(const LandingPage());

const orange = Color(0xFFF47721);
const deepOrange = Color(0xFFE85D04);
const ink = Color(0xFF2B211B);
const muted = Color(0xFF786D66);
const cream = Color(0xFFFFF7F0);

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class FoodItem {
  final String name, description, price, image, category;
  const FoodItem(
    this.name,
    this.description,
    this.price,
    this.image,
    this.category,
  );
}

const foods = [
  FoodItem(
    'Chicken Adobo',
    'Classic soy-vinegar braise',
    '₱95',
    'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=700',
    'Ulam',
  ),
  FoodItem(
    'Pork Sinigang',
    'Sour tamarind soup, just like home',
    '₱120',
    'https://images.unsplash.com/photo-1547592180-85f173990554?w=700',
    'Ulam',
  ),
  FoodItem(
    'Pancit Canton',
    'Stir-fried noodles with vegetables',
    '₱85',
    'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=700',
    'Meryenda',
  ),
  FoodItem(
    'Lumpiang Shanghai',
    'Crispy golden pork spring rolls',
    '₱70',
    'https://images.unsplash.com/photo-1544025162-d76694265947?w=700',
    'Silog & Sides',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  List<FoodItem> _foods = foods;
  int _activeSlide = 0;
  int _activeCategory = 0;
  final categories = const [
    'All',
    'Ulam',
    'Silog & Sides',
    'Meryenda',
    'Drinks',
  ];

  final slides = const [
    _Slide(
      'Lutong bahay,\nsa isang click.',
      'Your everyday favorites, freshly prepared and delivered to your door.',
      'assets/landing1.webp',
    ),
    _Slide(
      'Sarap na\nsulit sa budget.',
      'Comfort food and sulit meals made for every kind of day.',
      'assets/landing2.webp',
    ),
    _Slide(
      'May ulam na.\nKain na tayo!',
      'Discover today’s home-cooked specials from your neighborhood kitchen.',
      'assets/landing3.webp',
    ),
    _Slide(
      'Mainit at\nbagong luto.',
      'Freshly prepared Filipino dishes ready for lunch and dinner.',
      'assets/landing4.webp',
    ),
    _Slide(
      'Pamilyang busog,\nsayang walang kapantay.',
      'Bring home authentic Filipino flavors that everyone will love.',
      'assets/landing5.webp',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.getProducts();
      if (!mounted || products.isEmpty) return;

      setState(() {
        _foods = products.map(_toFoodItem).toList();
      });
    } catch (_) {
      // Keep the bundled catalog available when the API is offline.
    }
  }

  FoodItem _toFoodItem(Product product) {
    final category = product.slug.contains('beverage') || product.slug.contains('drink')
        ? 'Drinks'
        : product.slug.contains('snack')
        ? 'Meryenda'
        : 'Ulam';

    return FoodItem(
      product.name,
      product.description,
      '₱${product.basePrice.toStringAsFixed(0)}',
      product.image.isNotEmpty ? product.image : 'assets/assets1.jpg',
      category,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final visibleFoods = _activeCategory == 0
      ? _foods
      : _foods
              .where((f) => f.category == categories[_activeCategory])
              .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(compact)),
            SliverToBoxAdapter(child: _hero(compact)),
            SliverToBoxAdapter(child: _benefits(compact)),
            SliverToBoxAdapter(
              child: _sectionHeading(
                'Mga paborito ng kapitbahay',
                'Freshly cooked, always satisfying.',
                compact,
              ),
            ),
            SliverToBoxAdapter(child: _categoryBar(compact)),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 56,
                vertical: 12,
              ),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final cols = width > 1050
                      ? 4
                      : width > 700
                      ? 3
                      : width > 450
                      ? 2
                      : 1;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _foodCard(visibleFoods[index], compact),
                      childCount: visibleFoods.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: cols == 1 ? 1.4 : 0.82,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: _promo(compact)),
            SliverToBoxAdapter(child: _footer(compact)),
          ],
        ),
      ),
    );
  }

  Widget _header(bool compact) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56, vertical: 18),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: orange,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Vanessa\'s Carinderia',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w900,
            color: ink,
            letterSpacing: -1,
          ),
        ),
        const Spacer(),
        if (!compact) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/shop');
              },
              child: const Text(
                'Home',
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          _navText('Menu'),
          _navText('About us'),
          const SizedBox(width: 22),
        ],
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Log in'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: Color(0xFFEADFD6)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    ),
  );

  Widget _navText(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _hero(bool compact) => Padding(
    padding: EdgeInsets.fromLTRB(compact ? 12 : 44, 8, compact ? 12 : 44, 10),
    child: Column(
      children: [
        SizedBox(
          height: compact ? 320 : 350,
          child: PageView.builder(
            controller: _pageController,
            itemCount: slides.length,
            onPageChanged: (i) => setState(() => _activeSlide = i),
            itemBuilder: (context, i) {
              final slide = slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        slide.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Container(color: const Color(0xFFFFD9B8)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(.72),
                              Colors.black.withOpacity(.30),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 20 : 56,
                          compact ? 20 : 40,
                          compact ? 70 : 120,
                          compact ? 20 : 40,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 510),
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: orange,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Text(
                                      'SARAP NA LUTONG BAHAY',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 10 : 18),
                                  Text(
                                    slide.title.replaceAll('\\n', '\n'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 28 : 52,
                                      height: 1.08,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.2,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 8 : 14),
                                  Text(
                                    slide.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(.9),
                                      fontSize: compact ? 13 : 16,
                                      height: 1.4,
                                    ),
                                  ),
                                  SizedBox(height: compact ? 16 : 24),
                                  FilledButton(
                                    onPressed: () => Scrollable.ensureVisible(
                                      context,
                                      duration: const Duration(milliseconds: 400),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: orange,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 18 : 23,
                                        vertical: compact ? 12 : 16,
                                      ),
                                    ),
                                    child: const Text(
                                      'Order now  →',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: compact ? 16 : 28,
                        bottom: compact ? 16 : 28,
                        child: _singleNavControl(compact),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (i) => GestureDetector(
              onTap: () => _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _activeSlide == i ? 27 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _activeSlide == i ? orange : const Color(0xFFE8D6C8),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _singleNavControl(bool compact) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                if (_pageController.hasClients) {
                  if (_activeSlide > 0) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  } else {
                    _pageController.animateToPage(
                      slides.length - 1,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  }
                }
              },
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Previous',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${_activeSlide + 1} / ${slides.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (_pageController.hasClients) {
                  if (_activeSlide < slides.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  } else {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                    );
                  }
                }
              },
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 22,
              ),
              tooltip: 'Next',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefits(bool compact) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56, vertical: 22),
    child: Wrap(
      alignment: WrapAlignment.spaceAround,
      runSpacing: 14,
      spacing: 16,
      children: const [
        _Benefit(
          Icons.soup_kitchen_outlined,
          'Freshly cooked',
          'Made with care every day',
        ),
        _Benefit(
          Icons.delivery_dining_outlined,
          'Quick delivery',
          'Good food, right at your door',
        ),
        _Benefit(
          Icons.payments_outlined,
          'Presyong sulit',
          'Everyday meals, fair prices',
        ),
      ],
    ),
  );

  Widget _sectionHeading(String title, String subtitle, bool compact) =>
      Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 56,
          16,
          compact ? 20 : 56,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 20 : 26,
                fontWeight: FontWeight.w900,
                color: ink,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: muted, fontSize: 13)),
          ],
        ),
      );

  Widget _categoryBar(bool compact) => SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56),
      children: List.generate(
        categories.length,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 7),
          child: ChoiceChip(
            label: Text(categories[i]),
            selected: _activeCategory == i,
            onSelected: (_) => setState(() => _activeCategory = i),
            selectedColor: orange,
            backgroundColor: cream,
            labelStyle: TextStyle(
              color: _activeCategory == i ? Colors.white : ink,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            side: BorderSide.none,
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ),
    ),
  );

  Widget _foodCard(FoodItem food, bool compact) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0E7E0)),
      boxShadow: [
        BoxShadow(
          color: ink.withOpacity(.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 55,
          child: Image.network(
            food.image,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: cream,
              child: const Icon(Icons.restaurant, color: orange, size: 32),
            ),
          ),
        ),
        Expanded(
          flex: 45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      food.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      food.price,
                      style: const TextStyle(
                        color: deepOrange,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton.filled(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
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
  );

  Widget _promo(bool compact) => Padding(
    padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 30, compact ? 20 : 56, 36),
    child: Container(
      padding: EdgeInsets.all(compact ? 20 : 32),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'May cravings ka?',
                  style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your next comfort meal is just a few taps away.',
                  style: TextStyle(
                    color: ink,
                    fontSize: compact ? 18 : 24,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Explore the menu', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          if (!compact) const SizedBox(width: 20),
          if (!compact)
            const Icon(
              Icons.ramen_dining_rounded,
              color: Color(0xFFFFC28D),
              size: 80,
            ),
        ],
      ),
    ),
  );

  Widget _footer(bool compact) => Container(
    color: ink,
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56, vertical: 20),
    child: Row(
      children: [
        const Text(
          'Vanessa\'s Carinderia',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        const Flexible(
          child: Text(
            'Lutong bahay, delivered with love.  © 2026 Vanessa\'s Carinderia',
            textAlign: TextAlign.right,
            style: TextStyle(color: Color(0xFFD9CEC6), fontSize: 11),
          ),
        ),
      ],
    ),
  );
}

class _Slide {
  final String title, subtitle, image;
  const _Slide(this.title, this.subtitle, this.image);
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _Benefit(this.icon, this.title, this.subtitle);
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: orange, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: ink, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

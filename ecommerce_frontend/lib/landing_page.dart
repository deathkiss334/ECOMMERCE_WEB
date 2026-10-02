import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

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
  // 1. Monggo - ₱20
  FoodItem(
    'Ginisang Monggo',
    'Comforting sautéed mung bean stew with spinach, garlic, and savory chicharon',
    '₱20',
    'assets/dish_monggo.webp',
    'Gulay & Sabaw',
  ),
  // 2. Beef Steak - ₱60
  FoodItem(
    'Bistek Tagalog (Beef Steak)',
    'Tender beef slices simmered in savory soy sauce, calamansi, and sweet onions',
    '₱60',
    'assets/dish_beef_steak.webp',
    'Ulam',
  ),
  // 3. Giniling - ₱60
  FoodItem(
    'Pork Giniling',
    'Savory minced pork with potatoes, carrots, and sweet green peas in tomato sauce',
    '₱60',
    'assets/dish_giniling.webp',
    'Ulam',
  ),
  // 4. Lumpia - ₱10/pc
  FoodItem(
    'Lumpiang Shanghai',
    'Crispy golden pork spring rolls served with sweet & sour dipping sauce',
    '₱10/pc',
    'assets/dish_lumpia.webp',
    'Sides',
  ),
  // 5. Sopas - ₱20
  FoodItem(
    'Creamy Chicken Sopas',
    'Heartwarming macaroni soup with shredded chicken in rich evaporated milk broth',
    '₱20',
    'assets/dish_sopas.webp',
    'Gulay & Sabaw',
  ),
  // 6. Spaghetti - ₱20
  FoodItem(
    'Pinoy Sweet Spaghetti',
    'Classic sweet-style party spaghetti topped with sliced hotdogs and grated cheese',
    '₱20',
    'assets/dish_spaghetti.webp',
    'Meryenda & Desserts',
  ),
  // 7. Dinakdakan - ₱120
  FoodItem(
    'Authentic Dinakdakan',
    'Char-grilled pork tossed with calamansi, ginger, red onions, and rich creamy dressing',
    '₱120',
    'assets/dish_dinakdakan.webp',
    'Ulam',
  ),
  // 8. Pakbet - ₱40
  FoodItem(
    'Pinakbet (Pakbet)',
    'Traditional mixed veggies: squash, eggplant, okra, and sitaw sautéed in bagoong',
    '₱40',
    'assets/dish_pakbet.webp',
    'Gulay & Sabaw',
  ),
  // 9. Dinuguan - ₱60
  FoodItem(
    'Special Dinuguan',
    'Hearty and savory pork blood stew with vinegar, garlic, and sili haba',
    '₱60',
    'assets/dish_dinuguan.webp',
    'Ulam',
  ),
  // 10. Pansit - ₱20
  FoodItem(
    'Pansit Guisado',
    'Stir-fried noodles with crisp vegetables, pork bits, and savory seasonings',
    '₱20',
    'assets/dish_pansit.webp',
    'Meryenda & Desserts',
  ),
  // 11. Curry - ₱60
  FoodItem(
    'Pinoy Chicken Curry',
    'Fragrant Filipino-style curry with tender chicken, potatoes, and bell peppers',
    '₱60',
    'assets/dish_curry.webp',
    'Ulam',
  ),
  // 12. Ginataan Bilo-Bilo - ₱150
  FoodItem(
    'Ginataang Bilo-Bilo',
    'Warm sweet coconut stew with chewy glutinous rice balls, sago, and langka',
    '₱150',
    'assets/dish_ginataan_bilobilo.webp',
    'Meryenda & Desserts',
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _menuSectionKey = GlobalKey();
  final GlobalKey _aboutSectionKey = GlobalKey();

  Timer? _autoSlideTimer;
  bool _isHoveringHero = false;

  final List<FoodItem> _foods = foods;
  int _activeSlide = 0;
  int _activeCategory = 0;
  final categories = const [
    'All',
    'Ulam',
    'Gulay & Sabaw',
    'Meryenda & Desserts',
    'Sides',
  ];

  final slides = const [
    _Slide(
      'Lutong bahay,\nsa isang click.',
      'Your everyday Filipino favorites, freshly cooked and delivered warm to your doorstep.',
      'assets/hero_carinderia_feast.webp',
    ),
    _Slide(
      'Sarap na\nsulit sa budget.',
      'Generous servings and hearty comfort meals made for the whole family.',
      'assets/hero_family_dining.webp',
    ),
    _Slide(
      'Mainit at\nbagong luto.',
      'Sizzling specials and traditional ulam prepared fresh from our kitchen daily.',
      'assets/hero_sizzling_sisig.webp',
    ),
    _Slide(
      'Pamilyang busog,\nsayang walang kapantay.',
      'Authentic home-cooked flavors delivered fast anywhere in Dasmariñas.',
      'assets/hero_delivery.webp',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients || _isHoveringHero) return;
      final nextSlide = (_activeSlide + 1) % slides.length;
      _pageController.animateToPage(
        nextSlide,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _scrollToMenu() {
    final ctx = _menuSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollToAbout() {
    final ctx = _aboutSectionKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
    final isWideFooter = width >= 980;
    final visibleFoods = _activeCategory == 0
        ? _foods
        : _foods
              .where((f) => f.category == categories[_activeCategory])
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(child: _header(compact)),
            SliverToBoxAdapter(child: _hero(compact)),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _aboutSectionKey,
                child: _benefits(compact),
              ),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _menuSectionKey,
                child: _sectionHeading(
                  'Mga paborito ng kapitbahay',
                  'Freshly cooked lutong bahay dishes, always hot and satisfying.',
                  compact,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _categoryBar(compact)),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 56,
                vertical: 16,
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
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: cols == 1 ? 1.45 : 0.84,
                    ),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: _promo(compact)),
            SliverToBoxAdapter(child: _footer(compact, isWideFooter)),
          ],
        ),
      ),
    );
  }

  Widget _header(bool compact) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56, vertical: 18),
    child: Row(
      children: [
        Flexible(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _scrollToTop,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: orange,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: orange.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Vanessa\'s Carinderia',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: compact ? 19 : 23,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        if (!compact) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextButton(
              onPressed: _scrollToAbout,
              child: const Text(
                'About us',
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/shop'),
              child: const Text(
                'Order Online',
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Log in'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: const BorderSide(color: Color(0xFFDED0C5), width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero(bool compact) => Padding(
    padding: EdgeInsets.fromLTRB(compact ? 14 : 50, 6, compact ? 14 : 50, 12),
    child: Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHoveringHero = true),
          onExit: (_) => setState(() => _isHoveringHero = false),
          child: SizedBox(
            height: compact ? 330 : 380,
            child: Stack(
              children: [
                ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    dragDevices: {
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.touch,
                      PointerDeviceKind.stylus,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: slides.length,
                    onPageChanged: (i) => setState(() => _activeSlide = i),
                    itemBuilder: (context, i) {
                      final slide = slides[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                slide.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    Container(color: const Color(0xFFFFE0C2)),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.78),
                                      Colors.black.withValues(alpha: 0.40),
                                      Colors.black.withValues(alpha: 0.05),
                                    ],
                                    stops: const [0.0, 0.55, 1.0],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  compact ? 24 : 56,
                                  compact ? 24 : 44,
                                  compact ? 24 : 120,
                                  compact ? 24 : 44,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 520,
                                    ),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 13,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: orange,
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: orange.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Text(
                                              'SARAP NA LUTONG BAHAY',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: compact ? 12 : 18),
                                          Text(
                                            slide.title.replaceAll('\\n', '\n'),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: compact ? 30 : 48,
                                              height: 1.1,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -1.2,
                                              shadows: const [
                                                Shadow(
                                                  color: Colors.black45,
                                                  blurRadius: 10,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: compact ? 10 : 14),
                                          Text(
                                            slide.subtitle,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.92,
                                              ),
                                              fontSize: compact ? 13 : 16,
                                              height: 1.45,
                                            ),
                                          ),
                                          SizedBox(height: compact ? 18 : 26),
                                          FilledButton.icon(
                                            onPressed: _scrollToMenu,
                                            icon: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                            label: const Text(
                                              'Order now',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: orange,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: compact ? 22 : 28,
                                                vertical: compact ? 14 : 18,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              elevation: 4,
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
                        ),
                      );
                    },
                  ),
                ),

                if (!compact) ...[
                  Positioned(
                    left: 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _carouselChevron(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Previous slide',
                        onTap: () {
                          final prev =
                              (_activeSlide - 1 + slides.length) %
                              slides.length;
                          _pageController.animateToPage(
                            prev,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _carouselChevron(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Next slide',
                        onTap: () {
                          final next = (_activeSlide + 1) % slides.length;
                          _pageController.animateToPage(
                            next,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            slides.length,
            (i) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: _activeSlide == i ? 28 : 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _activeSlide == i
                          ? orange
                          : const Color(0xFFDCCBC0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _carouselChevron({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _isHoveringHero ? 0.95 : 0.4,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefits(bool compact) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56, vertical: 24),
    child: Wrap(
      alignment: WrapAlignment.spaceAround,
      runSpacing: 18,
      spacing: 20,
      children: const [
        _Benefit(
          Icons.soup_kitchen_rounded,
          'Lutong Bahay Araw-Araw',
          'Freshly prepared with home-style love',
        ),
        _Benefit(
          Icons.delivery_dining_rounded,
          'Mabilis na Delivery',
          'Hot and warm meals at your doorstep',
        ),
        _Benefit(
          Icons.savings_rounded,
          'Sulit sa Presyo',
          'Generous servings, abot-kayang halaga',
        ),
      ],
    ),
  );

  Widget _sectionHeading(String title, String subtitle, bool compact) =>
      Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 56,
          24,
          compact ? 20 : 56,
          10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 22 : 28,
                fontWeight: FontWeight.w900,
                color: ink,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                color: muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _categoryBar(bool compact) => SizedBox(
    height: 46,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 56),
      children: List.generate(
        categories.length,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(categories[i]),
            selected: _activeCategory == i,
            onSelected: (_) => setState(() => _activeCategory = i),
            selectedColor: orange,
            backgroundColor: cream,
            labelStyle: TextStyle(
              color: _activeCategory == i ? Colors.white : ink,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            side: BorderSide(
              color: _activeCategory == i ? orange : const Color(0xFFEADBCE),
              width: 1,
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _foodCard(FoodItem food, bool compact) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: InkWell(
      onTap: () => Navigator.pushNamed(context, '/shop'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFE6DF), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: ink.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  food.image.startsWith('http')
                      ? Image.network(
                          food.image,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: cream,
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: orange,
                              size: 34,
                            ),
                          ),
                        )
                      : Image.asset(
                          food.image,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: cream,
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: orange,
                              size: 34,
                            ),
                          ),
                        ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        food.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          food.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          food.price,
                          style: const TextStyle(
                            color: deepOrange,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: orange.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Order Now',
                            style: TextStyle(
                              color: deepOrange,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
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
    ),
  );

  Widget _promo(bool compact) => Padding(
    padding: EdgeInsets.fromLTRB(compact ? 20 : 56, 32, compact ? 20 : 56, 40),
    child: Container(
      padding: EdgeInsets.all(compact ? 24 : 36),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0DFCE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'GUTOM KA NA BA?',
                    style: TextStyle(
                      color: deepOrange,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your next favorite comfort meal is just a few taps away.',
                  style: TextStyle(
                    color: ink,
                    fontSize: compact ? 20 : 26,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Freshly cooked dishes prepared daily. Order directly online for fast delivery or store pickup.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/shop'),
                  icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                  label: const Text(
                    'Explore the full menu',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 32),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: orange.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.outdoor_grill_rounded,
                color: orange,
                size: 64,
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _footer(bool compact, bool isWide) => Container(
    color: ink,
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 20 : (isWide ? 56 : 28),
      vertical: compact ? 32 : 44,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isWide) ...[
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Vanessa's Carinderia",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Ang paboritong lutong bahay sa kapitbahayan. Fresh, mainit, at masarap na putahe araw-araw.',
            style: TextStyle(color: Color(0xFFD0C3B8), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          _footerInfoBlock(
            Icons.access_time_rounded,
            'Serving Hours',
            '8:00 AM – 8:00 PM Daily (Lunch ready by 10:30 AM)',
          ),
          const SizedBox(height: 10),
          _footerInfoBlock(
            Icons.location_on_rounded,
            'Location & Area',
            "Governor's Drive, Dasmariñas, Cavite • Dine-in & Delivery",
          ),
          const SizedBox(height: 16),
          _paymentBadges(),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Vanessa's Carinderia",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Ang paboritong lutong bahay sa kapitbahayan.\nFresh, mainit, at masarap na putahe araw-araw para sa buong pamilya.",
                      style: TextStyle(
                        color: Color(0xFFD0C3B8),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 36),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _footerInfoBlock(
                      Icons.access_time_rounded,
                      'Operating Hours',
                      "8:00 AM – 8:00 PM Daily\nLunch specials hot by 10:30 AM",
                    ),
                    const SizedBox(height: 14),
                    _footerInfoBlock(
                      Icons.location_on_rounded,
                      'Location & Service',
                      "Dasmariñas, Cavite\nDine-in, Takeout & Express Delivery",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accepted Payments',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _paymentBadges(),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/shop'),
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: orange,
                      ),
                      label: const Text(
                        'Start ordering now →',
                        style: TextStyle(
                          color: orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        const Divider(color: Color(0xFF453A34), height: 36),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: const [
            Text(
              "© 2026 Vanessa's Carinderia. All rights reserved.",
              style: TextStyle(color: Color(0xFFAFA39A), fontSize: 12),
            ),
            Text(
              'Lutong bahay na abot-kaya.',
              style: TextStyle(color: Color(0xFFAFA39A), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _footerInfoBlock(IconData icon, String title, String body) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: orange, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              style: const TextStyle(
                color: Color(0xFFD0C3B8),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _paymentBadges() => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF007DFE).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF007DFE).withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_rounded, color: Color(0xFF3897FF), size: 14),
            SizedBox(width: 5),
            Text(
              'GCash QR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.4),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_rounded, color: Color(0xFF4ADE80), size: 14),
            SizedBox(width: 5),
            Text(
              'Cash on Delivery',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
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
    width: 220,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1E3D7), width: 1),
          ),
          child: Icon(icon, color: orange, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 11, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

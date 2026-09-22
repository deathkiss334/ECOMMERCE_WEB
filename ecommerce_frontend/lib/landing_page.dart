import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const Color brandOrange = Color(0xFFF36F21);
  static const Color darkText = Color(0xFF1E1E1E);
  static const Color lightBg = Color(0xFFFFF8F0);

  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Navigation Bar
            _buildNavbar(context, isMobile),

            // Main Content Area (Full Horizontal Width)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : (isTablet ? 24.0 : 32.0),
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2x3 Grid of Pure Photo Collage Cards (Full Horizontal Width)
                  _buildPhotoGrid(isMobile, isTablet),

                  const SizedBox(height: 24),

                  // DasmaBITES Hero Banner Section (Full Horizontal Width)
                  _buildBottomHeroSection(context, isMobile, isTablet),
                ],
              ),
            ),

            // Web Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  /// Navigation Header Bar (Full Horizontal Width)
  Widget _buildNavbar(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo & Brand Name
            GestureDetector(
              onTap: () {
                // Already on home
              },
              child: Row(
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Dasma',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: darkText,
                            fontFamily: 'Roboto',
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'BITES',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: brandOrange,
                            fontFamily: 'Roboto',
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: brandOrange,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Desktop Links & Navigation
            if (!isMobile)
              Row(
                children: [
                  _navLink('Home', active: true, onTap: () {}),
                  const SizedBox(width: 24),
                  _navLink('Browse Menu', onTap: () {
                    Navigator.pushNamed(context, '/shop');
                  }),
                  const SizedBox(width: 24),
                  _navLink('Admin Portal', onTap: () {
                    Navigator.pushNamed(context, '/admin');
                  }),
                ],
              ),

            // Right Action Buttons
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: darkText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/shop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLink(String label, {bool active = false, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: active ? FontWeight.bold : FontWeight.w600,
            color: active ? brandOrange : Colors.black.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  /// 2x3 Grid of Pure Photo Collage Cards (Takes full horizontal space)
  Widget _buildPhotoGrid(bool isMobile, bool isTablet) {
    final images = [
      'assets/landing1.jpg',
      'assets/landing2.jpg',
      'assets/landing3.jpg',
      'assets/landing4.jpg',
      'assets/landing5.jpg',
      'assets/landing6.jpg',
    ];

    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);
    double childAspectRatio = isMobile ? 1.4 : (isTablet ? 1.7 : 2.2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: images.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          return _buildGridTile(images[index], index);
        },
      ),
    );
  }

  Widget _buildGridTile(String imagePath, int index) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: isHovered
            ? Matrix4.diagonal3Values(1.01, 1.01, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: Center(
                  child: Icon(Icons.image, size: 48, color: Colors.grey.shade500),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// DasmaBITES Hero Banner Section (Takes full horizontal space)
  Widget _buildBottomHeroSection(BuildContext context, bool isMobile, bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2E6D8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Top-Left Corner Wave Accent
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: brandOrange,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(120),
                  ),
                ),
              ),
            ),

            // Bottom-Right Corner Wave Accent
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: brandOrange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(120),
                  ),
                ),
              ),
            ),

            // Main Hero Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 48,
                vertical: isMobile ? 28 : 40,
              ),
              child: Column(
                children: [
                  // Top Row (Center Logo & Right Tagline)
                  if (isMobile)
                    Column(
                      children: [
                        _buildCenterLogoAndCTA(context, isMobile),
                        const SizedBox(height: 24),
                        _buildRightTagline(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(flex: 1, child: SizedBox()),
                        Expanded(
                          flex: 5,
                          child: _buildCenterLogoAndCTA(context, isMobile),
                        ),
                        Expanded(
                          flex: 4,
                          child: _buildRightTagline(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 36),
                  const Divider(color: Color(0xFFE6DBCF), thickness: 1),
                  const SizedBox(height: 24),

                  // Bottom 4 Feature Bullet Points Bar
                  _buildFeaturesBar(isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterLogoAndCTA(BuildContext context, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Brand Title with Cart Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Dasma',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: darkText,
                      fontFamily: 'Roboto',
                      letterSpacing: -1,
                    ),
                  ),
                  TextSpan(
                    text: 'BITES',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      color: brandOrange,
                      fontFamily: 'Roboto',
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: brandOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Subtitle
        const Text(
          'Your Favorite Bites, Just a Click Away!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 20),

        // Prominent CTA Button "Shop Now"
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/shop'),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Shop Now',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightTagline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '\\',
              style: TextStyle(
                color: brandOrange,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'DasmaBITES',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 12.0),
          child: Text(
            '— Because Good Food\n    Brings People Together',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: Color(0xFF333333),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesBar(bool isMobile) {
    final features = [
      {'icon': Icons.local_shipping_outlined, 'title': 'Fast Delivery'},
      {'icon': Icons.verified_user_outlined, 'title': 'Secure Payment'},
      {'icon': Icons.favorite_border, 'title': 'Great Deals'},
      {'icon': Icons.sentiment_satisfied_alt, 'title': 'Happy Customers'},
    ];

    if (isMobile) {
      return Wrap(
        alignment: WrapAlignment.spaceAround,
        runSpacing: 16,
        spacing: 16,
        children: features
            .map((f) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f['icon'] as IconData, size: 20, color: darkText),
                    const SizedBox(width: 6),
                    Text(
                      f['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: darkText,
                      ),
                    ),
                  ],
                ))
            .toList(),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.asMap().entries.map((entry) {
        final idx = entry.key;
        final f = entry.value;

        return Row(
          children: [
            Icon(f['icon'] as IconData, size: 20, color: darkText),
            const SizedBox(width: 8),
            Text(
              f['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: darkText,
              ),
            ),
            if (idx < features.length - 1) ...[
              const SizedBox(width: 32),
              Container(
                height: 20,
                width: 1,
                color: const Color(0xFFDCD2C4),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }

  /// Web Footer (Pinned to absolute bottom edge of full screen view)
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      child: Center(
        child: Text(
          '© ${DateTime.now().year} DasmaBITES — Your Favorite Bites, Just a Click Away! All rights reserved.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

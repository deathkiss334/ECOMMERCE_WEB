import 'package:flutter/material.dart';
import '../../models/food_item.dart';

class CartBottomSheet extends StatelessWidget {
  final List<CartItem> cart;
  final int cartTotal;
  final int cartCount;
  final Function(int id) onRemove;
  final VoidCallback onCheckout;

  const CartBottomSheet({
    super.key,
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

import 'package:flutter/material.dart';
import '../../models/food_item.dart';

class ItemDetailBottomSheet extends StatefulWidget {
  final FoodItem item;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final Function(int qty) onAddToCart;

  const ItemDetailBottomSheet({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onToggleSave,
    required this.onAddToCart,
  });

  @override
  State<ItemDetailBottomSheet> createState() => _ItemDetailBottomSheetState();
}

class _ItemDetailBottomSheetState extends State<ItemDetailBottomSheet> {
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

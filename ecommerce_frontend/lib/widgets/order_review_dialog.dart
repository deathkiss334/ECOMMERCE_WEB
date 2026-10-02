import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OrderReviewDialog extends StatefulWidget {
  final String orderNumber;
  final VoidCallback? onReviewSubmitted;

  const OrderReviewDialog({
    super.key,
    required this.orderNumber,
    this.onReviewSubmitted,
  });

  @override
  State<OrderReviewDialog> createState() => _OrderReviewDialogState();
}

class _OrderReviewDialogState extends State<OrderReviewDialog> {
  int _selectedRating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingReview;

  static const Color brandOrange = Color(0xFFF36F21);

  final List<String> _ratingLabels = [
    '',
    '😞 Disappointed',
    '😕 Needs Improvement',
    '😐 Okay / Average',
    '😊 Very Good',
    '🌟 Outstanding & Delicious! 🎉',
  ];

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingReview() async {
    try {
      final review = await ApiService.getOrderReview(widget.orderNumber);
      if (mounted) {
        setState(() {
          _existingReview = review;
          if (review != null) {
            _selectedRating = int.tryParse(review['rating']?.toString() ?? '5') ?? 5;
            _feedbackController.text = review['feedback'] ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final success = await ApiService.submitOrderReview(
      orderId: widget.orderNumber,
      rating: _selectedRating,
      feedback: _feedbackController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        widget.onReviewSubmitted?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Thank you for your rating and feedback!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit review. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasExisting = _existingReview != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: brandOrange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, size: 36, color: brandOrange),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      hasExisting ? 'Your Order Review' : 'Rate Your Experience',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order #${widget.orderNumber}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    // Star Rating Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        return GestureDetector(
                          onTap: hasExisting ? null : () => setState(() => _selectedRating = starIndex),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              starIndex <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                              size: 38,
                              color: starIndex <= _selectedRating ? const Color(0xFFFBBF24) : Colors.grey[350],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Rating description text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _ratingLabels[_selectedRating.clamp(1, 5)],
                        key: ValueKey<int>(_selectedRating),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Feedback comments TextField
                    TextField(
                      controller: _feedbackController,
                      enabled: !hasExisting,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: hasExisting
                            ? 'No additional feedback provided.'
                            : 'Share what you enjoyed or any suggestions for next time (optional)...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        filled: true,
                        fillColor: hasExisting ? Colors.grey[50] : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: brandOrange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              hasExisting ? 'Close' : 'Cancel',
                              style: const TextStyle(color: Color(0xFF4B5563)),
                            ),
                          ),
                        ),
                        if (!hasExisting) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandOrange,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isSubmitting ? null : _submitReview,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Submit Review',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

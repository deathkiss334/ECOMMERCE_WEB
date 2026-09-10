import 'package:flutter/material.dart';
import '../services/checkout_service.dart';

class QrPaymentModal extends StatefulWidget {
  final String orderNumber;
  final double totalAmount;
  final String qrImageUrl;
  final VoidCallback onPaymentComplete;

  const QrPaymentModal({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.qrImageUrl,
    required this.onPaymentComplete,
  });

  static const Color brandColor = Color(0xFFE8411E);

  @override
  State<QrPaymentModal> createState() => _QrPaymentModalState();
}

class _QrPaymentModalState extends State<QrPaymentModal> {
  bool _isProcessing = false;
  final TextEditingController _refController = TextEditingController();

  Future<void> _handleConfirmPayment() async {
    setState(() => _isProcessing = true);
    try {
      await CheckoutService.confirmQrPayment(
        orderNumber: widget.orderNumber,
        referenceNumber: _refController.text.trim().isNotEmpty
            ? _refController.text.trim()
            : 'QR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onPaymentComplete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Confirmed! Order ${widget.orderNumber} is now preparing 🍳'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to confirm payment: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.qr_code_scanner, color: QrPaymentModal.brandColor, size: 26),
                    SizedBox(width: 8),
                    Text(
                      'Scan to Pay',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Order Number & Amount Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Number', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      Text(widget.orderNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                      Text('₱${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: QrPaymentModal.brandColor)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.network(
                widget.qrImageUrl,
                width: 190,
                height: 190,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    width: 190,
                    height: 190,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (ctx, error, stack) => const SizedBox(
                  width: 190,
                  height: 190,
                  child: Center(child: Icon(Icons.qr_code, size: 80, color: Color(0xFF9CA3AF))),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Supported E-Wallets Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildBadge('GCash', const Color(0xFF005CE6)),
                const SizedBox(width: 8),
                _buildBadge('Maya', const Color(0xFF009944)),
                const SizedBox(width: 8),
                _buildBadge('InstaPay / Bank', const Color(0xFF6B7280)),
              ],
            ),
            const SizedBox(height: 16),

            // Simulated Confirmation Action
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _handleConfirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'I Have Paid (Confirm Order)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/checkout_service.dart';
import 'order_chat_dialog.dart';

class QrPaymentModal extends StatefulWidget {
  final String orderNumber;
  final double totalAmount;
  final String qrImageUrl;
  final String? orderType;
  final double? subtotal;
  final double? deliveryFee;
  final VoidCallback onPaymentComplete;

  const QrPaymentModal({
    super.key,
    required this.orderNumber,
    required this.totalAmount,
    required this.qrImageUrl,
    this.orderType,
    this.subtotal,
    this.deliveryFee,
    required this.onPaymentComplete,
  });

  static const Color brandColor = Color(0xFF005CE6); // GCash Blue

  @override
  State<QrPaymentModal> createState() => _QrPaymentModalState();
}

class _QrPaymentModalState extends State<QrPaymentModal> {
  Timer? _pollingTimer;
  bool _isPaid = false;
  bool _isAwaitingVerification = false;
  bool _isUploading = false;
  String? _rejectionReason;
  String _statusText = 'Awaiting payment submission...';

  final TextEditingController _refController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _receiptBytes;
  String? _receiptFileName;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _refController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (_isPaid) return;
      try {
        final data = await CheckoutService.checkOrderStatus(orderNumber: widget.orderNumber);
        final paymentStatus = (data['payment_status'] ?? '').toString().toLowerCase();
        final orderStatus = (data['status'] ?? '').toString().toLowerCase();
        final notes = (data['admin_notes'] ?? data['adminNotes'] ?? '').toString();

        if (paymentStatus == 'paid' || orderStatus == 'paid' || orderStatus == 'preparing') {
          _onPaymentSucceeded();
        } else if (orderStatus == 'awaiting_verification' || paymentStatus == 'awaiting_verification') {
          if (!_isAwaitingVerification && mounted) {
            setState(() {
              _isAwaitingVerification = true;
              _rejectionReason = null;
              _statusText = 'Verifying Payment with Store...';
            });
          }
        } else if (orderStatus == 'rejected' || paymentStatus == 'rejected') {
          if (mounted) {
            setState(() {
              _isAwaitingVerification = false;
              _rejectionReason = notes.isNotEmpty ? notes : 'Receipt screenshot was rejected by the admin.';
              _statusText = 'Payment verification rejected. Please re-upload valid proof.';
            });
          }
        }
      } catch (_) {
        // Polling retry silently
      }
    });
  }

  void _onPaymentSucceeded() {
    if (_isPaid) return;
    _pollingTimer?.cancel();
    setState(() {
      _isPaid = true;
      _isAwaitingVerification = false;
      _statusText = 'Payment Received! Order is now cooking in the kitchen 🍳';
    });

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onPaymentComplete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Confirmed! Order #${widget.orderNumber} is now preparing 🍳'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  Future<void> _pickReceipt() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        if (bytes.lengthInBytes > 5 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receipt image must be smaller than 5MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _receiptBytes = bytes;
          _receiptFileName = file.name;
          _rejectionReason = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not attach image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSubmitReceipt() async {
    if (_receiptBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach your GCash transaction screenshot first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final res = await CheckoutService.uploadReceipt(
        orderNumber: widget.orderNumber,
        imageBytes: _receiptBytes!,
        fileName: _receiptFileName ?? 'receipt.png',
        gcashRefNumber: _refController.text.trim(),
      );

      if (res['success'] == true) {
        setState(() {
          _isAwaitingVerification = true;
          _rejectionReason = null;
          _statusText = 'Verifying Payment with Store...';
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt uploaded! Store admin is verifying your payment.'),
            backgroundColor: Color(0xFF005CE6),
          ),
        );
      } else {
        throw Exception(res['message'] ?? 'Upload failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _copyOrderNumber() {
    Clipboard.setData(ClipboardData(text: widget.orderNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ID ${widget.orderNumber} copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openQrExternal() async {
    final rawUrl = widget.qrImageUrl.isNotEmpty
        ? widget.qrImageUrl
        : 'http://127.0.0.1:8000/assets/gcash_qr.png';
    final uri = Uri.parse(rawUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback
    }
  }

  void _showFullResolutionQr(BuildContext context) {
    final rawUrl = widget.qrImageUrl.isNotEmpty
        ? widget.qrImageUrl
        : 'http://127.0.0.1:8000/assets/gcash_qr.png';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.qr_code, color: Color(0xFF005CE6)),
                      SizedBox(width: 8),
                      Text(
                        'GCash QR Code (Full Size)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      rawUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (c1, e1, s1) => Image.asset(
                        'assets/gcash_qr.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c2, e2, s2) => Image.network('/assets/gcash_qr.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openQrExternal,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Open / Save Full QR Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005CE6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF005CE6).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Color(0xFF005CE6), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'GCash Manual Payment',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                          Text(
                            'Scan, pay, & upload receipt for verification',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      _pollingTimer?.cancel();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Rejection Alert Banner (if applicable)
              if (_rejectionReason != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF87171)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Verification Rejected',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _rejectionReason!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Please re-upload a clear screenshot of your GCash receipt below.',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7F1D1D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Breakdown & Total Amount Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order Reference Code', style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF))),
                            Row(
                              children: [
                                Text(
                                  widget.orderNumber,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                                ),
                                IconButton(
                                  onPressed: _copyOrderNumber,
                                  icon: const Icon(Icons.copy, size: 16, color: Color(0xFF2563EB)),
                                  tooltip: 'Copy Order ID',
                                  padding: const EdgeInsets.only(left: 4),
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('TOTAL TO SEND', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                            Text(
                              '₱${widget.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF005CE6)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.subtotal != null || widget.deliveryFee != null) ...[
                      const Divider(height: 14, color: Color(0xFFBFDBFE)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal: ₱${(widget.subtotal ?? widget.totalAmount).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
                          Text('Delivery: ₱${(widget.deliveryFee ?? 0.0).toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Step 1: Instruction Alert Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scan QR, send EXACTLY ₱${widget.totalAmount.toStringAsFixed(2)}, input "${widget.orderNumber}" in GCash notes, and upload the transaction screenshot below.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Store Personal GCash QR Code & Account Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    // Account Name & Number banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Account Name:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('R** SA***L M.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('GCash Number:', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('+63 985 564 4297', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF005CE6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // QR Code Image (Clickable for full-res zoom)
                    InkWell(
                      onTap: () => _showFullResolutionQr(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Tooltip(
                        message: 'Click to view / zoom full size',
                        child: Container(
                          width: 210,
                          height: 210,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.qrImageUrl.isNotEmpty ? widget.qrImageUrl : 'http://127.0.0.1:8000/assets/gcash_qr.png',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => Image.asset(
                                'assets/gcash_qr.png',
                                fit: BoxFit.contain,
                                errorBuilder: (ctx2, err2, stack2) => Image.network(
                                  '/assets/gcash_qr.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (ctx3, err3, stack3) => const Center(
                                    child: Icon(Icons.qr_code_2, size: 80, color: Color(0xFF9CA3AF)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick Actions: View Full Size & Save
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showFullResolutionQr(context),
                          icon: const Icon(Icons.zoom_in, size: 15, color: Color(0xFF005CE6)),
                          label: const Text(
                            'Click to Zoom',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF005CE6)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _openQrExternal,
                          icon: const Icon(Icons.download, size: 15, color: Color(0xFF005CE6)),
                          label: const Text(
                            'Download QR',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF005CE6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Awaiting Verification View OR Upload Form
              if (_isPaid) ...[
                // Success View
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.check_circle, color: Color(0xFF10B981), size: 54),
                      SizedBox(height: 8),
                      Text(
                        'Payment Verified & Approved!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Order is now cooking in the kitchen 🍳',
                        style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
              ] else if (_isAwaitingVerification) ...[
                // Awaiting Verification View
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(color: Color(0xFF005CE6), strokeWidth: 3),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Verifying Payment with Store...',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your receipt screenshot has been forwarded to store admin. As soon as verified, kitchen preparation will start immediately.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      if (_receiptBytes != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _receiptBytes!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      if (_refController.text.trim().isNotEmpty)
                        Text(
                          'GCash Ref: ${_refController.text.trim()}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                        ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _isAwaitingVerification = false);
                        },
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Re-upload Different Receipt', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Upload Form
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 2: Upload Payment Receipt Screenshot',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Attach the transaction screenshot from your GCash app (max 5MB)',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 10),

                      // Image attachment preview or upload button
                      if (_receiptBytes != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(
                                  _receiptBytes!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _receiptFileName ?? 'receipt.png',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(_receiptBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB • Attached ✓',
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF059669)),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _pickReceipt,
                                child: const Text('Change', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        InkWell(
                          onTap: _pickReceipt,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF3B82F6), style: BorderStyle.solid),
                            ),
                            child: Column(
                              children: const [
                                Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF005CE6)),
                                SizedBox(height: 6),
                                Text(
                                  'Click to Browse & Upload Receipt',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF005CE6)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Supports PNG, JPG, JPEG, WEBP',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Optional GCash Reference Number Input
                      const Text(
                        'GCash Reference No. (Optional)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _refController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. 9023 4857 2834',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Submit Button (Disabled until receipt screenshot is picked)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: (_receiptBytes == null || _isUploading) ? null : _handleSubmitReceipt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005CE6),
                            disabledBackgroundColor: const Color(0xFF9CA3AF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Submit Receipt for Verification',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Live Chat with Support Option
              OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => OrderChatDialog(
                      orderNumber: widget.orderNumber,
                      currentRole: 'customer',
                      currentUserName: 'Customer',
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 14, color: Color(0xFF005CE6)),
                label: const Text('Need Help? Chat with Store Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF005CE6))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),

              // Live Status Footnote
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sync, size: 12, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(
                    _statusText,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

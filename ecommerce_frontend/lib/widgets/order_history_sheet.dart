import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import 'order_chat_dialog.dart';
import 'order_progress_stepper.dart';
import 'order_review_dialog.dart';
import 'qr_payment_modal.dart';

import '../services/guest_order_storage.dart';

class OrderHistorySheet extends StatefulWidget {
  final List<String>? sessionOrderNumbers;
  final String? userPhone;
  final String? userEmail;
  final String? userName;

  const OrderHistorySheet({
    super.key,
    this.sessionOrderNumbers,
    this.userPhone,
    this.userEmail,
    this.userName,
  });

  static const Color brandColor = Color(0xFFE8411E);

  @override
  State<OrderHistorySheet> createState() => _OrderHistorySheetState();
}

class _OrderHistorySheetState extends State<OrderHistorySheet> {
  List<OrderModel>? _orders;
  bool _isLoading = true;
  Timer? _pollTimer;
  String? _selectedOrderId;
  final TextEditingController _lookupController = TextEditingController();
  bool _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _silentRefreshOrders();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _lookupController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await _fetchOrdersForThisDevice();
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _silentRefreshOrders() async {
    try {
      final list = await _fetchOrdersForThisDevice();
      if (mounted) {
        setState(() {
          _orders = list;
        });
      }
    } catch (_) {}
  }

  bool get _isLoggedIn => widget.userEmail != null && widget.userEmail!.trim().isNotEmpty;

  Future<List<OrderModel>> _fetchOrdersForThisDevice() async {
    if (_isLoggedIn) {
      // 1. Logged-in Customer Flow:
      // Strictly fetch orders belonging to this authenticated account email only.
      // Do NOT merge random device order numbers to prevent account cross-pollution.
      return ApiService.getOrders(
        email: widget.userEmail!.trim(),
      );
    } else {
      // 2. Guest Customer Flow:
      // Guests don't have an account; retrieve orders specifically saved on this device or session.
      final stored = await GuestOrderStorage.getStoredOrderNumbers();
      final combined = <String>{};
      if (widget.sessionOrderNumbers != null) {
        combined.addAll(widget.sessionOrderNumbers!);
      }
      combined.addAll(stored);

      // If guest has placed no orders on this device, immediately return empty list
      if (combined.isEmpty) {
        return <OrderModel>[];
      }

      return ApiService.getOrders(
        orderNumbers: combined.toList(),
      );
    }
  }

  Future<void> _handleLookup() async {
    final orderNum = _lookupController.text.trim();
    if (orderNum.isEmpty) return;

    setState(() => _isLookingUp = true);
    try {
      final order = await ApiService.trackOrder(
        orderNum,
        email: _isLoggedIn ? widget.userEmail?.trim() : null,
      );
      if (!_isLoggedIn) {
        if (order.userId != null && order.userId!.isNotEmpty) {
          throw Exception('This order belongs to a registered customer. Please sign in to view it.');
        }
        await GuestOrderStorage.saveOrderNumber(order.orderNumber);
      }
      if (widget.sessionOrderNumbers != null && !widget.sessionOrderNumbers!.contains(order.orderNumber)) {
        widget.sessionOrderNumbers!.add(order.orderNumber);
      }
      _lookupController.clear();
      _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.orderNumber} added to tracking!'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        _openChat(order);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: OrderHistorySheet.brandColor, size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Orders & Tracking',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                            ),
                            Text(
                              _isLoggedIn
                                  ? 'Account: ${widget.userEmail}'
                                  : 'Guest Mode (Orders on this device)',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isLoggedIn ? const Color(0xFF059669) : const Color(0xFF6B7280),
                                fontWeight: _isLoggedIn ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (!_isLoggedIn && _orders != null && _orders!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Clear Saved Orders?'),
                                  content: const Text('This will remove all saved order tracking from this device.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await GuestOrderStorage.clear();
                                widget.sessionOrderNumbers?.clear();
                                _loadOrders();
                              }
                            },
                            tooltip: 'Clear orders on this device',
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF4B5563)),
                          onPressed: _loadOrders,
                          tooltip: 'Refresh orders',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Quick Order Lookup (Enter Order # to track & chat)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _lookupController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Enter Order # to track & chat (e.g. DASMA-OWE94A)...',
                            prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _handleLookup(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLookingUp ? null : _handleLookup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: OrderHistorySheet.brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLookingUp
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Track & Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Orders List
              Expanded(
                child: _isLoading && _orders == null
                    ? const Center(child: CircularProgressIndicator(color: OrderHistorySheet.brandColor))
                    : (_orders == null || _orders!.isEmpty)
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF9CA3AF)),
                                  const SizedBox(height: 12),
                                  Text(
                                    _isLoggedIn
                                        ? 'No orders found for this account'
                                        : 'No orders found on this device',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4B5563)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isLoggedIn
                                        ? 'Orders placed under ${widget.userEmail} will appear here automatically.'
                                        : 'Orders placed on this device will appear here automatically. You can also paste your Order # in the search box above.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: OrderHistorySheet.brandColor,
                            onRefresh: () async => _loadOrders(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders!.length,
                              itemBuilder: (context, index) {
                                final order = _orders![index];
                                return _buildOrderCard(order);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(OrderModel order) {
    setState(() => _selectedOrderId = order.orderNumber);
    showDialog(
      context: context,
      builder: (_) => OrderChatDialog(
        orderNumber: order.orderNumber,
        currentRole: 'customer',
        currentUserName: order.customerName ?? 'Customer',
        customerName: order.customerName,
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusBgColor;
    Color statusTextColor;

    switch (order.status.toLowerCase()) {
      case 'preparing':
        statusBgColor = const Color(0xFFDBEAFE);
        statusTextColor = const Color(0xFF1D4ED8);
        break;
      case 'dispatched':
      case 'out_for_delivery':
        statusBgColor = const Color(0xFFE0E7FF);
        statusTextColor = const Color(0xFF4338CA);
        break;
      case 'rider_arrived':
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFB45309);
        break;
      case 'delivered':
        statusBgColor = const Color(0xFFD1FAE5);
        statusTextColor = const Color(0xFF047857);
        break;
      case 'payment_rejected':
      case 'rejected':
        statusBgColor = const Color(0xFFFEE2E2);
        statusTextColor = const Color(0xFFDC2626);
        break;
      case 'cancelled':
        statusBgColor = const Color(0xFFFFE4E6);
        statusTextColor = const Color(0xFFBE123C);
        break;
      case 'payment_pending':
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFB45309);
        break;
      default:
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFB45309);
        break;
    }

    final bool isSelected = _selectedOrderId == order.orderNumber;
    final bool hasLalamove = order.lalamoveTrackingUrl != null &&
        order.lalamoveTrackingUrl!.trim().isNotEmpty &&
        (order.status.toUpperCase() == 'OUT_FOR_DELIVERY' ||
            order.status.toUpperCase() == 'DISPATCHED' ||
            order.status.toUpperCase() == 'RIDER_ARRIVED' ||
            order.status.toUpperCase() == 'DELIVERED');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? OrderHistorySheet.brandColor : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? OrderHistorySheet.brandColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openChat(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          order.orderNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: OrderHistorySheet.brandColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.orderTypeDisplay,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: OrderHistorySheet.brandColor),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order.statusDisplay,
                        style: TextStyle(color: statusTextColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sequential Progress Step Indicator
                OrderProgressStepper(
                  status: order.status,
                  brandColor: OrderHistorySheet.brandColor,
                ),
                const SizedBox(height: 12),

                // Re-upload proof button if payment is rejected or payment pending
                if (order.status.toUpperCase() == 'PAYMENT_REJECTED' ||
                    order.status.toUpperCase() == 'REJECTED' ||
                    order.status.toUpperCase() == 'PAYMENT_PENDING') ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.rejectionReason != null && order.rejectionReason!.trim().isNotEmpty) ...[
                          Text(
                            'Reason: ${order.rejectionReason}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => QrPaymentModal(
                                  orderNumber: order.orderNumber,
                                  totalAmount: order.totalAmount,
                                  qrImageUrl: 'assets/images/gcash_qr.png',
                                  orderType: order.orderType,
                                  deliveryFee: order.deliveryFee,
                                  onPaymentComplete: () {
                                    _loadOrders();
                                  },
                                ),
                              );
                            },
                            icon: const Icon(Icons.upload_file, size: 16),
                            label: const Text('Re-upload GCash Receipt Proof', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005CE6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),

                // Lalamove Rider Live Tracking Button
                if (hasLalamove) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(order.lalamoveTrackingUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Text('🛵', style: TextStyle(fontSize: 18)),
                      label: const Text(
                        'Track Rider on Lalamove',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEA580C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],

                // Items summary
                Column(
                  children: [
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x  ${item.productName}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '₱${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF111827), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (order.deliveryFee > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🛵 Delivery Fee',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                            ),
                            Text(
                              '₱${order.deliveryFee.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),

                // Rejection Reason Alert (if rejected)
                if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Payment Rejected: ${order.rejectionReason}',
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Total & Payment
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.paymentMethod.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.paymentStatus == 'paid' ? '• Paid' : '• Unpaid',
                          style: TextStyle(
                            fontSize: 11,
                            color: order.paymentStatus == 'paid' ? Colors.green : Colors.amber.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ₱${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: OrderHistorySheet.brandColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 10),

                // Customer Actions: Live Chat & Post-Order Rating
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openChat(order),
                        icon: const Icon(Icons.chat_bubble_outline, size: 15, color: OrderHistorySheet.brandColor),
                        label: const Text(
                          'Chat with Store',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: OrderHistorySheet.brandColor),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: OrderHistorySheet.brandColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    if (order.status.toUpperCase() == 'DELIVERED') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => OrderReviewDialog(
                                orderNumber: order.orderNumber,
                                onReviewSubmitted: _loadOrders,
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                          label: const Text(
                            'Rate & Review',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      ),
    );
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/firebase_order_service.dart';
import '../widgets/order_chat_dialog.dart';
import '../widgets/order_progress_stepper.dart';
import '../widgets/order_review_dialog.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final Set<String> _readOrderNumbers = {};
  Timer? _timer;
  StreamSubscription<List<OrderModel>>? _ordersSub;
  List<OrderModel> _currentOrders = [];
  bool _isLoading = true;
  String? _updatingOrderId;
  String? _selectedOrderId;
  final Map<String, TextEditingController> _trackingControllers = {};

  TextEditingController _getTrackingController(String orderNumber, String? currentUrl) {
    if (!_trackingControllers.containsKey(orderNumber)) {
      _trackingControllers[orderNumber] = TextEditingController(text: currentUrl ?? '');
    }
    return _trackingControllers[orderNumber]!;
  }

  @override
  void initState() {
    super.initState();
    _startOrderStream();

    // Periodic timer to re-evaluate elapsed minutes for the 5-minute overdue warning
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  void _startOrderStream() {
    _ordersSub = FirebaseOrderService.streamAllAdminOrders().listen(
      (orders) {
        if (mounted) {
          setState(() {
            _currentOrders = orders;
            _isLoading = false;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ordersSub?.cancel();
    for (var c in _trackingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _markAsRead(OrderModel order) {
    if (!_readOrderNumbers.contains(order.orderNumber)) {
      setState(() {
        _readOrderNumbers.add(order.orderNumber);
      });
    }
  }

  void _openChat(OrderModel order) {
    _markAsRead(order);
    setState(() => _selectedOrderId = order.orderNumber);
    showDialog(
      context: context,
      builder: (_) => OrderChatDialog(
        orderNumber: order.orderNumber,
        currentRole: 'admin',
        currentUserName: 'Store Admin',
        customerName: order.customerName,
      ),
    );
  }

  Future<void> _updateStatus(OrderModel order, String newStatus, {String? trackingUrl}) async {
    setState(() => _updatingOrderId = order.orderNumber);
    _markAsRead(order);

    final success = await ApiService.updateOrderStatus(order.id, newStatus, trackingUrl: trackingUrl);

    if (mounted) {
      setState(() => _updatingOrderId = null);
      if (success) {
        // Local optimistic update while stream updates
        setState(() {
          final idx = _currentOrders.indexWhere((o) => o.id == order.id || o.orderNumber == order.orderNumber);
          if (idx != -1) {
            _currentOrders[idx] = _currentOrders[idx].copyWith(
              status: newStatus,
              isRead: true,
              lalamoveTrackingUrl: trackingUrl ?? _currentOrders[idx].lalamoveTrackingUrl,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order #${order.orderNumber} status updated to ${newStatus.toUpperCase()}! Customer notified.',
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status. Please check backend network connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSaveTracking(OrderModel order, String url) async {
    if (url.trim().isEmpty) return;
    setState(() => _updatingOrderId = order.orderNumber);
    final success = await ApiService.saveTrackingUrl(order.orderNumber, url.trim());
    if (mounted) {
      setState(() => _updatingOrderId = null);
      if (success) {
        setState(() {
          final idx = _currentOrders.indexWhere((o) => o.id == order.id || o.orderNumber == order.orderNumber);
          if (idx != -1) {
            _currentOrders[idx] = _currentOrders[idx].copyWith(lalamoveTrackingUrl: url.trim());
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lalamove tracking link saved! Customer can now track rider on live map.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save tracking link. Please check network connection.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDispatch(OrderModel order) async {
    final controller = _getTrackingController(order.orderNumber, order.lalamoveTrackingUrl);
    final isDelivery = !order.orderTypeDisplay.contains('Dine-in') && !order.orderTypeDisplay.contains('Pick-up');

    if (controller.text.trim().isEmpty && isDelivery) {
      final linkController = TextEditingController();
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Text('🛵 ', style: TextStyle(fontSize: 22)),
              Text('Dispatch Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Lalamove Share Tracking Link so the customer can track their delivery:',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: linkController,
                decoration: InputDecoration(
                  hintText: 'https://share.lalamove.com/?id=...',
                  prefixIcon: const Icon(Icons.link, color: Color(0xFFF36F21)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Dispatch Without Link', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save & Dispatch'),
            ),
          ],
        ),
      );

      if (proceed == null) return;

      final entered = linkController.text.trim();
      if (entered.isNotEmpty) {
        controller.text = entered;
        await _handleSaveTracking(order, entered);
      }
    }

    await _updateStatus(order, 'OUT_FOR_DELIVERY', trackingUrl: controller.text.trim());
  }

  void _showReceiptDialog(BuildContext context, String receiptUrl, String orderNumber) {
    String cleanUrl = receiptUrl.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      final base = ApiService.baseUrl.replaceAll('/api', '');
      cleanUrl = '$base${cleanUrl.startsWith('/') ? '' : '/'}$cleanUrl';
    }

    final filename = cleanUrl.split('/').last.split('?').first;
    final directApiUrl = '${ApiService.baseUrl}/receipts/$filename';

    Future<Uint8List> loadReceiptBytes() async {
      // 1. Try CORS-enabled direct API route
      try {
        final res = await http.get(Uri.parse(directApiUrl));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return res.bodyBytes;
        }
      } catch (_) {}

      // 2. Try cleanUrl
      if (cleanUrl != directApiUrl) {
        try {
          final res2 = await http.get(Uri.parse(cleanUrl));
          if (res2.statusCode == 200 && res2.bodyBytes.isNotEmpty) {
            return res2.bodyBytes;
          }
        } catch (_) {}
      }

      throw Exception('Could not fetch receipt image data.');
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, color: Color(0xFF005CE6)),
                      const SizedBox(width: 8),
                      Text(
                        'GCash Receipt Proof #$orderNumber',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Open raw link in new tab',
                        onPressed: () => launchUrl(Uri.parse(cleanUrl), mode: LaunchMode.externalApplication),
                        icon: const Icon(Icons.open_in_new, color: Color(0xFF005CE6), size: 20),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 500),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: FutureBuilder<Uint8List>(
                    future: loadReceiptBytes(),
                    builder: (c, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 280,
                          width: double.infinity,
                          color: const Color(0xFFF8FAFC),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Color(0xFF005CE6)),
                                SizedBox(height: 12),
                                Text('Loading GCash receipt preview...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return Material(
                          color: Colors.transparent,
                          child: Tooltip(
                            message: 'Click image to open in new tab',
                            child: InkWell(
                              onTap: () => launchUrl(Uri.parse(cleanUrl), mode: LaunchMode.externalApplication),
                              child: InteractiveViewer(
                                panEnabled: true,
                                minScale: 0.8,
                                maxScale: 4.0,
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // Fallback with Image.network
                      return Material(
                        color: Colors.transparent,
                        child: Tooltip(
                          message: 'Click image to open in new tab',
                          child: InkWell(
                            onTap: () => launchUrl(Uri.parse(cleanUrl), mode: LaunchMode.externalApplication),
                            child: InteractiveViewer(
                              panEnabled: true,
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: Image.network(
                                cleanUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (c, err, stack) => Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(28),
                                  color: const Color(0xFFF8FAFC),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.image_not_supported_outlined, size: 48, color: Color(0xFF94A3B8)),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Receipt preview unavailable in canvas',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        cleanUrl,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 14),
                                      ElevatedButton.icon(
                                        onPressed: () => launchUrl(Uri.parse(cleanUrl), mode: LaunchMode.externalApplication),
                                        icon: const Icon(Icons.open_in_new, size: 14),
                                        label: const Text('Open receipt in new tab'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF005CE6),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tip: Pinch/scroll to zoom • Tap to open full size', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(cleanUrl), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_browser, size: 14),
                    label: const Text('View Raw Image', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerifyAction(OrderModel order, String action) async {
    String? rejectionReason;
    if (action == 'REJECT') {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.cancel_outlined, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Reject GCash Receipt Proof', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Specify rejection reason for Order #${order.orderNumber}:', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Blurred receipt, incorrect amount, mismatched reference number',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              child: const Text('Confirm Rejection'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      rejectionReason = reasonController.text.trim();
    }

    setState(() => _updatingOrderId = order.orderNumber);

    try {
      final res = await ApiService.verifyOrder(
        orderId: order.orderNumber,
        action: action,
        notes: rejectionReason,
      );

      if (mounted) {
        final newStatus = action == 'APPROVE' ? 'PREPARING' : 'PAYMENT_REJECTED';
        final newPaymentStatus = action == 'APPROVE' ? 'paid' : 'rejected';
        setState(() {
          final idx = _currentOrders.indexWhere((o) => o.id == order.id || o.orderNumber == order.orderNumber);
          if (idx != -1) {
            _currentOrders[idx] = _currentOrders[idx].copyWith(
              status: newStatus,
              paymentStatus: newPaymentStatus,
              adminNotes: rejectionReason,
              rejectionReason: rejectionReason,
              isRead: true,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? (action == 'APPROVE' ? 'Order verified and accepted!' : 'Order rejected.')),
            backgroundColor: action == 'APPROVE' ? const Color(0xFF10B981) : const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to verify order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingOrderId = null);
    }
  }

  List<OrderModel> get _filteredOrders {
    return _currentOrders.where((order) {
      final matchesSearch = order.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.notes.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final isRead = order.isRead || _readOrderNumbers.contains(order.orderNumber);

      switch (_selectedFilter) {
        case 'incoming':
        case 'pending':
          final s = order.status.toLowerCase();
          final ps = order.paymentStatus.toLowerCase();
          return s == 'pending' || s == 'payment_pending' || s == 'awaiting_verification' || ps == 'awaiting_verification';
        case 'awaiting_verification':
          return order.status.toUpperCase() == 'AWAITING_VERIFICATION' || order.paymentStatus.toLowerCase() == 'awaiting_verification';
        case 'payment_rejected':
        case 'rejected':
          return order.status.toUpperCase() == 'PAYMENT_REJECTED' || order.status.toUpperCase() == 'REJECTED' || order.paymentStatus.toLowerCase() == 'rejected';
        case 'preparing':
          return order.status.toLowerCase() == 'preparing';
        case 'dispatched':
          return order.status.toLowerCase() == 'dispatched' || order.status.toUpperCase() == 'OUT_FOR_DELIVERY';
        case 'delivered':
          return order.status.toLowerCase() == 'delivered' || order.status.toUpperCase() == 'COMPLETED';
        case 'overdue':
          return order.isOverdue;
        case 'unread':
          return !isRead;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rejectedCount = _currentOrders.where((o) =>
        o.status.toUpperCase() == 'PAYMENT_REJECTED' ||
        o.status.toUpperCase() == 'REJECTED' ||
        o.paymentStatus.toLowerCase() == 'rejected').length;
    final awaitingCount = _currentOrders.where((o) => o.status.toUpperCase() == 'AWAITING_VERIFICATION' || o.paymentStatus.toLowerCase() == 'awaiting_verification').length;
    final overdueCount = _currentOrders.where((o) => o.isOverdue).length;
    final preparingCount = _currentOrders.where((o) => o.status.toLowerCase() == 'preparing').length;
    final unreadCount = _currentOrders.where((o) => !o.isRead && !_readOrderNumbers.contains(o.orderNumber)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Management',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Real-time customer orders monitoring and status dispatch',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isLoading = true);
                  ApiService.getAdminOrders().then((orders) {
                    if (mounted) {
                      setState(() {
                        _currentOrders = orders;
                        _isLoading = false;
                      });
                    }
                  });
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overdue / Urgent Global Alert (If any orders > 5 mins pending)
          if (overdueCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ URGENT REMINDER: $overdueCount Order${overdueCount > 1 ? 's' : ''} Placed > 5 Minutes Ago!',
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Customers are waiting for their food preparation update. Please mark pending orders as "Preparing".',
                          style: TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'overdue';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Overdue Orders'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Stats Bar Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 800 ? (constraints.maxWidth - 16) / 2 : (constraints.maxWidth - 48) / 4;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Total Placed Orders',
                      _currentOrders.length.toString(),
                      Icons.receipt_long,
                      const Color(0xFF3B82F6),
                      const Color(0xFFEFF6FF),
                      filterKey: 'all',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Rejected Orders',
                      rejectedCount.toString(),
                      Icons.cancel_outlined,
                      const Color(0xFFDC2626),
                      const Color(0xFFFEF2F2),
                      filterKey: 'rejected',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Overdue (> 5 Mins)',
                      overdueCount.toString(),
                      Icons.timer_off_outlined,
                      const Color(0xFFEAB308),
                      const Color(0xFFFEF9C3),
                      filterKey: 'overdue',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Food Preparing',
                      preparingCount.toString(),
                      Icons.ramen_dining_outlined,
                      const Color(0xFF10B981),
                      const Color(0xFFECFDF5),
                      filterKey: 'preparing',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Filters & Search Bar Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search box
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by Order #, customer phone, notes, or payment...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Filter Dropdown beside search bar
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: [
                            'all',
                            'pending',
                            'awaiting_verification',
                            'overdue',
                            'preparing',
                            'dispatched',
                            'delivered',
                            'rejected',
                            'unread'
                          ].contains(_selectedFilter)
                              ? _selectedFilter
                              : 'all',
                          icon: const Icon(Icons.filter_list, color: Color(0xFFF36F21), size: 20),
                          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 13),
                          borderRadius: BorderRadius.circular(10),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('All Orders (${_currentOrders.length})')),
                            DropdownMenuItem(value: 'rejected', child: Text('❌ Rejected Orders ($rejectedCount)')),
                            DropdownMenuItem(value: 'awaiting_verification', child: Text('🔍 Awaiting GCash ($awaitingCount)')),
                            DropdownMenuItem(value: 'overdue', child: Text('⚠️ Overdue ($overdueCount)')),
                            DropdownMenuItem(value: 'preparing', child: Text('🍳 Food Preparing ($preparingCount)')),
                            const DropdownMenuItem(value: 'dispatched', child: Text('🛵 Dispatched')),
                            const DropdownMenuItem(value: 'delivered', child: Text('✅ Delivered')),
                            DropdownMenuItem(value: 'unread', child: Text('✉️ Unread ($unreadCount)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFilter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Orders List
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_filteredOrders.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(48.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No orders found matching "$_selectedFilter"',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredOrders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = _filteredOrders[index];
                return _buildOrderCard(order);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
    Color bgColor, {
    required String filterKey,
    String? badgeText,
    bool isUrgent = false,
  }) {
    final isSelected = _selectedFilter == filterKey;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = filterKey;
          });
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: bgColor.withValues(alpha: 0.35),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey.shade200,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? accentColor.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.04),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? Colors.white : accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? accentColor : const Color(0xFF1E293B),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                            ),
                          ),
                      ],
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

  Widget _buildFilterChip(String key, String label, {Color? color}) {
    final isSelected = _selectedFilter == key;
    final primaryColor = color ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        selectedColor: primaryColor,
        backgroundColor: const Color(0xFFF1F5F9),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedFilter = key);
          }
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final isRead = order.isRead || _readOrderNumbers.contains(order.orderNumber);
    final isOverdue = order.isOverdue;
    final isUpdating = _updatingOrderId == order.orderNumber;
    final isSelected = _selectedOrderId == order.orderNumber;

    Color cardBorderColor = Colors.grey.shade200;
    if (isOverdue) {
      cardBorderColor = const Color(0xFFEF4444);
    } else if (isSelected) {
      cardBorderColor = const Color(0xFFF36F21);
    } else if (!isRead) {
      cardBorderColor = const Color(0xFF3B82F6);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cardBorderColor,
          width: (isOverdue || isSelected) ? 2 : (isRead ? 1 : 1.5),
        ),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          _markAsRead(order);
          setState(() => _selectedOrderId = order.orderNumber);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Urgent 5-Minute Overdue Banner inside the Order Card
              if (isOverdue) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_3_sharp, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '⚠️ URGENT REMINDER: Placed ${order.elapsedMinutes} minutes ago! Admin has not clicked "Preparing" yet.',
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Card Top Header Line
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                spacing: 8,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      _buildReadBadge(isRead),
                      _buildTypeBadge(order.orderTypeDisplay),
                    ],
                  ),
                  Text(
                    '₱${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE8411E)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time Placed & Payment Method
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Placed: ${order.createdAt.isNotEmpty ? order.createdAt : "Just now"} (${order.elapsedMinutes} mins ago)',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Payment: ${order.paymentMethod} (${order.paymentStatus.toUpperCase()})',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal Progress Stepper
              OrderProgressStepper(
                status: order.status,
                brandColor: const Color(0xFFF36F21),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Items Snapshot
              if (order.items.isNotEmpty) ...[
                const Text(
                  'Order Items:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x  ${item.productName} (${item.variantName})',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '₱${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Customer Details & Notes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          order.customerName != null && order.customerName!.isNotEmpty ? order.customerName! : 'Customer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        if (order.customerEmail != null && order.customerEmail!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text('• ${order.customerEmail}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ],
                    ),
                    if (order.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.notes,
                              style: const TextStyle(color: Color(0xFF334155), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (order.rejectionReason != null && order.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rejection Reason: ${order.rejectionReason}',
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Lalamove Tracking Link Integration (for Delivery Orders)
              if (!order.orderTypeDisplay.contains('Dine-in') && !order.orderTypeDisplay.contains('Pick-up')) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🛵 ', style: TextStyle(fontSize: 16)),
                          const Text(
                            'Lalamove Share Tracking Link',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                          ),
                          if (order.lalamoveTrackingUrl != null && order.lalamoveTrackingUrl!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => launchUrl(Uri.parse(order.lalamoveTrackingUrl!), mode: LaunchMode.externalApplication),
                              child: const Text('(Open Map ↗)', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _getTrackingController(order.orderNumber, order.lalamoveTrackingUrl),
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'https://share.lalamove.com/?id=...',
                                  prefixIcon: const Icon(Icons.link, size: 16, color: Color(0xFFF36F21)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: isUpdating
                                ? null
                                : () {
                                    final val = _getTrackingController(order.orderNumber, order.lalamoveTrackingUrl).text;
                                    _handleSaveTracking(order, val);
                                  },
                            icon: const Icon(Icons.save, size: 14),
                            label: const Text('Save Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF36F21),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // GCash Verification Banner for Admin
              if (order.status.toUpperCase() == 'AWAITING_VERIFICATION' ||
                  order.receiptImageUrl != null ||
                  order.gcashRefNumber != null ||
                  (order.paymentMethod.toLowerCase() == 'gcash' && order.status.toUpperCase() == 'PAYMENT_PENDING')) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: order.status.toUpperCase() == 'PAID'
                        ? const Color(0xFFECFDF5)
                        : (order.status.toUpperCase() == 'AWAITING_VERIFICATION'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFFFFBEB)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: order.status.toUpperCase() == 'PAID'
                          ? const Color(0xFFA7F3D0)
                          : (order.status.toUpperCase() == 'AWAITING_VERIFICATION'
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFFDE68A)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                order.status.toUpperCase() == 'PAID'
                                    ? Icons.check_circle
                                    : (order.status.toUpperCase() == 'AWAITING_VERIFICATION'
                                        ? Icons.verified_user
                                        : Icons.warning_amber_rounded),
                                size: 18,
                                color: order.status.toUpperCase() == 'PAID'
                                    ? const Color(0xFF059669)
                                    : (order.status.toUpperCase() == 'AWAITING_VERIFICATION'
                                        ? const Color(0xFF005CE6)
                                        : const Color(0xFFD97706)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order.status.toUpperCase() == 'PAID'
                                    ? 'GCash Payment Verified ✓'
                                    : (order.status.toUpperCase() == 'AWAITING_VERIFICATION'
                                        ? 'GCash Proof Awaiting Verification'
                                        : 'GCash Payment Pending - DO NOT COOK'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: order.status.toUpperCase() == 'PAID'
                                      ? const Color(0xFF065F46)
                                      : (order.status.toUpperCase() == 'AWAITING_VERIFICATION'
                                          ? const Color(0xFF1E3A8A)
                                          : const Color(0xFF92400E)),
                                ),
                              ),
                            ],
                          ),
                          if (order.gcashRefNumber != null && order.gcashRefNumber!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                'Ref: ${order.gcashRefNumber}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order.customerName != null && order.customerName!.isNotEmpty)
                                  Text('Customer Name: ${order.customerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                Text('Exact Total Due: ₱${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF005CE6))),
                                if (order.adminNotes != null && order.adminNotes!.isNotEmpty)
                                  Text('Admin Notes: ${order.adminNotes}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          if (order.receiptImageUrl != null && order.receiptImageUrl!.isNotEmpty) ...[
                            ElevatedButton.icon(
                              onPressed: () => _showReceiptDialog(context, order.receiptImageUrl!, order.orderNumber),
                              icon: const Icon(Icons.remove_red_eye, size: 14),
                              label: const Text('View Receipt Proof', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005CE6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Current Status Pill & Sequential Action Buttons Row
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      _buildStatusPill(order.statusDisplay, order.status),
                    ],
                  ),

                  // Actions
                  if (isUpdating)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Live Customer-Admin Chat Button
                        OutlinedButton.icon(
                          onPressed: () => _openChat(order),
                          icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFFF36F21)),
                          label: const Text('Live Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF36F21))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFF36F21)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),

                        // Post-Order Review Inspection (If delivered)
                        if (order.status.toUpperCase() == 'DELIVERED') ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => OrderReviewDialog(orderNumber: order.orderNumber),
                              );
                            },
                            icon: const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                            label: const Text('Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFDE68A)),
                              backgroundColor: const Color(0xFFFFFBEB),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        // ── Sequential Linear Action Stepper Buttons (Strict progression) ──
                        if (order.status.toLowerCase() == 'pending' ||
                            order.status.toUpperCase() == 'PAYMENT_PENDING' ||
                            order.status.toUpperCase() == 'AWAITING_VERIFICATION' ||
                            order.paymentStatus.toLowerCase() == 'awaiting_verification') ...[
                          OutlinedButton.icon(
                            onPressed: isUpdating ? null : () => _handleVerifyAction(order, 'REJECT'),
                            icon: const Icon(Icons.close, size: 14, color: Color(0xFFDC2626)),
                            label: const Text('Reject Receipt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF87171)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isUpdating ? null : () => _handleVerifyAction(order, 'APPROVE'),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Approve Payment & Start Preparing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        if (order.status.toUpperCase() == 'PAYMENT_REJECTED' || order.status.toUpperCase() == 'REJECTED') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cancel, size: 14, color: Color(0xFFDC2626)),
                                const SizedBox(width: 6),
                                Text(
                                  order.rejectionReason != null && order.rejectionReason!.isNotEmpty
                                      ? 'Rejected: ${order.rejectionReason}'
                                      : 'Receipt Proof Rejected',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isUpdating ? null : () => _handleVerifyAction(order, 'APPROVE'),
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Re-verify & Start Preparing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        if (order.status.toUpperCase() == 'PREPARING') ...[
                          ElevatedButton.icon(
                            onPressed: isUpdating ? null : () => _handleDispatch(order),
                            icon: const Icon(Icons.delivery_dining, size: 16),
                            label: const Text('Dispatch (Out for Delivery)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        if (order.status.toUpperCase() == 'OUT_FOR_DELIVERY' || order.status.toLowerCase() == 'dispatched') ...[
                          ElevatedButton.icon(
                            onPressed: isUpdating ? null : () => _updateStatus(order, 'RIDER_ARRIVED'),
                            icon: const Icon(Icons.pin_drop, size: 16),
                            label: const Text('Mark Rider Arrived', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        if (order.status.toUpperCase() == 'RIDER_ARRIVED') ...[
                          ElevatedButton.icon(
                            onPressed: isUpdating ? null : () => _updateStatus(order, 'DELIVERED'),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Confirm Delivered', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        if (order.status.toUpperCase() == 'DELIVERED' || order.status.toUpperCase() == 'COMPLETED') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                                SizedBox(width: 6),
                                Text(
                                  'Order Completed',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadBadge(bool isRead) {
    if (!isRead) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
            SizedBox(width: 4),
            Text(
              'UNREAD',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: const Text(
        'READ',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTypeBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStatusPill(String display, String statusKey) {
    Color bg = const Color(0xFFFEF3C7);
    Color fg = const Color(0xFFD97706);

    switch (statusKey.toLowerCase()) {
      case 'awaiting_verification':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'paid':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case 'payment_pending':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'payment_rejected':
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
      case 'preparing':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        break;
      case 'dispatched':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4338CA);
        break;
      case 'delivered':
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case 'cancelled':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

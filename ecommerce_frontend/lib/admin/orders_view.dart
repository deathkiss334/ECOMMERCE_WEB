import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../services/firebase_order_service.dart';

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
    super.dispose();
  }

  void _markAsRead(OrderModel order) {
    if (!_readOrderNumbers.contains(order.orderNumber)) {
      setState(() {
        _readOrderNumbers.add(order.orderNumber);
      });
    }
  }

  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    setState(() => _updatingOrderId = order.orderNumber);
    _markAsRead(order);

    final success = await ApiService.updateOrderStatus(order.id, newStatus);

    if (mounted) {
      setState(() => _updatingOrderId = null);
      if (success) {
        // Local optimistic update while stream updates
        setState(() {
          final idx = _currentOrders.indexWhere((o) => o.id == order.id);
          if (idx != -1) {
            _currentOrders[idx] = _currentOrders[idx].copyWith(status: newStatus, isRead: true);
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

  List<OrderModel> get _filteredOrders {
    return _currentOrders.where((order) {
      final matchesSearch = order.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.notes.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      final isRead = order.isRead || _readOrderNumbers.contains(order.orderNumber);

      switch (_selectedFilter) {
        case 'pending':
          return order.status.toLowerCase() == 'pending';
        case 'preparing':
          return order.status.toLowerCase() == 'preparing';
        case 'dispatched':
          return order.status.toLowerCase() == 'dispatched';
        case 'delivered':
          return order.status.toLowerCase() == 'delivered';
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
    final pendingCount = _currentOrders.where((o) => o.status.toLowerCase() == 'pending').length;
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
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'New Incoming (Pending)',
                      pendingCount.toString(),
                      Icons.new_releases_outlined,
                      const Color(0xFFF59E0B),
                      const Color(0xFFFFFBEB),
                      badgeText: unreadCount > 0 ? '$unreadCount Unread' : null,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Overdue (> 5 Mins)',
                      overdueCount.toString(),
                      Icons.timer_off_outlined,
                      const Color(0xFFEF4444),
                      const Color(0xFFFEF2F2),
                      isUrgent: overdueCount > 0,
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

                    // Filter tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All (${_currentOrders.length})'),
                          _buildFilterChip('pending', 'Pending ($pendingCount)'),
                          if (overdueCount > 0)
                            _buildFilterChip('overdue', '⚠️ Overdue ($overdueCount)', color: Colors.red),
                          _buildFilterChip('preparing', 'Preparing ($preparingCount)'),
                          _buildFilterChip('dispatched', 'Dispatched'),
                          _buildFilterChip('delivered', 'Delivered'),
                          if (unreadCount > 0)
                            _buildFilterChip('unread', 'Unread ($unreadCount)', color: Colors.purple),
                        ],
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
    String? badgeText,
    bool isUrgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUrgent ? Border.all(color: const Color(0xFFEF4444), width: 2) : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
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
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
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

    Color cardBorderColor = Colors.grey.shade200;
    if (isOverdue) {
      cardBorderColor = const Color(0xFFEF4444);
    } else if (!isRead) {
      cardBorderColor = const Color(0xFF3B82F6);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: isOverdue ? 2 : (isRead ? 1 : 1.5)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _markAsRead(order),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 12),
                      _buildReadBadge(isRead),
                      const SizedBox(width: 8),
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
              if (order.notes.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Customer Notes / Contact: ${order.notes}',
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Current Status Pill & Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
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
                      children: [
                        // Primary "Preparing" Button as explicitly requested
                        if (order.status.toLowerCase() == 'pending') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(order, 'preparing'),
                            icon: const Icon(Icons.soup_kitchen, size: 18),
                            label: const Text('Preparing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8411E), // Brand Orange/Red
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 2,
                            ),
                          ),
                        ],

                        if (order.status.toLowerCase() == 'preparing') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(order, 'dispatched'),
                            icon: const Icon(Icons.delivery_dining, size: 18),
                            label: const Text('Out for Delivery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        if (order.status.toLowerCase() == 'dispatched') ...[
                          ElevatedButton.icon(
                            onPressed: () => _updateStatus(order, 'delivered'),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Mark Delivered'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],

                        // Quick Status Switcher Dropdown menu for Admin flexibility
                        PopupMenuButton<String>(
                          onSelected: (newStatus) => _updateStatus(order, newStatus),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'pending', child: Text('Set Pending')),
                            const PopupMenuItem(value: 'preparing', child: Text('Set Preparing')),
                            const PopupMenuItem(value: 'dispatched', child: Text('Set Out for Delivery')),
                            const PopupMenuItem(value: 'delivered', child: Text('Set Delivered')),
                            const PopupMenuItem(value: 'cancelled', child: Text('Set Cancelled')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Row(
                              children: [
                                Text('Change Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                Icon(Icons.arrow_drop_down, size: 18),
                              ],
                            ),
                          ),
                        ),
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

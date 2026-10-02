import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard_view.dart';
import 'orders_view.dart';
import 'users_view.dart';
import 'products_view.dart';
import 'analytics_view.dart';
import '../models/order_model.dart';
import '../services/firebase_order_service.dart';

enum NotificationFilter { all, unread, placed, delivered, overdue }

class AdminNotification {
  final String id;
  final String orderNumber;
  final String type; // 'PLACED', 'DELIVERED', 'OVERDUE'
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;

  AdminNotification({
    required this.id,
    required this.orderNumber,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  int _newOrdersCount = 0;
  int _overdueOrdersCount = 0;
  StreamSubscription<List<OrderModel>>? _ordersSub;

  final Set<String> _readNotificationIds = {};
  List<AdminNotification> _notifications = [];
  NotificationFilter _currentFilter = NotificationFilter.all;
  OverlayEntry? _overlayEntry;
  bool _isOverlayOpen = false;

  final List<Widget> _views = [
    const DashboardView(),
    const OrdersView(),
    const UsersView(),
    const ProductsView(),
    const AnalyticsView(),
  ];

  @override
  void initState() {
    super.initState();
    _ordersSub = FirebaseOrderService.streamAllAdminOrders().listen((orders) {
      if (mounted) {
        _updateNotificationsFromOrders(orders);
      }
    });
  }

  void _updateNotificationsFromOrders(List<OrderModel> orders) {
    final List<AdminNotification> newList = [];

    for (final order in orders) {
      final dt = order.parsedCreatedAt ?? DateTime.now();
      final statusUpper = order.status.toUpperCase();

      // 1. Order Placed
      if (['PENDING', 'PREPARING', 'AWAITING_VERIFICATION', 'PAYMENT_PENDING'].contains(statusUpper)) {
        final id = 'placed_${order.orderNumber}';
        newList.add(AdminNotification(
          id: id,
          orderNumber: order.orderNumber,
          type: 'PLACED',
          title: 'New Order Placed',
          message: 'Order #${order.orderNumber} by ${order.customerName ?? "Customer"} (₱${order.totalAmount.toStringAsFixed(2)})',
          timestamp: dt,
          isRead: _readNotificationIds.contains(id),
        ));
      }

      // 2. Order Delivered
      if (statusUpper == 'DELIVERED') {
        final id = 'delivered_${order.orderNumber}';
        newList.add(AdminNotification(
          id: id,
          orderNumber: order.orderNumber,
          type: 'DELIVERED',
          title: 'Order Delivered',
          message: 'Order #${order.orderNumber} delivered to ${order.customerName ?? "Customer"}.',
          timestamp: dt,
          isRead: _readNotificationIds.contains(id),
        ));
      }

      // 3. Order Overdue
      if (order.isOverdue) {
        final id = 'overdue_${order.orderNumber}';
        newList.add(AdminNotification(
          id: id,
          orderNumber: order.orderNumber,
          type: 'OVERDUE',
          title: 'Order Overdue (5+ mins)',
          message: 'Order #${order.orderNumber} has been waiting for ${order.elapsedMinutes} mins!',
          timestamp: dt,
          isRead: _readNotificationIds.contains(id),
        ));
      }
    }

    // Sort newest first
    newList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _notifications = newList;
      _newOrdersCount = orders.where((o) => ['PENDING', 'PREPARING', 'AWAITING_VERIFICATION'].contains(o.status.toUpperCase())).length;
      _overdueOrdersCount = orders.where((o) => o.isOverdue).length;
    });
  }

  @override
  void dispose() {
    _closeNotificationDropdown();
    _ordersSub?.cancel();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _toggleNotificationDropdown() {
    if (_isOverlayOpen) {
      _closeNotificationDropdown();
    } else {
      _openNotificationDropdown();
    }
  }

  void _openNotificationDropdown() {
    _closeNotificationDropdown();

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setOverlayState) {
            final unreadCount = _notifications.where((n) => !n.isRead).length;

            List<AdminNotification> filtered = _notifications.where((n) {
              if (_currentFilter == NotificationFilter.unread) return !n.isRead;
              if (_currentFilter == NotificationFilter.placed) return n.type == 'PLACED';
              if (_currentFilter == NotificationFilter.delivered) return n.type == 'DELIVERED';
              if (_currentFilter == NotificationFilter.overdue) return n.type == 'OVERDUE';
              return true;
            }).toList();

            return Stack(
              children: [
                // Modal barrier
                GestureDetector(
                  onTap: _closeNotificationDropdown,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
                // Popover Panel
                Positioned(
                  top: 75,
                  right: 24,
                  child: Material(
                    elevation: 16,
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: Container(
                      width: 420,
                      constraints: const BoxConstraints(maxHeight: 560),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Bar
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.notifications_active, color: Color(0xFF2563EB), size: 22),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Notifications',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    if (unreadCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$unreadCount UNREAD',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: unreadCount == 0
                                      ? null
                                      : () {
                                          setState(() {
                                            _readNotificationIds.addAll(_notifications.map((n) => n.id));
                                            for (var n in _notifications) {
                                              n.isRead = true;
                                            }
                                          });
                                          setOverlayState(() {});
                                        },
                                  icon: const Icon(Icons.done_all, size: 16),
                                  label: const Text('Mark all read', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                _buildFilterChip(setOverlayState, NotificationFilter.all, 'All (${_notifications.length})'),
                                _buildFilterChip(setOverlayState, NotificationFilter.unread, 'Unread ($unreadCount)'),
                                _buildFilterChip(setOverlayState, NotificationFilter.placed, 'Placed 🛒'),
                                _buildFilterChip(setOverlayState, NotificationFilter.delivered, 'Delivered 🎉'),
                                _buildFilterChip(setOverlayState, NotificationFilter.overdue, 'Overdue ⚠️'),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Notification Items List
                          Flexible(
                            child: filtered.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('No notifications found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.all(12),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final item = filtered[index];
                                      return _buildNotificationCard(item, setOverlayState);
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOverlayOpen = true);
  }

  void _closeNotificationDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    if (mounted && _isOverlayOpen) {
      setState(() => _isOverlayOpen = false);
    }
  }

  Widget _buildFilterChip(StateSetter setOverlayState, NotificationFilter filter, String label) {
    final isSelected = _currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.black87,
        ),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        showCheckmark: false,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _currentFilter = filter;
            });
            setOverlayState(() {});
          }
        },
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotification item, StateSetter setOverlayState) {
    final isUnread = !item.isRead;

    Color accentColor;
    IconData iconData;
    String badgeText;

    switch (item.type) {
      case 'DELIVERED':
        accentColor = const Color(0xFF16A34A); // Green
        iconData = Icons.check_circle_rounded;
        badgeText = 'DELIVERED';
        break;
      case 'OVERDUE':
        accentColor = const Color(0xFFDC2626); // Red
        iconData = Icons.warning_amber_rounded;
        badgeText = 'OVERDUE';
        break;
      case 'PLACED':
      default:
        accentColor = const Color(0xFF2563EB); // Blue
        iconData = Icons.shopping_bag_rounded;
        badgeText = 'NEW ORDER';
        break;
    }

    final diff = DateTime.now().difference(item.timestamp);
    String timeAgo = 'Just now';
    if (diff.inMinutes >= 60) {
      timeAgo = '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      timeAgo = '${diff.inMinutes}m ago';
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _readNotificationIds.add(item.id);
          item.isRead = true;
          _selectedIndex = 1; // Open Order Management view
        });
        _closeNotificationDropdown();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: isUnread
            ? BoxDecoration(
                // DARK STYLE FOR UNREAD NOTIFICATION
                color: const Color(0xFF0F172A), // Dark slate
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withValues(alpha: 0.8), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              )
            : BoxDecoration(
                // LIGHT STYLE FOR READ NOTIFICATION
                color: const Color(0xFFF8FAFC), // Light slate
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isUnread ? 0.25 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: isUnread ? 0.3 : 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: isUnread ? accentColor : accentColor.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeAgo,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: isUnread ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.message,
                    style: TextStyle(
                      color: isUnread ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Theme.of(context).colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Admin Panel',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
                _buildNavItem(1, Icons.shopping_bag_outlined, 'Order Management', badgeCount: _newOrdersCount, isUrgent: _overdueOrdersCount > 0),
                _buildNavItem(2, Icons.people_outline, 'User Management'),
                _buildNavItem(3, Icons.inventory_2_outlined, 'Product Management'),
                _buildNavItem(4, Icons.analytics_outlined, 'Sales Analytics'),
                const Spacer(),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    leading: const Icon(Icons.arrow_back),
                    title: const Text('Back to Store'),
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/shop');
                      }
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    hoverColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Spacer(),
                      // Profile & Notifications
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _unreadCount > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                                  color: _unreadCount > 0 ? const Color(0xFF2563EB) : Colors.black87,
                                ),
                                onPressed: _toggleNotificationDropdown,
                              ),
                              if (_unreadCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _overdueOrdersCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                    child: Text(
                                      '$_unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE2E8F0),
                            child: Icon(Icons.person, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          const Text('Admin User', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    ],
                  ),
                ),
                // Page Content
                Expanded(
                  child: _views[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title, {int badgeCount = 0, bool isUrgent = false}) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
        leading: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
        ),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            : null,
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

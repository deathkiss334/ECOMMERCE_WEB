import 'dart:async';
import 'package:flutter/material.dart';
import 'dashboard_view.dart';
import 'orders_view.dart';
import 'users_view.dart';
import 'products_view.dart';
import 'analytics_view.dart';
import '../models/order_model.dart';
import '../services/firebase_order_service.dart';

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
        final pending = orders.where((o) => o.status.toLowerCase() == 'pending').length;
        final overdue = orders.where((o) => o.isOverdue).length;
        setState(() {
          _newOrdersCount = pending;
          _overdueOrdersCount = overdue;
        });
      }
    });
  }

  @override
  void dispose() {
    _ordersSub?.cancel();
    super.dispose();
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
                      Navigator.pop(context);
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
                      // Search
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search admin portal...',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Profile & Notifications
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_outlined),
                                onPressed: () {
                                  setState(() => _selectedIndex = 1);
                                },
                              ),
                              if (_newOrdersCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _overdueOrdersCount > 0 ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                    child: Text(
                                      '$_newOrdersCount',
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

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isLoading = true;
  num _totalRevenue = 0;
  int _totalOrders = 0;
  int _activeUsers = 0;
  List<dynamic> _recentOrders = [];

  String _formatCurrency(num amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final mathFunc = (Match match) => '${match[1]},';
    final formattedInt = parts[0].replaceAllMapped(reg, mathFunc);
    return '₱$formattedInt.${parts[1]}';
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await ApiService.getAdminAnalytics(range: '7days');

    if (mounted) {
      if (data.isNotEmpty) {
        setState(() {
          _totalRevenue = data['total_revenue'] ?? 0;
          _totalOrders = data['total_orders'] ?? 0;
          _activeUsers = data['active_users'] ?? 0;
          _recentOrders = data['recent_orders'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real-time stats from the store database',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _fetchDashboardData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth < 700
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 48) / 3;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _buildStatCard(
                            context,
                            'Total Revenue',
                            _formatCurrency(_totalRevenue),
                            Icons.monetization_on_outlined,
                            Colors.green,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildStatCard(
                            context,
                            'Active Customers',
                            '$_activeUsers',
                            Icons.people_alt_outlined,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildStatCard(
                            context,
                            'Total Store Orders',
                            '$_totalOrders',
                            Icons.receipt_long_outlined,
                            Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Store Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Live Feed',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _recentOrders.isEmpty
                    ? Container(
                        height: 120,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Text('No recent activity recorded yet.', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentOrders.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _recentOrders[index];
                          final orderNum = item['order_number'] ?? '';
                          final cust = item['customer_name'] ?? 'Customer';
                          final amt = item['total_amount'] ?? 0;
                          final status = item['status'] ?? 'PREPARING';
                          final timeStr = item['created_at'] ?? '';

                          Color statusColor = Colors.orange;
                          if (status == 'DELIVERED') statusColor = Colors.green;
                          if (status == 'PAYMENT_REJECTED' || status == 'REJECTED') statusColor = Colors.red;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.shopping_bag, color: Theme.of(context).colorScheme.primary, size: 20),
                            ),
                            title: Text(
                              'Order #$orderNum - $cust',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '$timeStr • ${_formatCurrency(amt)}',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Text('Live Database Metric', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

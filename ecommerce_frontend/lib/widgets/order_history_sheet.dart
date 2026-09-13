import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderHistorySheet extends StatefulWidget {
  final List<String>? sessionOrderNumbers;
  final String? userPhone;

  const OrderHistorySheet({
    super.key,
    this.sessionOrderNumbers,
    this.userPhone,
  });

  static const Color brandColor = Color(0xFFE8411E);

  @override
  State<OrderHistorySheet> createState() => _OrderHistorySheetState();
}

class _OrderHistorySheetState extends State<OrderHistorySheet> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = ApiService.getOrders(
        orderNumbers: widget.sessionOrderNumbers,
        phone: widget.userPhone,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  children: const [
                    Icon(Icons.receipt_long, color: OrderHistorySheet.brandColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'My Orders & Tracking',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF4B5563)),
                  onPressed: _loadOrders,
                  tooltip: 'Refresh orders',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Orders List
          Expanded(
            child: FutureBuilder<List<OrderModel>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: OrderHistorySheet.brandColor));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 40),
                          const SizedBox(height: 12),
                          Text('Failed to load orders: ${snapshot.error}', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadOrders,
                            style: ElevatedButton.styleFrom(backgroundColor: OrderHistorySheet.brandColor),
                            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.shopping_bag_outlined, size: 48, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 12),
                        Text('No orders placed yet', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                        SizedBox(height: 4),
                        Text('Add some delicious Filipino dishes to your cart!', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: OrderHistorySheet.brandColor,
                  onRefresh: () async => _loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
        statusBgColor = const Color(0xFFE0E7FF);
        statusTextColor = const Color(0xFF4338CA);
        break;
      case 'delivered':
        statusBgColor = const Color(0xFFD1FAE5);
        statusTextColor = const Color(0xFF047857);
        break;
      case 'cancelled':
        statusBgColor = const Color(0xFFFFE4E6);
        statusTextColor = const Color(0xFFBE123C);
        break;
      default:
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFB45309);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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

          // Progress Step Indicator
          _buildTrackerSteps(order.stepIndex),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 10),

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
        ],
      ),
    );
  }

  Widget _buildTrackerSteps(int activeStep) {
    final steps = ['Confirmed', 'Packing', 'On Delivery', 'Delivered'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = index ~/ 2;
          final isCompleted = activeStep > stepBefore;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? OrderHistorySheet.brandColor : const Color(0xFFE5E7EB),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isActive = activeStep >= stepIndex;
        final isCurrent = activeStep == stepIndex;

        return Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? OrderHistorySheet.brandColor : const Color(0xFFE5E7EB),
                border: isCurrent
                    ? Border.all(color: OrderHistorySheet.brandColor.withValues(alpha: 0.3), width: 3)
                    : null,
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        );
      }),
    );
  }
}

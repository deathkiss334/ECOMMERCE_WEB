import 'package:flutter/material.dart';
import '../../services/order_service.dart';

class ProfileBottomSheet extends StatefulWidget {
  const ProfileBottomSheet({super.key});

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet> {
  List<dynamic> myOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final result = await OrderService.getOrderHistory();
    if (mounted) {
      setState(() {
        myOrders = result;
        isLoading = false;
      });
    }
  }

  void _showReviewDialog(int orderId) {
    final TextEditingController commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your order?'),
              const SizedBox(height: 10),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  hintText: 'Great food, arrived hot!',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await OrderService.submitReview(orderId, 5, commentController.text);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted! Thank you.')));
                }
              },
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('👤 Profile & Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const Text('Live Delivery Tracking & History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : myOrders.isEmpty
                        ? const Center(child: Text('No orders found.'))
                        : ListView.builder(
                            itemCount: myOrders.length,
                            itemBuilder: (context, index) {
                              final o = myOrders[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(o['order_number'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: o['status'] == 'completed' ? Colors.green.shade100 : Colors.orange.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            o['status'].toString().toUpperCase(),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Total: ₱${o['total_amount']}',
                                      style: const TextStyle(color: Color(0xFFE8411E), fontWeight: FontWeight.bold),
                                    ),
                                    if (o['status'] == 'completed') ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () => _showReviewDialog(o['id']),
                                          child: const Text('Leave a Review (5⭐)'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

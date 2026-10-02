import 'package:flutter/material.dart';

class OrderProgressStepper extends StatefulWidget {
  final String status;
  final Color brandColor;
  final bool showArrivedBanner;

  const OrderProgressStepper({
    super.key,
    required this.status,
    this.brandColor = const Color(0xFFF36F21),
    this.showArrivedBanner = true,
  });

  static const List<Map<String, dynamic>> stages = [
    {'title': 'Receipt Verified', 'icon': Icons.receipt_long},
    {'title': 'Preparing', 'icon': Icons.soup_kitchen},
    {'title': 'Out for Delivery', 'icon': Icons.delivery_dining},
    {'title': 'Rider Arrived', 'icon': Icons.pin_drop},
    {'title': 'Delivered', 'icon': Icons.check_circle},
  ];

  static int getStageIndex(String status) {
    switch (status.toUpperCase()) {
      case 'PREPARING':
        return 1;
      case 'OUT_FOR_DELIVERY':
      case 'DISPATCHED':
        return 2;
      case 'RIDER_ARRIVED':
        return 3;
      case 'DELIVERED':
      case 'COMPLETED':
        return 4;
      case 'PAYMENT_REJECTED':
      case 'REJECTED':
        return -1;
      case 'AWAITING_VERIFICATION':
      case 'PAYMENT_PENDING':
      case 'PENDING':
      default:
        return 0;
    }
  }

  @override
  State<OrderProgressStepper> createState() => _OrderProgressStepperState();
}

class _OrderProgressStepperState extends State<OrderProgressStepper>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStage = OrderProgressStepper.getStageIndex(widget.status);
    final isDelivered = widget.status.toUpperCase() == 'DELIVERED' ||
        widget.status.toUpperCase() == 'COMPLETED';
    final isRiderArrived = widget.status.toUpperCase() == 'RIDER_ARRIVED';
    final isRejected = widget.status.toUpperCase() == 'PAYMENT_REJECTED' ||
        widget.status.toUpperCase() == 'REJECTED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rejection Notice Banner
        if (isRejected) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF87171), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Receipt Rejected by Store Admin',
                        style: TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Food will NOT be prepared until a valid GCash receipt proof is provided.',
                        style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // High-Contrast Rider Arrived Banner
        if (widget.showArrivedBanner && isRiderArrived) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Your Lalamove rider has arrived outside! Please collect your order.',
                    style: TextStyle(
                      color: Color(0xFF78350F),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Horizontal Step Indicator
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 420;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(OrderProgressStepper.stages.length * 2 - 1, (index) {
                if (index.isOdd) {
                  // Connecting line
                  final lineIndex = index ~/ 2;
                  final isLineCompleted = currentStage > lineIndex;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 14),
                      height: 3,
                      decoration: BoxDecoration(
                        color: isLineCompleted
                            ? widget.brandColor
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }

                final stepIdx = index ~/ 2;
                final stage = OrderProgressStepper.stages[stepIdx];
                final isCompleted = currentStage > stepIdx || (isDelivered && stepIdx == 4);
                final isCurrent = currentStage == stepIdx && !isDelivered;

                Widget iconWidget = Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? widget.brandColor
                        : (isCurrent ? widget.brandColor.withValues(alpha: 0.15) : const Color(0xFFF1F5F9)),
                    border: Border.all(
                      color: (isCompleted || isCurrent)
                          ? widget.brandColor
                          : const Color(0xFFCBD5E1),
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: widget.brandColor.withValues(alpha: 0.35),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Icon(
                            stage['icon'] as IconData,
                            size: 15,
                            color: isCurrent
                                ? widget.brandColor
                                : const Color(0xFF94A3B8),
                          ),
                  ),
                );

                if (isCurrent) {
                  iconWidget = AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: iconWidget,
                  );
                }

                return SizedBox(
                  width: isCompact ? 56 : 72,
                  child: Column(
                    children: [
                      iconWidget,
                      const SizedBox(height: 6),
                      Text(
                        stage['title'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isCompact ? 9 : 10,
                          fontWeight: (isCurrent || isCompleted)
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: (isCurrent || isCompleted)
                              ? (isCurrent ? widget.brandColor : const Color(0xFF1E293B))
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

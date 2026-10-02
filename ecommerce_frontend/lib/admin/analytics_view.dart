import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String _selectedRange = 'Last 7 days';
  bool _isLoading = true;

  num _totalRevenue = 0;
  int _totalOrders = 0;
  List<String> _labels = [];
  List<num> _values = [];

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
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    String rangeKey = '7days';
    if (_selectedRange == 'Last 30 days') rangeKey = '30days';
    if (_selectedRange == 'Last 90 days') rangeKey = '90days';
    if (_selectedRange == 'Last 12 months') rangeKey = '12months';

    final data = await ApiService.getAdminAnalytics(range: rangeKey);

    if (mounted) {
      if (data.isNotEmpty) {
        final trend = data['trend'] ?? {};
        setState(() {
          _totalRevenue = data['total_revenue'] ?? 0;
          _totalOrders = data['total_orders'] ?? 0;
          _labels = List<String>.from(trend['labels'] ?? []);
          _values = List<num>.from(trend['values'] ?? []);
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
    final maxVal = _values.isNotEmpty
        ? _values.reduce((curr, next) => curr > next ? curr : next)
        : 1.0;
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Analytics',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live sales summary and revenue breakdown',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRange,
                    items: <String>[
                      'Last 7 days',
                      'Last 30 days',
                      'Last 90 days',
                      'Last 12 months'
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRange = val;
                        });
                        _fetchAnalytics();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Summary Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 700
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 48) / 3;
              final avgOrder = _totalOrders > 0 ? (_totalRevenue / _totalOrders) : 0;

              return Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Total Revenue',
                      _formatCurrency(_totalRevenue),
                      Icons.payments_outlined,
                      Colors.green.shade700,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Total Valid Orders',
                      '$_totalOrders orders',
                      Icons.shopping_bag_outlined,
                      Colors.blue.shade700,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _buildMetricCard(
                      'Avg. Order Value',
                      _formatCurrency(avgOrder),
                      Icons.analytics_outlined,
                      Colors.orange.shade700,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Revenue Chart Container
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
            child: _isLoading
                ? const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Revenue Trend',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Peak: ${_formatCurrency(maxVal)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_values.isEmpty)
                        const SizedBox(
                          height: 250,
                          child: Center(child: Text('No revenue data available.')),
                        )
                      else ...[
                        SizedBox(
                          height: 250,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(_values.length, (index) {
                              final val = _values[index];
                              final heightFactor = (val / effectiveMax).clamp(0.05, 1.0);
                              final height = heightFactor * 200;

                              return Expanded(
                                child: Tooltip(
                                  message: '${_labels[index]}: ${_formatCurrency(val)}',
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (val > 0)
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '₱${val.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 400),
                                          height: height,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context).colorScheme.primary,
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.4)
                                              ],
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                            ),
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: List.generate(_labels.length, (index) {
                            return Expanded(
                              child: Text(
                                _labels[index],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

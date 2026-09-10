import 'package:flutter/material.dart';

class ProductsView extends StatelessWidget {
  const ProductsView({super.key});

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
              const Text(
                'Product Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                _buildProductRow(context, 'Adobong Manok', 'Filipino', '₱89.00', '45 in stock', false),
                _buildProductRow(context, 'Sinigang na Baboy', 'Filipino', '₱130.00', 'Out of stock', true),
                _buildProductRow(context, 'Lechon Kawali', 'Filipino', '₱145.00', '12 in stock', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildProductRow(BuildContext context, String name, String category, String price, String stock, bool isOutOfStock) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          )
        ),
        DataCell(Text(category, style: const TextStyle(color: Colors.grey))),
        DataCell(Text(price)),
        DataCell(
          Text(stock, style: TextStyle(color: isOutOfStock ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
        ),
        DataCell(
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
            child: const Text('Edit'),
          ),
        ),
      ],
    );
  }
}

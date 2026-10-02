import 'package:shared_preferences/shared_preferences.dart';

class GuestOrderStorage {
  static const String _key = 'dasmabites_guest_orders';

  /// Retrieve all order numbers saved on this specific device
  static Future<List<String>> getStoredOrderNumbers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final list = prefs.getStringList(_key);
      if (list != null) {
        return List<String>.from(list);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Add a newly placed order number to this device's local storage
  static Future<void> saveOrderNumber(String orderNumber) async {
    final clean = orderNumber.trim();
    if (clean.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final existing = List<String>.from(prefs.getStringList(_key) ?? []);
      if (!existing.contains(clean)) {
        existing.insert(0, clean); // most recent first
        await prefs.setStringList(_key, existing);
      }
    } catch (_) {}
  }
}

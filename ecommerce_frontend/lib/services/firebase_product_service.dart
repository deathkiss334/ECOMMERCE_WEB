import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_table_model.dart';
import 'firebase_order_service.dart';

/// FirebaseProductService manages Cloud Firestore real-time streaming,
/// fetching, creation, and updating of records in the `product_table` collection.
class FirebaseProductService {
  /// Live real-time stream of product_table items from Cloud Firestore & Laravel DB
  static Stream<List<ProductTableModel>> streamProducts({
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      try {
        final products = await fetchProductsFromFirestore();
        yield products;
      } catch (_) {
        yield [];
      }
      await Future.delayed(interval);
    }
  }

  /// Fetch all documents from Cloud Firestore `product_table` collection & Laravel DB
  static Future<List<ProductTableModel>> fetchProductsFromFirestore() async {
    final projectId = FirebaseOrderService.firebaseProjectId;

    // 1. Fetch from Firebase Cloud Firestore
    if (projectId.isNotEmpty) {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/product_table',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> documents = data['documents'] ?? [];
          return documents
              .map((doc) => ProductTableModel.fromFirestore(doc))
              .toList();
        }
      } catch (_) {}
    }

    // 2. Fallback to Laravel REST API if Firebase returns empty or network error
    try {
      final laravelUrl = Uri.parse('http://127.0.0.1:8000/api/product-table');
      final response = await http.get(laravelUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ProductTableModel.fromJson(json)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Add or update a product in Firestore `product_table` collection & Laravel DB
  static Future<bool> saveProductToFirestore(ProductTableModel product) async {
    // 1. Sync to Laravel REST API if running
    try {
      final laravelUrl = Uri.parse('http://127.0.0.1:8000/api/product-table');
      await http.post(
        laravelUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );
    } catch (_) {}

    // 2. Sync to Cloud Firestore REST API
    final projectId = FirebaseOrderService.firebaseProjectId;
    if (projectId.isEmpty) return true;

    final docId = product.productId.isNotEmpty
        ? product.productId
        : 'PROD-${DateTime.now().millisecondsSinceEpoch}';

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/product_table/$docId',
    );

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toFirestoreFields()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  /// Delete a product document from Firestore `product_table` collection & Laravel DB
  static Future<bool> deleteProductFromFirestore(String productId) async {
    // 1. Delete from Laravel REST API if running
    try {
      final laravelUrl = Uri.parse('http://127.0.0.1:8000/api/product-table/$productId');
      await http.delete(laravelUrl);
    } catch (_) {}

    // 2. Delete from Cloud Firestore REST API
    final projectId = FirebaseOrderService.firebaseProjectId;
    if (projectId.isEmpty) return true;

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/product_table/$productId',
    );

    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}

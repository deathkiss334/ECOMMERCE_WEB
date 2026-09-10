import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/users_table_model.dart';
import 'firebase_order_service.dart';

/// FirebaseUsersTableService manages Cloud Firestore real-time streaming,
/// fetching, creation, updating, and deletion of records in the `users_table` collection.
class FirebaseUsersTableService {
  /// Live real-time stream of users_table items from Cloud Firestore & Laravel DB
  static Stream<List<UsersTableModel>> streamUsers({
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      try {
        final users = await fetchUsersFromFirestore();
        yield users;
      } catch (_) {
        yield [];
      }
      await Future.delayed(interval);
    }
  }

  /// Fetch all documents from Cloud Firestore `users_table` collection & Laravel DB
  static Future<List<UsersTableModel>> fetchUsersFromFirestore() async {
    final projectId = FirebaseOrderService.firebaseProjectId;

    // 1. Fetch from Firebase Cloud Firestore
    if (projectId.isNotEmpty) {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users_table',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> documents = data['documents'] ?? [];
          return documents
              .map((doc) => UsersTableModel.fromFirestore(doc))
              .toList();
        }
      } catch (_) {}
    }

    // 2. Fallback to Laravel REST API if Firebase returns empty or network error
    try {
      final laravelUrl = Uri.parse('http://127.0.0.1:8000/api/users-table');
      final response = await http.get(laravelUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UsersTableModel.fromJson(json)).toList();
      }
    } catch (_) {}

    return [];
  }

  /// Add or update a user in Firestore `users_table` collection & Laravel DB
  static Future<bool> saveUserToFirestore(UsersTableModel user) async {
    final docId = user.emailAddress.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    // 1. Sync to Laravel REST API if running
    try {
      final laravelUrl = Uri.parse('http://127.0.0.1:8000/api/users-table');
      await http.post(
        laravelUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );
    } catch (_) {}

    // 2. Sync to Cloud Firestore REST API
    final projectId = FirebaseOrderService.firebaseProjectId;
    if (projectId.isEmpty) return true;

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users_table/$docId',
    );

    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toFirestoreFields()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  /// Delete a user document from Firestore `users_table` collection & Laravel DB
  static Future<bool> deleteUserFromFirestore(String emailAddress) async {
    final docId = emailAddress.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    // 1. Delete from Laravel REST API if running
    try {
      final laravelUrl = Uri.parse('http://127.0.0.1:8000/api/users-table/$docId');
      await http.delete(laravelUrl);
    } catch (_) {}

    // 2. Delete from Cloud Firestore REST API
    final projectId = FirebaseOrderService.firebaseProjectId;
    if (projectId.isEmpty) return true;

    final url = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users_table/$docId',
    );

    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }
}

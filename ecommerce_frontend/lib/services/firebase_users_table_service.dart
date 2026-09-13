import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/users_table_model.dart';
import 'firebase_order_service.dart';
import 'firebase_user_service.dart';

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

  /// Fetch all documents from Cloud Firestore `users_table` & `users` collections & Laravel DB
  static Future<List<UsersTableModel>> fetchUsersFromFirestore() async {
    final Map<String, UsersTableModel> userMap = {};
    final projectId = FirebaseOrderService.firebaseProjectId;

    // 1. Fetch from Firebase Cloud Firestore `users_table` collection
    if (projectId.isNotEmpty) {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users_table',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> documents = data['documents'] ?? [];
          for (final doc in documents) {
            final model = UsersTableModel.fromFirestore(doc);
            if (model.emailAddress.isNotEmpty) {
              userMap[model.emailAddress.toLowerCase()] = model;
            }
          }
        }
      } catch (_) {}

      // 2. Fetch from Firebase Cloud Firestore `users` collection
      try {
        final usersUrl = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users',
        );
        final response = await http.get(usersUrl);
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> documents = data['documents'] ?? [];
          for (final doc in documents) {
            final model = UsersTableModel.fromFirestore(doc);
            if (model.emailAddress.isNotEmpty) {
              userMap.putIfAbsent(model.emailAddress.toLowerCase(), () => model);
            }
          }
        }
      } catch (_) {}
    }

    // 3. Sync/Fetch from Laravel REST API
    try {
      final laravelUrl = Uri.parse('http://127.0.0.1:8000/api/users-table');
      final response = await http.get(laravelUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (final jsonItem in data) {
          final model = UsersTableModel.fromJson(jsonItem);
          if (model.emailAddress.isNotEmpty) {
            userMap.putIfAbsent(model.emailAddress.toLowerCase(), () => model);
          }
        }
      }
    } catch (_) {}

    // 4. Include current active verified user if available
    final activeUser = FirebaseUserService.currentUser;
    if (activeUser.isVerified && activeUser.emailAddress.isNotEmpty && !activeUser.isAdmin) {
      final model = UsersTableModel(
        firstName: activeUser.firstName,
        middleName: activeUser.middleName,
        lastName: activeUser.secondName,
        birthday: activeUser.birthday,
        address: activeUser.address,
        emailAddress: activeUser.emailAddress,
        phoneNumber: activeUser.phoneNumber,
      );
      userMap.putIfAbsent(model.emailAddress.toLowerCase(), () => model);
    }

    return userMap.values.toList();
  }

  /// Add or update a user in Firestore `users_table` & `users` collections & Laravel DB
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

    // 2. Sync to Cloud Firestore REST API (`users_table` and `users` collections)
    final projectId = FirebaseOrderService.firebaseProjectId;
    if (projectId.isEmpty) return true;

    final usersTableUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users_table/$docId',
    );
    final usersUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$docId',
    );

    try {
      await http.patch(
        usersTableUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toFirestoreFields()),
      );
    } catch (_) {}

    try {
      final userFieldsPayload = {
        'fields': {
          'first_name': {'stringValue': user.firstName},
          'second_name': {'stringValue': user.lastName},
          'middle_name': {'stringValue': user.middleName},
          'birthday': {'stringValue': user.birthday},
          'address': {'stringValue': user.address},
          'phone_number': {'stringValue': user.phoneNumber},
          'email_address': {'stringValue': user.emailAddress},
          'is_verified': {'booleanValue': true},
        }
      };

      await http.patch(
        usersUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userFieldsPayload),
      );
    } catch (_) {}

    return true;
  }

  /// Delete a user document from Firestore `users_table` & `users` collections & Laravel DB
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

    final usersTableUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users_table/$docId',
    );
    final usersUrl = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$docId',
    );

    try {
      await http.delete(usersTableUrl);
      await http.delete(usersUrl);
      return true;
    } catch (_) {
      return true;
    }
  }
}


import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/users_table_model.dart';
import 'api_service.dart';
import 'firebase_user_service.dart';

/// UsersTableService manages real-time streaming, fetching, creation,
/// updating, and deletion of records in `users_table` directly via Laravel SQLite.
class FirebaseUsersTableService {
  /// Live real-time stream of users_table items from Laravel DB (polls every 4s)
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

  /// Fetch all users directly from Laravel DB + active session
  static Future<List<UsersTableModel>> fetchUsersFromFirestore() async {
    final Map<String, UsersTableModel> userMap = {};

    // 1. Fetch from Laravel REST API
    try {
      final laravelUrl = Uri.parse('${ApiService.baseUrl}/users-table');
      final response = await http.get(laravelUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (final jsonItem in data) {
          final model = UsersTableModel.fromJson(jsonItem);
          if (model.emailAddress.isNotEmpty) {
            userMap[model.emailAddress.toLowerCase()] = model;
          }
        }
      }
    } catch (_) {}

    // 2. Include current active verified user if available
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

  /// Add or update a user in Laravel DB
  static Future<bool> saveUserToFirestore(UsersTableModel user) async {
    try {
      final laravelUrl = Uri.parse('${ApiService.baseUrl}/users-table');
      final response = await http.post(
        laravelUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Delete a user from Laravel DB
  static Future<bool> deleteUserFromFirestore(String emailAddress) async {
    final docId = emailAddress.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    try {
      final laravelUrl = Uri.parse('${ApiService.baseUrl}/users-table/$docId');
      final response = await http.delete(laravelUrl);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

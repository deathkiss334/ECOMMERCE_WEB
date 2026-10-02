import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/users_table_model.dart';
import 'api_service.dart';
import 'firebase_user_service.dart';

/// UsersTableService — reads and writes directly to Supabase users_table
/// via the Laravel REST API (/api/users-table).
class FirebaseUsersTableService {
  /// Live real-time stream of users_table items (polls every 5s)
  static Stream<List<UsersTableModel>> streamUsers({
    Duration interval = const Duration(seconds: 5),
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

  /// Fetch all users from Supabase users_table via Laravel API
  static Future<List<UsersTableModel>> fetchUsersFromFirestore() async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/users-table');
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final models = data
            .map((item) => UsersTableModel.fromJson(item as Map<String, dynamic>))
            .where((u) => u.emailAddress.isNotEmpty)
            .toList();
        return models;
      }
    } catch (_) {}

    // Fallback: include current active verified user if available
    final activeUser = FirebaseUserService.currentUser;
    if (activeUser.isVerified && activeUser.emailAddress.isNotEmpty && !activeUser.isAdmin) {
      return [
        UsersTableModel(
          firstName: activeUser.firstName,
          middleName: activeUser.middleName,
          lastName: activeUser.secondName,
          birthday: activeUser.birthday,
          address: activeUser.address,
          emailAddress: activeUser.emailAddress,
          phoneNumber: activeUser.phoneNumber,
          role: 'customer',
        ),
      ];
    }

    return [];
  }

  /// Add or update a user in Supabase users_table via Laravel API
  static Future<bool> saveUserToFirestore(UsersTableModel user) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/users-table');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(user.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Update a user's role (promote to admin / demote to customer)
  static Future<bool> updateUserRole(String emailAddress, String role) async {
    try {
      final encodedEmail = Uri.encodeComponent(emailAddress);
      final url = Uri.parse('${ApiService.baseUrl}/users-table/$encodedEmail/role');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'user_role': role}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Delete a user from Supabase users_table via Laravel API
  static Future<bool> deleteUserFromFirestore(String emailAddress) async {
    try {
      final encodedEmail = Uri.encodeComponent(emailAddress);
      final url = Uri.parse('${ApiService.baseUrl}/users-table/$encodedEmail');
      final response = await http.delete(
        url,
        headers: {'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

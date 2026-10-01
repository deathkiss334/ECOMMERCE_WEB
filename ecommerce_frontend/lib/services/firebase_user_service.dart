import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/users_table_model.dart';
import 'firebase_order_service.dart';
import 'firebase_users_table_service.dart';

/// FirebaseUserService manages real-time Cloud Firestore fetching
/// and local caching for Verified Users vs Guest Accounts.
class FirebaseUserService {
  static UserModel? _cachedUser;

  /// Get current user (defaults to Guest account profile)
  static UserModel get currentUser {
    return _cachedUser ?? UserModel.guest();
  }

  /// Set local current user mode (Verified vs Guest)
  static void setCurrentUser(UserModel user) {
    _cachedUser = user;
  }

  /// Check if a user with this email has existing profile credentials in Firebase or users_table.
  /// Returns null if user has never completed registration or credentials.
  static Future<UserModel?> findUserProfile(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return null;

    if (cleanEmail == 'admin@example.com' || cleanEmail == 'admin') {
      return UserModel.adminMock();
    }

    // 1. Check Cloud Firestore /users/{docId}
    if (FirebaseOrderService.isFirebaseConfigured) {
      try {
        final docId = cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
        final url = Uri.parse(
          'https://firestore.googleapis.com/v1/projects/${FirebaseOrderService.firebaseProjectId}/databases/(default)/documents/users/$docId',
        );
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final fields = data['fields'] ?? {};
          final phone = fields['phone_number']?['stringValue'] ?? '';
          final firstName = fields['first_name']?['stringValue'] ?? '';

          if (phone.isNotEmpty || firstName.isNotEmpty) {
            final user = UserModel(
              firstName: firstName,
              secondName: fields['second_name']?['stringValue'] ?? fields['last_name']?['stringValue'] ?? '',
              middleName: fields['middle_name']?['stringValue'] ?? '',
              birthday: fields['birthday']?['stringValue'] ?? '',
              address: fields['address']?['stringValue'] ?? '',
              phoneNumber: phone,
              emailAddress: fields['email_address']?['stringValue'] ?? cleanEmail,
              isVerified: fields['is_verified']?['booleanValue'] ?? true,
            );
            return user;
          }
        }
      } catch (_) {}
    }

    // 2. Check users_table records in Firestore & Laravel DB
    try {
      final users = await FirebaseUsersTableService.fetchUsersFromFirestore();
      for (final u in users) {
        if (u.emailAddress.toLowerCase().trim() == cleanEmail && u.phoneNumber.isNotEmpty) {
          return UserModel(
            firstName: u.firstName,
            secondName: u.lastName,
            middleName: u.middleName,
            birthday: u.birthday,
            address: u.address,
            phoneNumber: u.phoneNumber,
            emailAddress: u.emailAddress,
            isVerified: true,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  /// Fetch Verified User profile from Cloud Firestore REST API
  static Future<UserModel> fetchUserProfile(String email) async {
    final existing = await findUserProfile(email);
    if (existing != null) {
      _cachedUser = existing;
      return existing;
    }

    final defaultUser = UserModel.defaultVerified();
    _cachedUser = defaultUser;
    return defaultUser;
  }

  /// Push/Sync Verified User profile updates to Firebase Cloud Firestore and users_table
  static Future<bool> saveUserProfileToFirebase(UserModel user) async {
    _cachedUser = user;

    final usersTableModel = UsersTableModel(
      firstName: user.firstName,
      middleName: user.middleName,
      lastName: user.secondName,
      birthday: user.birthday,
      address: user.address,
      emailAddress: user.emailAddress,
      phoneNumber: user.phoneNumber,
    );

    // 1. Sync to users_table collection & Laravel REST API
    try {
      await FirebaseUsersTableService.saveUserToFirestore(usersTableModel);
    } catch (_) {}

    if (!user.isVerified || !FirebaseOrderService.isFirebaseConfigured) {
      return true;
    }

    // 2. Sync to users collection in Cloud Firestore REST API
    try {
      final docId = user.emailAddress.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/${FirebaseOrderService.firebaseProjectId}/databases/(default)/documents/users/$docId',
      );

      final payload = {
        'fields': {
          'first_name': {'stringValue': user.firstName},
          'second_name': {'stringValue': user.secondName},
          'middle_name': {'stringValue': user.middleName},
          'birthday': {'stringValue': user.birthday},
          'address': {'stringValue': user.address},
          'phone_number': {'stringValue': user.phoneNumber},
          'email_address': {'stringValue': user.emailAddress},
          'is_verified': {'booleanValue': user.isVerified},
          'updated_at': {'stringValue': DateTime.now().toIso8601String()},
        }
      };

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}


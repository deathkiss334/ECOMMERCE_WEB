import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'firebase_order_service.dart';

/// FirebaseUserService manages real-time Cloud Firestore fetching
/// and local caching for Verified Users vs Guest Accounts.
class FirebaseUserService {
  static UserModel? _cachedUser;

  /// Get current user (defaults to Verified User demo profile)
  static UserModel get currentUser {
    return _cachedUser ?? UserModel.defaultVerified();
  }

  /// Set local current user mode (Verified vs Guest)
  static void setCurrentUser(UserModel user) {
    _cachedUser = user;
  }

  /// Fetch Verified User profile from Cloud Firestore REST API
  static Future<UserModel> fetchUserProfile(String email) async {
    if (email.toLowerCase() == 'admin@example.com' || email.toLowerCase() == 'admin') {
      final adminUser = UserModel.adminMock();
      _cachedUser = adminUser;
      return adminUser;
    }

    if (!FirebaseOrderService.isFirebaseConfigured) {
      return UserModel.defaultVerified();
    }

    try {
      final docId = email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/${FirebaseOrderService.firebaseProjectId}/databases/(default)/documents/users/$docId',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final fields = data['fields'] ?? {};

        final user = UserModel(
          firstName: fields['first_name']?['stringValue'] ?? '',
          secondName: fields['second_name']?['stringValue'] ?? '',
          middleName: fields['middle_name']?['stringValue'] ?? '',
          birthday: fields['birthday']?['stringValue'] ?? '',
          address: fields['address']?['stringValue'] ?? '',
          phoneNumber: fields['phone_number']?['stringValue'] ?? '',
          emailAddress: fields['email_address']?['stringValue'] ?? '',
          isVerified: fields['is_verified']?['booleanValue'] ?? true,
        );

        _cachedUser = user;
        return user;
      }
    } catch (_) {}

    return UserModel.defaultVerified();
  }

  /// Push/Sync Verified User profile updates to Firebase Cloud Firestore
  static Future<bool> saveUserProfileToFirebase(UserModel user) async {
    _cachedUser = user;

    if (!user.isVerified || !FirebaseOrderService.isFirebaseConfigured) {
      return true;
    }

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

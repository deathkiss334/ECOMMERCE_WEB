import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firebase_user_service.dart';
import 'guest_order_storage.dart';

class AuthResult {
  final String token;
  final UserModel user;
  final String role;
  final bool needsProfileCompletion;

  AuthResult({
    required this.token,
    required this.user,
    required this.role,
    this.needsProfileCompletion = false,
  });
}

class AuthApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const String _tokenPrefKey = 'dasmabites_auth_token';
  static const String _userPrefKey = 'dasmabites_auth_user';

  static String? _authToken;

  /// Returns active auth token
  static String? get authToken => _authToken;

  /// Check if an authenticated session exists
  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Set the active token manually
  static void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Save session to persistent storage
  static Future<void> saveSession(String token, UserModel user) async {
    _authToken = token;
    FirebaseUserService.setCurrentUser(user);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenPrefKey, token);
      await prefs.setString(_userPrefKey, json.encode(user.toJson()));
    } catch (_) {}
  }

  /// Restore user session across browser refresh (F5)
  static Future<UserModel?> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenPrefKey);
      final userJsonStr = prefs.getString(_userPrefKey);

      if (token != null && token.isNotEmpty && userJsonStr != null && userJsonStr.isNotEmpty) {
        final userData = json.decode(userJsonStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);
        _authToken = token;
        FirebaseUserService.setCurrentUser(user);
        return user;
      }
    } catch (_) {}
    return null;
  }

  /// Clear persistent session on logout
  static Future<void> clearSession() async {
    _authToken = null;
    FirebaseUserService.setCurrentUser(UserModel.guest());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenPrefKey);
      await prefs.remove(_userPrefKey);
    } catch (_) {}
  }

  /// Sign Up / Register new customer in SQLite backend
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'phone': phone?.trim(),
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 201) {
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromBackendJson(userData);

      await saveSession(token, user);

      return AuthResult(
        token: token,
        user: user,
        role: userData['role'] ?? 'customer',
      );
    } else if (response.statusCode == 409) {
      throw Exception(data['message'] ?? 'Email is already registered. Please log in.');
    } else if (response.statusCode == 422) {
      final errors = data['errors'] as Map<String, dynamic>?;
      if (errors != null && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
      }
      throw Exception(data['message'] ?? 'Validation failed. Please verify your details.');
    } else {
      throw Exception(data['message'] ?? 'Registration failed (${response.statusCode})');
    }
  }

  /// Log In with email and password
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode({
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromBackendJson(userData);

      await saveSession(token, user);

      return AuthResult(
        token: token,
        user: user,
        role: userData['role'] ?? 'customer',
      );
    } else if (response.statusCode == 401) {
      throw Exception(data['message'] ?? 'Invalid email or password.');
    } else {
      throw Exception(data['message'] ?? 'Login failed (${response.statusCode})');
    }
  }

  /// Google OAuth 2.0 Sign In (Zero Firebase)
  static Future<AuthResult> loginWithGoogle(
    String idToken, {
    String? email,
    String? name,
    String? avatar,
    String? address,
    String? phone,
    String? firstName,
    String? lastName,
  }) async {
    final body = <String, dynamic>{
      'id_token': idToken,
    };
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (avatar != null && avatar.isNotEmpty) body['avatar'] = avatar;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (firstName != null && firstName.isNotEmpty) body['first_name'] = firstName;
    if (lastName != null && lastName.isNotEmpty) body['last_name'] = lastName;

    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: json.encode(body),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = data['token'] as String;
      final userData = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromBackendJson(userData);

      await saveSession(token, user);

      return AuthResult(
        token: token,
        user: user,
        role: userData['role'] ?? 'customer',
        needsProfileCompletion: userData['needs_profile_completion'] == true,
      );
    } else {
      throw Exception(data['message'] ?? 'Google authentication failed.');
    }
  }

  /// Get Logged-in User Profile
  static Future<UserModel> getProfile() async {
    if (_authToken == null) {
      throw Exception('Unauthenticated. Please log in.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final user = UserModel.fromBackendJson(data['user']);
      FirebaseUserService.setCurrentUser(user);
      return user;
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }

  /// Update Logged-in User Profile
  static Future<UserModel> updateProfile({
    required String name,
    String? phone,
  }) async {
    if (_authToken == null) {
      throw Exception('Unauthenticated. Please log in.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
      body: json.encode({
        'name': name.trim(),
        'phone': phone?.trim(),
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200) {
      final user = UserModel.fromBackendJson(data['user']);
      FirebaseUserService.setCurrentUser(user);
      return user;
    } else {
      throw Exception(data['message'] ?? 'Failed to update profile.');
    }
  }

  /// Change Password for local accounts
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    if (_authToken == null) {
      throw Exception('Unauthenticated. Please log in.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/user/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_authToken',
      },
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to update password.');
    }
  }

  /// Log out from session
  static Future<void> logout() async {
    if (_authToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $_authToken',
          },
        );
      } catch (_) {}
    }

    await clearSession();
    await GuestOrderStorage.clear();
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// CustomerAuthService
///
/// Handles:
///  1. Real Google Sign-In with account-chooser (official SDK)
///  2. Sending the idToken to the Laravel backend for verification
///  3. Persisting the returned Sanctum bearer token
///  4. Providing helper getters for the currently signed-in customer
class CustomerAuthService {
  // ─── Web OAuth Client ID ───────────────────────────────────────────────────
  static const _webClientId =
      '183407974320-i03p84v2n4320tr17sbsvtubdcdphnor.apps.googleusercontent.com';

  // ─── Laravel backend base URL ──────────────────────────────────────────────
  static const _baseUrl = 'http://127.0.0.1:8000';

  // ─── SharedPreferences keys ────────────────────────────────────────────────
  static const _keyToken    = 'customer_sanctum_token';
  static const _keyUserId   = 'customer_user_id';
  static const _keyUserName = 'customer_user_name';
  static const _keyEmail    = 'customer_email';
  static const _keyAvatar   = 'customer_avatar';
  static const _keyRole     = 'customer_role';

  // ─── Singleton GoogleSignIn instance ──────────────────────────────────────
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: _webClientId,
    scopes: const ['email', 'profile'],
  );

  // ──────────────────────────────────────────────────────────────────────────
  //  PUBLIC API
  // ──────────────────────────────────────────────────────────────────────────

  /// Initiates the Google Sign-In flow (real account chooser) and
  /// authenticates with the Laravel backend via ID token.
  ///
  /// Returns a map with keys: id, name, email, avatar, role, token
  /// or throws an [Exception] describing what went wrong.
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    // ── Step 1: Force sign-out to always show account chooser ──────────────
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore signOut errors if not already signed in
    }

    // ── Step 2: Trigger the real Google Account Chooser ────────────────────
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('sign_in_cancelled');
    }

    // ── Step 3: Get authentication tokens ─────────────────────────────────
    String? idToken;
    String? accessToken;

    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      idToken = googleAuth.idToken;
      accessToken = googleAuth.accessToken;
    } catch (e) {
      debugPrint('[CustomerAuth] Error getting authentication tokens: $e');
    }

    debugPrint(
      '[CustomerAuth] User: ${googleUser.email}, '
      'idToken: ${idToken != null ? "${idToken.length} chars" : "null"}, '
      'accessToken: ${accessToken != null ? "${accessToken.length} chars" : "null"}',
    );

    // ── Step 4: Send tokens & profile to Laravel backend ───────────────────
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/google'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id_token': idToken,
        'access_token': accessToken,
        'email': googleUser.email,
        'name': googleUser.displayName,
        'avatar': googleUser.photoUrl,
        'google_id': googleUser.id,
      }),
    );

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (response.statusCode != 200 || body['status'] != 'success') {
      final msg = body['message'] ?? 'Backend authentication failed';
      throw Exception(msg);
    }

    // ── Step 5: Persist token & user info ─────────────────────────────────
    final user  = body['user']  as Map<String, dynamic>;
    final token = body['token'] as String;

    await _persist(token: token, user: user);

    return {'token': token, ...user};
  }

  /// Signs the customer out (revokes Sanctum token from backend + clears local storage)
  static Future<void> signOut() async {
    final token = await getToken();
    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/api/customer/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } catch (_) {
        // Ignore network errors on logout
      }
    }
    await _googleSignIn.signOut();
    await _clearLocalStorage();
  }

  /// Returns the persisted Sanctum bearer token (null if not signed in)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Returns the persisted customer profile as a map (null if not signed in)
  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return null;
    return {
      'id':     prefs.getInt(_keyUserId),
      'name':   prefs.getString(_keyUserName),
      'email':  prefs.getString(_keyEmail),
      'avatar': prefs.getString(_keyAvatar),
      'role':   prefs.getString(_keyRole),
      'token':  token,
    };
  }

  /// Returns true if the customer has a stored token
  static Future<bool> isSignedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> _persist({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken,    token);
    await prefs.setInt(_keyUserId,       (user['id'] as num).toInt());
    await prefs.setString(_keyUserName,  user['name']   ?? '');
    await prefs.setString(_keyEmail,     user['email']  ?? '');
    await prefs.setString(_keyAvatar,    user['avatar'] ?? '');
    await prefs.setString(_keyRole,      user['role']   ?? 'customer');
  }

  static Future<void> _clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      _keyToken, _keyUserId, _keyUserName, _keyEmail, _keyAvatar, _keyRole,
    ]) {
      await prefs.remove(key);
    }
  }
}

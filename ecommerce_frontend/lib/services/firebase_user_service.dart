import '../models/user_model.dart';
import '../models/users_table_model.dart';
import 'firebase_users_table_service.dart';

/// UserService manages authenticated vs guest account profiles
/// and persists customer updates directly into SQLite via Laravel REST API.
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

  /// Check if a user with this email has existing profile credentials in users_table.
  /// Returns null if user has never completed registration.
  static Future<UserModel?> findUserProfile(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty) return null;

    if (cleanEmail == 'admin@example.com' || cleanEmail == 'admin') {
      return UserModel.adminMock();
    }

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

  /// Fetch Verified User profile from Laravel DB
  static Future<UserModel> fetchUserProfile(String email) async {
    if (email.toLowerCase() == 'admin@example.com' || email.toLowerCase() == 'admin') {
      final adminUser = UserModel.adminMock();
      _cachedUser = adminUser;
      return adminUser;
    }

    final existing = await findUserProfile(email);
    if (existing != null) {
      _cachedUser = existing;
      return existing;
    }

    final defaultUser = UserModel.defaultVerified();
    _cachedUser = defaultUser;
    return defaultUser;
  }

  /// Push/Sync Verified User profile updates to users_table in Laravel SQLite
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

    try {
      return await FirebaseUsersTableService.saveUserToFirestore(usersTableModel);
    } catch (_) {
      return false;
    }
  }
}

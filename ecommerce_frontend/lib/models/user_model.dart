class UserModel {
  final String firstName;
  final String secondName; // Last name
  final String middleName;
  final String birthday;
  final String address;
  final String phoneNumber;
  final String emailAddress;
  final bool isVerified;
  final bool isAdmin;
  final String? authProvider;

  UserModel({
    required this.firstName,
    required this.secondName,
    required this.middleName,
    required this.birthday,
    required this.address,
    required this.phoneNumber,
    required this.emailAddress,
    this.isVerified = true,
    this.isAdmin = false,
    this.authProvider = 'local',
  });

  /// Factory to construct empty Guest account profile
  factory UserModel.guest() {
    return UserModel(
      firstName: '',
      secondName: '',
      middleName: '',
      birthday: '',
      address: '',
      phoneNumber: '',
      emailAddress: '',
      isVerified: false,
      isAdmin: false,
      authProvider: null,
    );
  }

  /// Construct default Verified User profile
  factory UserModel.defaultVerified() {
    return UserModel(
      firstName: 'Juan',
      secondName: 'Dela Cruz',
      middleName: 'Santos',
      birthday: '1998-05-15',
      address: '123 Governor Drive, Dasmariñas, Cavite',
      phoneNumber: '09123456789',
      emailAddress: 'juan.delacruz@example.com',
      isVerified: true,
      isAdmin: false,
      authProvider: 'local',
    );
  }

  /// Construct temporary Admin Mock profile
  factory UserModel.adminMock() {
    return UserModel(
      firstName: 'Admin',
      secondName: 'System',
      middleName: 'Owner',
      birthday: '1990-01-01',
      address: 'Storehouse Admin HQ, Dasmariñas, Cavite',
      phoneNumber: '09990001111',
      emailAddress: 'admin@example.com',
      isVerified: true,
      isAdmin: true,
      authProvider: 'local',
    );
  }

  /// Parse user profile returned from Laravel SQLite Auth API
  factory UserModel.fromBackendJson(Map<String, dynamic> json) {
    final name = (json['name'] ?? '').toString().trim();
    final parts = name.split(' ');
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final role = json['role'] ?? 'customer';

    return UserModel(
      firstName: first,
      secondName: last,
      middleName: '',
      birthday: '',
      address: '',
      phoneNumber: json['phone'] ?? '',
      emailAddress: json['email'] ?? '',
      isVerified: true,
      isAdmin: role == 'admin',
      authProvider: json['auth_provider'] ?? 'local',
    );
  }

  String get fullName {
    if (!isVerified) return 'Guest Account';
    final parts = [firstName, middleName, secondName].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'Verified User' : parts.join(' ');
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      firstName: json['first_name'] ?? '',
      secondName: json['second_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      birthday: json['birthday'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      emailAddress: json['email_address'] ?? '',
      isVerified: json['is_verified'] ?? true,
      isAdmin: json['is_admin'] ?? false,
      authProvider: json['auth_provider'] ?? 'local',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'second_name': secondName,
      'middle_name': middleName,
      'birthday': birthday,
      'address': address,
      'phone_number': phoneNumber,
      'email_address': emailAddress,
      'is_verified': isVerified,
      'is_admin': isAdmin,
      'auth_provider': authProvider,
    };
  }
}

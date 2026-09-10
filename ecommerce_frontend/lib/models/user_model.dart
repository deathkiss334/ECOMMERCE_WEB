class UserModel {
  final String firstName;
  final String secondName; // Last name
  final String middleName;
  final String birthday;
  final String address;
  final String phoneNumber;
  final String emailAddress;
  final bool isVerified;

  UserModel({
    required this.firstName,
    required this.secondName,
    required this.middleName,
    required this.birthday,
    required this.address,
    required this.phoneNumber,
    required this.emailAddress,
    this.isVerified = true,
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
    };
  }
}

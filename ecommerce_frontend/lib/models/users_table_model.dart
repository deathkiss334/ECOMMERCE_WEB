class UsersTableModel {
  final String firstName;
  final String middleName;
  final String lastName;
  final String birthday;
  final String address;
  final String emailAddress;
  final String phoneNumber;

  UsersTableModel({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.birthday,
    required this.address,
    required this.emailAddress,
    required this.phoneNumber,
  });

  String get fullName {
    final parts = [firstName, middleName, lastName].where((p) => p.isNotEmpty);
    return parts.isEmpty ? 'User' : parts.join(' ');
  }

  /// Create model from standard JSON map
  factory UsersTableModel.fromJson(Map<String, dynamic> json) {
    return UsersTableModel(
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? json['second_name']?.toString() ?? '',
      birthday: json['birthday']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      emailAddress: json['email_address']?.toString() ?? json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }

  /// Convert model to standard JSON map
  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'birthday': birthday,
      'address': address,
      'email_address': emailAddress,
      'phone_number': phoneNumber,
    };
  }

  /// Create model from Firestore REST API document format
  factory UsersTableModel.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] ?? {};
    final namePath = doc['name']?.toString() ?? '';
    final docId = namePath.split('/').last;

    return UsersTableModel(
      firstName: fields['first_name']?['stringValue'] ?? '',
      middleName: fields['middle_name']?['stringValue'] ?? '',
      lastName: fields['last_name']?['stringValue'] ?? fields['second_name']?['stringValue'] ?? '',
      birthday: fields['birthday']?['stringValue'] ?? '',
      address: fields['address']?['stringValue'] ?? '',
      emailAddress: fields['email_address']?['stringValue'] ?? docId,
      phoneNumber: fields['phone_number']?['stringValue'] ?? '',
    );
  }

  /// Convert to Firestore REST API payload fields format
  Map<String, dynamic> toFirestoreFields() {
    return {
      'fields': {
        'first_name': {'stringValue': firstName},
        'middle_name': {'stringValue': middleName},
        'last_name': {'stringValue': lastName},
        'birthday': {'stringValue': birthday},
        'address': {'stringValue': address},
        'email_address': {'stringValue': emailAddress},
        'phone_number': {'stringValue': phoneNumber},
      }
    };
  }
}

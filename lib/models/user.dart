class User {
  final String id;
  final String email;
  final String fullName;
  final String phone;


  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      phone: json['phone'] ?? json['PhoneNumber'] ?? '',
    );
  }
}


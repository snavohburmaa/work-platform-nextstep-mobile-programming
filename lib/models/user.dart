// User model to store user information
class User {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String bio;
  final String location;
  final String profileImage;
  final List<String> skills;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.bio = '',
    this.location = '',
    this.profileImage = '',
    this.skills = const [],
  });

  // Convert user to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'bio': bio,
      'location': location,
      'profileImage': profileImage,
      'skills': skills,
    };
  }

  // Create user from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      bio: json['bio'] ?? '',
      location: json['location'] ?? '',
      profileImage: json['profileImage'] ?? '',
      skills: json['skills'] != null ? List<String>.from(json['skills']) : [],
    );
  }
}


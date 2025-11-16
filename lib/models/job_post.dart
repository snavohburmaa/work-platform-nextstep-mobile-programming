// Job Post model for jobs created by users
class JobPost {
  final String id;
  final String userId; // Owner of the job post
  final String userName;
  final String userEmail;
  final String title;
  final String company;
  final String description;
  final String location;
  final String jobType; // Full-time, Part-time, Remote, etc.
  final String salary;
  final List<String> requirements;
  final DateTime createdAt;
  final List<String> applicants; // List of user IDs who applied

  JobPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.jobType,
    required this.salary,
    this.requirements = const [],
    required this.createdAt,
    this.applicants = const [],
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'title': title,
      'company': company,
      'description': description,
      'location': location,
      'jobType': jobType,
      'salary': salary,
      'requirements': requirements,
      'createdAt': createdAt.toIso8601String(),
      'applicants': applicants,
    };
  }

  // Create from JSON
  factory JobPost.fromJson(Map<String, dynamic> json) {
    return JobPost(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      title: json['title'] ?? '',
      company: json['company'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      jobType: json['jobType'] ?? '',
      salary: json['salary'] ?? '',
      requirements: json['requirements'] != null
          ? List<String>.from(json['requirements'])
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      applicants: json['applicants'] != null
          ? List<String>.from(json['applicants'])
          : [],
    );
  }
}


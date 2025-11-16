// Application model for job applications
class Application {
  final String id;
  final String jobId;
  final String jobTitle;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String message;
  final DateTime appliedAt;
  final String status; // pending, accepted, rejected

  Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.message,
    required this.appliedAt,
    this.status = 'pending',
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'message': message,
      'appliedAt': appliedAt.toIso8601String(),
      'status': status,
    };
  }

  // Create from JSON
  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      applicantId: json['applicantId'] ?? '',
      applicantName: json['applicantName'] ?? '',
      applicantEmail: json['applicantEmail'] ?? '',
      message: json['message'] ?? '',
      appliedAt: json['appliedAt'] != null
          ? DateTime.parse(json['appliedAt'])
          : DateTime.now(),
      status: json['status'] ?? 'pending',
    );
  }
}


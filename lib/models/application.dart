class Application {
  final String id;
  final String jobId;
  final String postId;
  final String jobTitle;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String message;
  final DateTime appliedAt;

  Application({
    required this.id,
    required this.jobId,
    this.postId = '',
    required this.jobTitle,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    this.message = '',
    required this.appliedAt,
  });

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
    };
  }

  factory Application.fromJson(Map<String, dynamic> json) {
    final appId = json['id']?.toString() ?? json['ApplicationID']?.toString() ?? '';
    final postId = json['postId']?.toString() ?? json['PostID']?.toString() ?? '';
    final jobId = json['jobId']?.toString() ?? json['JobID']?.toString() ?? postId;
    final applicantId = json['applicantId']?.toString() ?? json['ApplicantID']?.toString() ?? '';
    final jobTitle = json['jobTitle'] ?? json['JobTitle'] ?? json['PostTitle'] ?? '';
    final applicantName = json['applicantName'] ?? '';
    final applicantEmail = json['applicantEmail'] ?? json['Email'] ?? '';
    final dateApplied = json['appliedAt'] ?? json['DateApplied'] ?? json['dateApplied'];

    DateTime appliedAtDate;
    if (dateApplied != null) {
      if (dateApplied is String) {
        appliedAtDate = DateTime.parse(dateApplied);
      } else if (dateApplied is DateTime) {
        appliedAtDate = dateApplied;
      } else {
        appliedAtDate = DateTime.now();
      }
    } else {
      appliedAtDate = DateTime.now();
    }

    return Application(
      id: appId,
      jobId: jobId,
      postId: postId,
      jobTitle: jobTitle,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      message: json['message'] ?? '',
      appliedAt: appliedAtDate,
    );
  }
}


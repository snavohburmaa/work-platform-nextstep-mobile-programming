class JobPost {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String title;
  final String company;
  final String description;
  final String location;
  final String jobType;
  final String salary;
  final double? salaryMin;
  final double? salaryMax;
  final List<String> requirements;
  final DateTime createdAt;
  final List<String> applicants;

  JobPost({
    required this.id,
    this.userId = '',
    this.userName = '',
    this.userEmail = '',
    required this.title,
    required this.company,
    required this.description,
    required this.location,
    required this.jobType,
    required this.salary,
    this.salaryMin,
    this.salaryMax,
    this.requirements = const [],
    required this.createdAt,
    this.applicants = const [],
  });

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

  factory JobPost.fromJson(Map<String, dynamic> json) {
    final jobId = json['id']?.toString() ?? json['JobID']?.toString() ?? '';
    final jobTitle = json['title'] ?? json['Title'] ?? '';
    final companyName = json['company'] ?? json['CompanyName'] ?? '';
    final jobLocation = json['location'] ?? json['Location'] ?? '';
    final employmentType = json['jobType'] ?? json['EmploymentType'] ?? '';
    final jobDescription = json['description'] ?? json['Description'] ?? '';
    final postedDate = json['createdAt'] ?? json['PostedDate'] ?? json['postedDate'];
    
    DateTime createdAt;
    if (postedDate != null) {
      if (postedDate is String) {
        createdAt = DateTime.parse(postedDate);
      } else if (postedDate is DateTime) {
        createdAt = postedDate;
      } else {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    final min = json['salaryMin'] ?? json['SalaryMin'];
    final max = json['salaryMax'] ?? json['SalaryMax'];
    final salaryStr = json['salary'] ?? '';
    
    String salaryText = salaryStr;
    if (salaryStr.isEmpty && min != null && max != null) {
      salaryText = '\$$min - \$$max';
    } else if (salaryStr.isEmpty && min != null) {
      salaryText = '\$$min+';
    } else if (salaryStr.isEmpty) {
      salaryText = 'Not specified';
    }

    return JobPost(
      id: jobId,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      title: jobTitle,
      company: companyName,
      description: jobDescription,
      location: jobLocation,
      jobType: employmentType,
      salary: salaryText,
      salaryMin: min != null ? (min is double ? min : double.tryParse(min.toString())) : null,
      salaryMax: max != null ? (max is double ? max : double.tryParse(max.toString())) : null,
      requirements: json['requirements'] != null
          ? List<String>.from(json['requirements'])
          : [],
      createdAt: createdAt,
      applicants: json['applicants'] != null
          ? List<String>.from(json['applicants'])
          : [],
    );
  }
}


import 'dart:convert'; 
import 'package:http/http.dart' as http; 
import 'package:shared_preferences/shared_preferences.dart';  
import '../constants/api_config.dart';  
import '../models/user.dart';  
import '../models/job_post.dart';  
import '../models/application.dart';  

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<dynamic> _makeRequest(
    String method,  
    String endpoint,  
    {
    Map<String, dynamic>? body,  
    Map<String, String>? headers,  
  }) async {
    try {
      final baseUrl = ApiConfig.baseUrl;  
      final fullUrl = '$baseUrl$endpoint';  
      final url = Uri.parse(fullUrl);  

      final defaultHeaders = {
        'Content-Type': 'application/json',  
        ...?headers,  
      };

      http.Response response;  

      if (method.toUpperCase() == 'GET') {
        response = await http.get(url, headers: defaultHeaders);
      } else if (method.toUpperCase() == 'POST') {
        final jsonBody = body != null ? jsonEncode(body) : null;  
        response = await http.post(url, headers: defaultHeaders, body: jsonBody);
      } else if (method.toUpperCase() == 'PUT') {
        final jsonBody = body != null ? jsonEncode(body) : null;
        response = await http.put(url, headers: defaultHeaders, body: jsonBody);
      } else if (method.toUpperCase() == 'DELETE') {
        response = await http.delete(url, headers: defaultHeaders);
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {};
        } else {
          throw Exception('Request failed with status ${response.statusCode}');
        }
      }

      dynamic responseBody;  
      try {
        responseBody = jsonDecode(response.body);  
      } catch (e) {
        final responseText = response.body.trim();
        if (responseText.startsWith('<!DOCTYPE') || responseText.startsWith('<html')) {
          throw Exception('Backend returned HTML instead of JSON. Please check if backend is running correctly and database is connected.');
        }
        print('API Error - Response body: ${response.body}');
        print('API Error - Status code: ${response.statusCode}');
        final errorPreview = response.body.length > 100 
            ? response.body.substring(0, 100) 
            : response.body;
        throw Exception('Invalid JSON response: $errorPreview');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody;
      } else {
        String errorMessage;
        if (responseBody is Map) {
          errorMessage = responseBody['message'] ?? 
                        responseBody['error'] ?? 
                        'Request failed with status ${response.statusCode}';
        } else {
          errorMessage = 'Request failed with status ${response.statusCode}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('API Request Error: $e');
      print('Endpoint: $endpoint');
      print('Method: $method');
      
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<User> registerUser(User user, String password) async {
    final userData = {
      'FullName': user.fullName,
      'Email': user.email,
      'PasswordHash': password,  
      'PhoneNumber': user.phone,
    };

    final response = await _makeRequest('POST', ApiConfig.users, body: userData);
    final userDataFromServer = response['user'] ?? response;
    final newUser = User.fromJson(userDataFromServer);
    await _saveCurrentUser(newUser);
    return newUser;
  }

  Future<User> loginUser(String email, String password) async {
    final loginData = {
      'Email': email,
      'PasswordHash': password,
    };

    final response = await _makeRequest('POST', ApiConfig.userLogin, body: loginData);
    final userData = response['user'] ?? response;
    final user = User.fromJson(userData);
    await _saveCurrentUser(user);
    return user;
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('currentUser');
    if (userJson == null) {
      return null;
    }
    
    final userMap = jsonDecode(userJson);
    return User.fromJson(userMap);
  }

  Future<void> _saveCurrentUser(User user) async {
    final prefs = await SharedPreferences.getInstance(); 
    final userJson = jsonEncode(user.toJson());
    await prefs.setString('currentUser', userJson);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();   
    await prefs.remove('currentUser');
  }

  Future<User> getUserById(String userId) async {
    final response = await _makeRequest('GET', '${ApiConfig.users}/$userId');
    return User.fromJson(response);
  }

  Future<User> getUserByEmail(String email) async {
    final response = await _makeRequest('GET', '${ApiConfig.userByEmail}/$email');
    return User.fromJson(response);
  }

  Future<User> registerApplicant(User user, String password) async {
    final applicantData = {
      'FullName': user.fullName,
      'Email': user.email,
      'PasswordHash': password,
      'PhoneNumber': user.phone,
    };

    final response = await _makeRequest('POST', ApiConfig.applicants, body: applicantData);
    final applicantDataFromServer = response['applicant'] ?? response;
    final newApplicant = User.fromJson(applicantDataFromServer);
    await _saveCurrentUser(newApplicant);
    return newApplicant;
  }

  Future<User> loginApplicant(String email, String password) async {
    final loginData = {
      'Email': email,
      'PasswordHash': password,
    };

    final response = await _makeRequest('POST', ApiConfig.applicantLogin, body: loginData);
    final applicantData = response['applicant'] ?? response;
    final user = User.fromJson(applicantData);
    await _saveCurrentUser(user);
    return user;
  }

  Future<User> getApplicantById(String applicantId) async {
    final response = await _makeRequest('GET', '${ApiConfig.applicants}/$applicantId');
    return User.fromJson(response);
  }

  Future<User> getApplicantByEmail(String email) async {
    final response = await _makeRequest('GET', '${ApiConfig.applicantByEmail}/$email');
    return User.fromJson(response);
  }

  Future<List<JobPost>> getAllJobPosts() async {
    final response = await _makeRequest('GET', ApiConfig.posts);
    final List<dynamic> postsList = response is List ? response : [];
    final jobPosts = postsList.map((json) => JobPost.fromJson(json)).toList();
    return jobPosts;
  }

  Future<JobPost> getJobPostById(String postId) async {
    final response = await _makeRequest('GET', '${ApiConfig.posts}/$postId');
    return JobPost.fromJson(response);
  }

  Future<List<JobPost>> getJobPostsByUser(String userId) async {
    final response = await _makeRequest('GET', '${ApiConfig.postsByUser}/$userId');
    final List<dynamic> postsList = response is List ? response : [];
    final jobPosts = postsList.map((json) => JobPost.fromJson(json)).toList();
    return jobPosts;
  }

  Future<JobPost> createJobPost(JobPost jobPost, String userId) async {
    final dateString = jobPost.createdAt.toIso8601String().split('T')[0];
    final postData = {
      'UserID': userId,
      'Title': jobPost.title,
      'CompanyName': jobPost.company,
      'Location': jobPost.location,
      'EmploymentType': jobPost.jobType,
      'Description': jobPost.description,
      'PostedDate': dateString,
      'SalaryMin': jobPost.salaryMin,
      'SalaryMax': jobPost.salaryMax,
    };

    final response = await _makeRequest('POST', ApiConfig.posts, body: postData);
    final postDataFromServer = response['post'] ?? response;
    return JobPost.fromJson(postDataFromServer);
  }

  Future<void> deleteJobPost(String postId) async {
    await _makeRequest('DELETE', '${ApiConfig.posts}/$postId');
  }

  Future<Application> createApplication(Application application) async {
    final applicationData = {
      'UserID': application.applicantId,
      'PostID': application.jobId,
      'Message': application.message,
    };

    final response = await _makeRequest('POST', ApiConfig.apply, body: applicationData);
    final appData = response['application'] ?? response;
    return Application.fromJson(appData);
  }

  Future<List<Application>> getAllApplications() async {
    final response = await _makeRequest('GET', ApiConfig.applications);
    final List<dynamic> appsList = response is List ? response : [];
    final applications = appsList.map((json) => Application.fromJson(json)).toList();
    return applications;
  }

  Future<List<Application>> getApplicationsByUser(String userId) async {
    final response = await _makeRequest('GET', '${ApiConfig.applicationsByUser}/$userId');
    final List<dynamic> appsList = response is List ? response : [];
    final applications = appsList.map((json) => Application.fromJson(json)).toList();
    return applications;
  }

  @Deprecated('Use getApplicationsByUser instead')
  Future<List<Application>> getApplicationsByApplicant(String userId) async {
    return getApplicationsByUser(userId);
  }

  Future<List<Application>> getApplicationsForJob(String postId) async {
    final response = await _makeRequest('GET', '${ApiConfig.applicationsByPost}/$postId');
    final List<dynamic> appsList = response is List ? response : [];
    final applications = appsList.map((json) => Application.fromJson(json)).toList();
    return applications;
  }

  Future<bool> hasUserApplied(String postId, String applicantId) async {
    final response = await _makeRequest('GET', '${ApiConfig.checkApplication}/$postId/$applicantId');
    final hasApplied = response['hasApplied'] ?? false;
    return hasApplied;
  }

}
  
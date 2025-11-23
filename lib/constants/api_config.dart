class ApiConfig {
  static const String baseUrl = 'http://localhost:3000';

  static const String users = '/users';
  static const String userLogin = '/users/login';
  static const String userByEmail = '/users/email';
  
  static const String applicants = '/applicants';
  static const String applicantLogin = '/applicants/login';
  static const String applicantByEmail = '/applicants/email';
  
  static const String posts = '/posts';
  static const String postsByUser = '/posts/user';
  
  static const String apply = '/apply';
  static const String applications = '/applications';
  static const String applicationsByUser = '/applications/user';
  static const String applicationsByPost = '/applications/post';
  static const String checkApplication = '/applications/check';
}

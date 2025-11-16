import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/job_post.dart';
import '../models/application.dart';
import '../models/message.dart';

// Service to handle all data storage operations
class StorageService {
  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Keys for SharedPreferences
  static const String _usersKey = 'users';
  static const String _jobPostsKey = 'jobPosts';
  static const String _applicationsKey = 'applications';
  static const String _messagesKey = 'messages';
  static const String _currentUserIdKey = 'currentUserId';

  // ===== USER OPERATIONS =====

  // Save new user
  Future<void> saveUser(User user, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing users
    final users = await getAllUsers();
    users.add(user);
    
    // Save users
    final usersJson = users.map((u) => u.toJson()).toList();
    await prefs.setString(_usersKey, jsonEncode(usersJson));
    
    // Save password separately (in real app, use secure storage)
    await prefs.setString('password_${user.id}', password);
  }

  // Get all users
  Future<List<User>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersString = prefs.getString(_usersKey);
    
    if (usersString == null) return [];
    
    final List<dynamic> usersList = jsonDecode(usersString);
    return usersList.map((json) => User.fromJson(json)).toList();
  }

  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    final users = await getAllUsers();
    try {
      return users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Verify password
  Future<bool> verifyPassword(String userId, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString('password_$userId');
    return savedPassword == password;
  }

  // Set current logged in user
  Future<void> setCurrentUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
    await prefs.setBool('isLoggedIn', true);
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserIdKey);
    if (userId == null) return null;
    return getUserById(userId);
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    await prefs.setBool('isLoggedIn', false);
  }

  // Update user
  Future<void> updateUser(User user) async {
    final users = await getAllUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      users[index] = user;
      final prefs = await SharedPreferences.getInstance();
      final usersJson = users.map((u) => u.toJson()).toList();
      await prefs.setString(_usersKey, jsonEncode(usersJson));
    }
  }

  // ===== JOB POST OPERATIONS =====

  // Create job post
  Future<void> createJobPost(JobPost jobPost) async {
    final prefs = await SharedPreferences.getInstance();
    final jobPosts = await getAllJobPosts();
    jobPosts.add(jobPost);
    
    final jobsJson = jobPosts.map((j) => j.toJson()).toList();
    await prefs.setString(_jobPostsKey, jsonEncode(jobsJson));
  }

  // Get all job posts
  Future<List<JobPost>> getAllJobPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final jobsString = prefs.getString(_jobPostsKey);
    
    if (jobsString == null) return [];
    
    final List<dynamic> jobsList = jsonDecode(jobsString);
    return jobsList.map((json) => JobPost.fromJson(json)).toList();
  }

  // Get job posts by user
  Future<List<JobPost>> getJobPostsByUser(String userId) async {
    final allPosts = await getAllJobPosts();
    return allPosts.where((post) => post.userId == userId).toList();
  }

  // Get job post by ID
  Future<JobPost?> getJobPostById(String jobId) async {
    final posts = await getAllJobPosts();
    try {
      return posts.firstWhere((post) => post.id == jobId);
    } catch (e) {
      return null;
    }
  }

  // Update job post (for adding applicants)
  Future<void> updateJobPost(JobPost jobPost) async {
    final posts = await getAllJobPosts();
    final index = posts.indexWhere((p) => p.id == jobPost.id);
    if (index != -1) {
      posts[index] = jobPost;
      final prefs = await SharedPreferences.getInstance();
      final jobsJson = posts.map((j) => j.toJson()).toList();
      await prefs.setString(_jobPostsKey, jsonEncode(jobsJson));
    }
  }

  // Delete job post
  Future<void> deleteJobPost(String jobId) async {
    final posts = await getAllJobPosts();
    posts.removeWhere((post) => post.id == jobId);
    
    final prefs = await SharedPreferences.getInstance();
    final jobsJson = posts.map((j) => j.toJson()).toList();
    await prefs.setString(_jobPostsKey, jsonEncode(jobsJson));
  }

  // ===== APPLICATION OPERATIONS =====

  // Create application
  Future<void> createApplication(Application application) async {
    final prefs = await SharedPreferences.getInstance();
    final applications = await getAllApplications();
    applications.add(application);
    
    final appsJson = applications.map((a) => a.toJson()).toList();
    await prefs.setString(_applicationsKey, jsonEncode(appsJson));
  }

  // Get all applications
  Future<List<Application>> getAllApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final appsString = prefs.getString(_applicationsKey);
    
    if (appsString == null) return [];
    
    final List<dynamic> appsList = jsonDecode(appsString);
    return appsList.map((json) => Application.fromJson(json)).toList();
  }

  // Get applications by user (jobs user applied to)
  Future<List<Application>> getApplicationsByUser(String userId) async {
    final allApps = await getAllApplications();
    return allApps.where((app) => app.applicantId == userId).toList();
  }

  // Get applications for a job
  Future<List<Application>> getApplicationsForJob(String jobId) async {
    final allApps = await getAllApplications();
    return allApps.where((app) => app.jobId == jobId).toList();
  }

  // ===== MESSAGE OPERATIONS =====

  // Send message
  Future<void> sendMessage(Message message) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getAllMessages();
    messages.add(message);
    
    final messagesJson = messages.map((m) => m.toJson()).toList();
    await prefs.setString(_messagesKey, jsonEncode(messagesJson));
  }

  // Get all messages
  Future<List<Message>> getAllMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final messagesString = prefs.getString(_messagesKey);
    
    if (messagesString == null) return [];
    
    final List<dynamic> messagesList = jsonDecode(messagesString);
    return messagesList.map((json) => Message.fromJson(json)).toList();
  }

  // Get messages between two users
  Future<List<Message>> getMessagesBetweenUsers(
      String user1Id, String user2Id) async {
    final allMessages = await getAllMessages();
    return allMessages
        .where((msg) =>
            (msg.senderId == user1Id && msg.receiverId == user2Id) ||
            (msg.senderId == user2Id && msg.receiverId == user1Id))
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  // Get all chats for a user
  Future<List<Chat>> getChatsForUser(String userId) async {
    final allMessages = await getAllMessages();
    final currentUser = await getUserById(userId);
    if (currentUser == null) return [];

    // Get unique users we've chatted with
    final Set<String> chatUserIds = {};
    for (var msg in allMessages) {
      if (msg.senderId == userId) chatUserIds.add(msg.receiverId);
      if (msg.receiverId == userId) chatUserIds.add(msg.senderId);
    }

    // Create chat objects
    List<Chat> chats = [];
    for (var otherUserId in chatUserIds) {
      final messages = await getMessagesBetweenUsers(userId, otherUserId);
      if (messages.isEmpty) continue;

      final lastMessage = messages.last;
      final otherUser = await getUserById(otherUserId);
      
      final unreadCount = messages
          .where((msg) => msg.receiverId == userId && !msg.isRead)
          .length;

      chats.add(Chat(
        chatId: '${userId}_$otherUserId',
        otherUserId: otherUserId,
        otherUserName: otherUser?.fullName ?? 'Unknown',
        lastMessage: lastMessage.content,
        lastMessageTime: lastMessage.sentAt,
        unreadCount: unreadCount,
      ));
    }

    // Sort by last message time
    chats.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return chats;
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String senderId, String receiverId) async {
    final messages = await getAllMessages();
    bool updated = false;

    for (var i = 0; i < messages.length; i++) {
      if (messages[i].senderId == senderId &&
          messages[i].receiverId == receiverId &&
          !messages[i].isRead) {
        messages[i] = Message(
          id: messages[i].id,
          senderId: messages[i].senderId,
          senderName: messages[i].senderName,
          receiverId: messages[i].receiverId,
          receiverName: messages[i].receiverName,
          content: messages[i].content,
          sentAt: messages[i].sentAt,
          isRead: true,
        );
        updated = true;
      }
    }

    if (updated) {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = messages.map((m) => m.toJson()).toList();
      await prefs.setString(_messagesKey, jsonEncode(messagesJson));
    }
  }
}


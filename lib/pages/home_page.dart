import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/job_post.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'create_job_page.dart';
import 'job_detail_page.dart';
import 'my_posts_page.dart';
import 'my_applications_page.dart';
import 'profile_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const JobFeedPage(),
    const MyPostsPage(),
    const MyApplicationsPage(),
    const ProfilePage(),
  ];

  void _handleNavigation(int index) {
    if (index == 4) {
      _showLogoutDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final storage = ApiService();
      await storage.logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _handleNavigation,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'My Posts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Applied',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout, color: Colors.red),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}

class JobFeedPage extends StatefulWidget {
  const JobFeedPage({super.key});

  @override
  State<JobFeedPage> createState() => _JobFeedPageState();
}

class _JobFeedPageState extends State<JobFeedPage> {
  User? _currentUser;
  List<JobPost> _jobPosts = [];
  List<JobPost> _filteredPosts = [];
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final api = ApiService();
    final user = await api.getCurrentUser();
    final posts = await api.getAllJobPosts();
    
    setState(() {
      _currentUser = user;
      _jobPosts = posts..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _filteredPosts = _jobPosts;
    });
  }

  void _filterPosts() {
    setState(() {
      _filteredPosts = _jobPosts.where((post) {

        // Search 

        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            post.title.toLowerCase().contains(searchQuery) ||
            post.company.toLowerCase().contains(searchQuery) ||
            post.location.toLowerCase().contains(searchQuery);

        final matchesType = _selectedFilter == 'All' ||
            post.jobType == _selectedFilter;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Job Feed'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filterPosts(),
                decoration: InputDecoration(
                  hintText: 'Search jobs...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: ['All', 'Full-time', 'Part-time', 'Remote', 'Internship']
                    .map((filter) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: _selectedFilter == filter,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                                _filterPosts();
                              });
                            },
                            selectedColor: Theme.of(context).primaryColor,
                            labelStyle: TextStyle(
                              color: _selectedFilter == filter
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No jobs found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Be the first to post a job!'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredPosts.length,
                      itemBuilder: (context, index) {
                        final job = _filteredPosts[index];
                        final isMyPost = job.userId == _currentUser?.id;
                        return _buildJobCard(job, isMyPost);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateJobPage()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Job'),
      ),
    );
  }

  Widget _buildJobCard(JobPost job, bool isMyPost) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailPage(jobPost: job),
              ),
            ).then((_) => _loadData());
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMyPost)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'My Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Posted by ${job.userName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _getTimeAgo(job.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(Icons.location_on, job.location, Colors.blue),
                    _buildTag(Icons.work_outline, job.jobType, Colors.green),
                    _buildTag(FontAwesomeIcons.moneyBill, job.salary,Colors.orange),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  job.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.people,
                        size: 18, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${job.applicants.length} applicants',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

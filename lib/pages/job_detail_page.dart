import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/job_post.dart';
import '../models/application.dart';
import '../services/api_service.dart';
import 'user_profile_page.dart';

class JobDetailPage extends StatefulWidget {
  final JobPost jobPost;

  const JobDetailPage({super.key, required this.jobPost});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final _messageController = TextEditingController();
  bool _hasApplied = false;
  bool _isMyPost = false;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    final storage = ApiService();
    final currentUser = await storage.getCurrentUser();
    
    if (currentUser == null) return;
    
    // Check user's own post
    final isMyPost = widget.jobPost.userId == currentUser.id;
    
    // Check user apply
    final hasApplied = await storage.hasUserApplied(widget.jobPost.id, currentUser.id);

    if (mounted) {
      setState(() {
        _isMyPost = isMyPost;
        _hasApplied = hasApplied;
      });
    }
  }

  Future<void> _applyToJob() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final storage = ApiService();
    final currentUser = await storage.getCurrentUser();
    
    if (currentUser == null) return;

    // Create apply
    final applicationId = DateTime.now().millisecondsSinceEpoch.toString();
    final application = Application(
      id: applicationId,
      jobId: widget.jobPost.id,
      jobTitle: widget.jobPost.title,
      applicantId: currentUser.id,
      applicantName: currentUser.fullName,
      applicantEmail: currentUser.email,
      message: _messageController.text.trim(),
      appliedAt: DateTime.now(),
    );

    try {
      await storage.createApplication(application);
      
      // Update apply 
      setState(() {
        _hasApplied = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error apply to job'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showApplyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apply for this position',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tell the employer why you are a great fit...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyToJob();
                },
                child: const Text('Submit Application'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Job Details'),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.business,
                          size: 35,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.jobPost.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.jobPost.company,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(Icons.location_on, widget.jobPost.location, Colors.blue),
                      _buildTag(Icons.work_outline, widget.jobPost.jobType, Colors.green),
                      _buildTag(FontAwesomeIcons.moneyBill, widget.jobPost.salary, Colors.orange),
                    ],
                  ),

                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilePage(
                            userId: widget.jobPost.userId,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Posted by ${widget.jobPost.userName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),

                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Applicants count
                  Row(
                    children: [
                      Icon(Icons.people, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.jobPost.applicants.length} people applied',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Job Description
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.jobPost.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _isMyPost
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _hasApplied ? null : _showApplyDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasApplied ? Colors.grey : Theme.of(context).primaryColor,
                  ),
                  child: Text(
                    _hasApplied ? 'Already Applied' : 'Apply Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


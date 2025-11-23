import 'package:flutter/material.dart';
import '../models/job_post.dart';
import '../services/api_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  
  String _selectedJobType = 'Full-time';
  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Remote', 'Internship'];

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _createJob() async {
    if (_formKey.currentState!.validate()) {
      final storage = ApiService();
      final currentUser = await storage.getCurrentUser();

      if (currentUser == null) return;

      double? salaryMin;
      double? salaryMax;
      final salaryText = _salaryController.text.trim();
      if (salaryText.isNotEmpty) {
        if (salaryText.contains('-')) {
          final parts = salaryText.split('-');
          salaryMin = double.tryParse(parts[0].trim().replaceAll('thb', '').replaceAll(',', ''));
          salaryMax = double.tryParse(parts[1].trim().replaceAll('thb', '').replaceAll(',', ''));
        } else {
          salaryMin = double.tryParse(salaryText.replaceAll('thb', '').replaceAll(',', ''));
        }
      }

      final jobId = DateTime.now().millisecondsSinceEpoch.toString();
      final jobPost = JobPost(
        id: jobId,
        userId: currentUser.id,
        userName: currentUser.fullName,
        userEmail: currentUser.email,
        title: _titleController.text.trim(),
        company: _companyController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        jobType: _selectedJobType,
        salary: salaryText.isNotEmpty ? salaryText : 'Not specified',
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        createdAt: DateTime.now(),
      );

      try {
        await storage.createJobPost(jobPost, currentUser.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job posted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Post a Job'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Job Post',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in the details to post a new job opportunity',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              CustomTextField(
                label: 'Job Title',
                hint: 'e.g. Smart contract developer',
                controller: _titleController,
                prefixIcon: Icons.work,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter job title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Company Name',
                hint: 'e.g. Rangsit Company',
                controller: _companyController,
                prefixIcon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter company name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Location',
                hint: 'e.g. Bangkok, Thailand',
                controller: _locationController,
                prefixIcon: Icons.location_on,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedJobType,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: _jobTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedJobType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Salary Range',
                hint: 'e.g. 50000 thb',
                controller: _salaryController,
                prefixIcon: Icons.attach_money,
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter job description';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Describe the job role, requirements, and responsibilities...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: 'Post Job',
                onPressed: _createJob,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


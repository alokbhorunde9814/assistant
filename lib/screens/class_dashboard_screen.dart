import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/assignment_model.dart';
import '../screens/class_students_screen.dart';
import '../screens/create_assignment_screen.dart';
import '../screens/submit_assignment_screen.dart';
import '../screens/assignment_detail_screen.dart';
import '../screens/feedback_screen.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';

class ClassDashboardScreen extends StatefulWidget {
  final ClassModel classModel;
  final bool isTeacher;

  const ClassDashboardScreen({
    super.key,
    required this.classModel,
    required this.isTeacher,
  });

  @override
  State<ClassDashboardScreen> createState() => _ClassDashboardScreenState();
}

class _ClassDashboardScreenState extends State<ClassDashboardScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  bool _isLoading = false;

  final List<String> _teacherTabs = ['Dashboard', 'Assignments', 'Students', 'Feedback', 'Insights'];
  final List<String> _studentTabs = ['Dashboard', 'Assignments', 'Resources', 'Feedback', 'Doubts'];

  // Get class-specific gradient colors based on class name
  List<Color> get classGradientColors {
    final String firstChar = widget.classModel.name.isNotEmpty ? widget.classModel.name[0].toUpperCase() : 'A';
    final int colorSeed = firstChar.codeUnitAt(0) % 6; // Use 6 different color schemes
    
    if (widget.isTeacher) {
      // Blue-based gradients for created classes
      switch (colorSeed) {
        case 0:
          return [const Color(0xFF1A73E8), const Color(0xFF3C8CE7)]; // Google blue
        case 1:
          return [const Color(0xFF4285F4), const Color(0xFF5C9EFF)]; // Light blue
        case 2:
          return [const Color(0xFF2979FF), const Color(0xFF448AFF)]; // Material blue
        case 3:
          return [const Color(0xFF0277BD), const Color(0xFF039BE5)]; // Sky blue
        case 4:
          return [const Color(0xFF0288D1), const Color(0xFF29B6F6)]; // Light blue accent
        case 5:
          return [const Color(0xFF1565C0), const Color(0xFF42A5F5)]; // Blue to light blue
        default:
          return [const Color(0xFF1A73E8), const Color(0xFF3C8CE7)]; // Default blue
      }
    } else {
      // Purple-based gradients for joined classes
      switch (colorSeed) {
        case 0:
          return [const Color(0xFF8E24AA), const Color(0xFFAB47BC)]; // Light purple
        case 1:
          return [const Color(0xFF7B1FA2), const Color(0xFF9C27B0)]; // Medium purple
        case 2:
          return [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)]; // Dark purple
        case 3:
          return [const Color(0xFF5E35B1), const Color(0xFF7986CB)]; // Indigo to purple
        case 4:
          return [const Color(0xFF9C27B0), const Color(0xFFCE93D8)]; // Purple to light purple
        case 5:
          return [const Color(0xFF7E57C2), const Color(0xFF9575CD)]; // Deep purple to light
        default:
          return [const Color(0xFF7B1FA2), const Color(0xFF9C27B0)]; // Default purple
      }
    }
  }

  // Get primary color for the class for other UI elements
  Color get classPrimaryColor => classGradientColors.first;

  @override
  void initState() {
    super.initState();
    final tabs = widget.isTeacher ? _teacherTabs : _studentTabs;
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
      
      // Auto-navigate to students screen when the Students tab is selected and there are students
      if (_tabController.index == 2 && widget.isTeacher && widget.classModel.studentCount > 0) {
        // Use Future.delayed to ensure the tab has finished animating before navigating
        Future.delayed(Duration.zero, () {
          _navigateToStudentsScreen();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.classModel.name,
        backgroundColor: Colors.white,
        foregroundColor: classPrimaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: classPrimaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share code: ${widget.classModel.code}')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: classPrimaryColor),
            onPressed: () {
              _showClassOptions(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildClassHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: widget.isTeacher
                  ? [
                      _buildTeacherDashboard(),
                      _buildAssignmentsTab(),
                      _buildStudentsTab(),
                      _buildFeedbackTab(),
                      _buildInsightsTab(),
                    ]
                  : [
                      _buildStudentDashboard(),
                      _buildAssignmentsTab(),
                      _buildResourcesTab(),
                      _buildFeedbackTab(),
                      _buildDoubtsTab(),
                    ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isTeacher ? FloatingActionButton(
        onPressed: () {
          _showCreateOptions(context);
        },
        backgroundColor: classPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  // Show class options menu
  void _showClassOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.share, color: classPrimaryColor),
                title: const Text('Share Class Code'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share code: ${widget.classModel.code}')),
                  );
                },
              ),
              if (widget.isTeacher) ...[
                ListTile(
                  leading: Icon(Icons.edit, color: classPrimaryColor),
                  title: const Text('Edit Class Details'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit class coming soon')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Class', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Leave Class', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showLeaveConfirmation(context);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Show creation options for teacher
  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Create New',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.assignment_add, color: classPrimaryColor),
                title: const Text('Assignment'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAssignmentScreen(
                        classModel: widget.classModel,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.announcement, color: classPrimaryColor),
                title: const Text('Announcement'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateAnnouncementDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.upload_file, color: classPrimaryColor),
                title: const Text('Resource'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateResourceDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.quiz, color: classPrimaryColor),
                title: const Text('Quiz'),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateQuizDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // New methods for creating different content types
  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter announcement title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Enter announcement content',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || contentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              try {
                setState(() => _isLoading = true);
                await _databaseService.createAnnouncement(
                  classId: widget.classModel.id,
                  title: titleController.text,
                  content: contentController.text,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement created successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating announcement: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: classPrimaryColor,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateResourceDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    ResourceType selectedType = ResourceType.document;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Resource'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter resource title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter resource description',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'Enter resource URL',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Resource Type:'),
                DropdownButton<ResourceType>(
                  value: selectedType,
                  isExpanded: true,
                  items: ResourceType.values.map((type) {
                    return DropdownMenuItem<ResourceType>(
                      value: type,
                      child: Text(type.toString().split('.').last),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || urlController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in title and URL')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                
                try {
                  this.setState(() => _isLoading = true);
                  await _databaseService.createResource(
                    classId: widget.classModel.id,
                    title: titleController.text,
                    description: descriptionController.text,
                    url: urlController.text,
                    type: selectedType,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resource added successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding resource: $e')),
                    );
                  }
                } finally {
                  if (mounted) {
                    this.setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: classPrimaryColor,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCreateQuizDialog() {
    final titleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Quiz'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Quiz Title',
                hintText: 'Enter quiz title',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The quiz builder will open where you can add questions and set quiz settings.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a quiz title')),
                );
                return;
              }
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Quiz creation interface will be available soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: classPrimaryColor,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Show delete class confirmation
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class?'),
        content: const Text(
          'This will permanently delete the class, all assignments, and student data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete class coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Show leave class confirmation
  void _showLeaveConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Class?'),
        content: const Text(
          'You will be removed from this class and lose access to all materials. You can rejoin with the class code later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Leave class coming soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: classGradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class title and status row
          Row(
            children: [
              // Class subject badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.classModel.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const Spacer(),
              // Class status
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.classModel.studentCount} ${widget.classModel.studentCount == 1 ? 'Student' : 'Students'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Teacher info
          Row(
            children: [
              // Avatar/initials for teacher
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.3),
                child: Text(
                  widget.isTeacher 
                    ? 'You'
                    : widget.classModel.ownerName.isNotEmpty 
                      ? widget.classModel.ownerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    widget.isTeacher 
                      ? 'You'
                      : widget.classModel.ownerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Class summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isTeacher ? 'Class Summary' : 'Your Progress',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Assignments
                    _buildStatIndicator(
                      label: 'Assignments',
                      value: '0',
                      icon: Icons.assignment,
                    ),
                    
                    // Attendance/Completion rate
                    _buildStatIndicator(
                      label: widget.isTeacher ? 'Avg. Score' : 'Your Score',
                      value: '0%',
                      icon: Icons.analytics,
                    ),
                    
                    // Last activity
                    _buildStatIndicator(
                      label: 'Last Active',
                      value: 'Today',
                      icon: Icons.update,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method for building stat indicators
  Widget _buildStatIndicator({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = widget.isTeacher ? _teacherTabs : _studentTabs;
    
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: classPrimaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: classPrimaryColor,
        indicatorWeight: 3,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }

  Widget _buildTeacherDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions row
          Row(
            children: [
              _buildQuickActionButton(
                label: 'Assignment',
                icon: Icons.assignment_add,
                color: classPrimaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateAssignmentScreen(
                        classModel: widget.classModel,
                      ),
                    ),
                  );
                },
              ),
              _buildQuickActionButton(
                label: 'Announcement',
                icon: Icons.campaign,
                color: Colors.orange,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcements coming soon')),
                  );
                },
              ),
              _buildQuickActionButton(
                label: 'Resource',
                icon: Icons.upload_file,
                color: Colors.teal,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Resource uploading coming soon')),
                  );
                },
              ),
              _buildQuickActionButton(
                label: 'AI Tools',
                icon: Icons.psychology,
                color: Colors.purple,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI tools coming soon')),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          _buildSectionHeader(
            title: 'Recent Activity',
            actionText: 'View All',
            onActionTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Activity log coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          widget.classModel.studentCount > 0
              ? _buildRecentActivityList()
              : _buildEmptyActivityState(),
              
          const SizedBox(height: 24),
          
          // Student Insights
          _buildSectionHeader(
            title: 'Student Insights',
            actionText: widget.classModel.studentCount > 0 ? 'Details' : null,
            onActionTap: widget.classModel.studentCount > 0
                ? () => _tabController.animateTo(3)
                : null,
          ),
          
          const SizedBox(height: 12),
          
          widget.classModel.studentCount > 0
              ? _buildInsightsCards()
              : _buildEmptyInsightsState(),
              
          const SizedBox(height: 24),
          
          // AI Teaching Assistant
          _buildSectionHeader(
            title: 'AI Teaching Assistant',
            actionText: 'Try Now',
            onActionTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI assistant coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildAIAssistantCard(),
        ],
      ),
    );
  }

  // Helper for building quick action buttons
  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for building section headers
  Widget _buildSectionHeader({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        if (actionText != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: classPrimaryColor,
              ),
            ),
          ),
      ],
    );
  }

  // Empty state for recent activity
  Widget _buildEmptyActivityState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite students to join your class to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            label: 'Share Class Code',
            icon: Icons.share,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Class code: ${widget.classModel.code}')),
              );
            },
          ),
        ],
      ),
    );
  }

  // Recent activity list
  Widget _buildRecentActivityList() {
    // Placeholder data for recent activity
    final activities = [
      {
        'icon': Icons.person_add,
        'color': Colors.green,
        'title': 'New student joined',
        'description': 'John Doe joined your class',
        'time': '2 hours ago',
      },
      {
        'icon': Icons.assignment_turned_in,
        'color': Colors.blue,
        'title': 'Assignment completed',
        'description': '3 students completed "Math Quiz 1"',
        'time': 'Yesterday',
      },
    ];

    return Column(
      children: activities.map((activity) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                activity['time'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Empty state for insights
  Widget _buildEmptyInsightsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Insights Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create assignments and get students to submit work to generate insights',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Student insights cards
  Widget _buildInsightsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                title: 'Participation',
                value: '80%',
                icon: Icons.people,
                color: Colors.green,
                change: '+5%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                title: 'Avg. Score',
                value: '76%',
                icon: Icons.score,
                color: Colors.orange,
                change: '-2%',
                isPositive: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                title: 'Completion',
                value: '92%',
                icon: Icons.assignment_turned_in,
                color: Colors.blue,
                change: '+8%',
                isPositive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                title: 'Engaged',
                value: '65%',
                icon: Icons.thumb_up,
                color: Colors.purple,
                change: '+12%',
                isPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Insight card
  Widget _buildInsightCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // AI Teaching Assistant card
  Widget _buildAIAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            classPrimaryColor.withOpacity(0.8),
            classPrimaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Teaching Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'What would you like help with today?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAIFeatureButton(
                label: 'Generate Quiz',
                icon: Icons.quiz,
              ),
              const SizedBox(width: 12),
              _buildAIFeatureButton(
                label: 'Grade Papers',
                icon: Icons.grading,
              ),
              const SizedBox(width: 12),
              _buildAIFeatureButton(
                label: 'Student Analysis',
                icon: Icons.analytics,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // AI feature button
  Widget _buildAIFeatureButton({
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label coming soon')),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick actions row
          Row(
            children: [
              _buildQuickActionButton(
                label: 'Assignments',
                icon: Icons.assignment,
                color: classPrimaryColor,
                onTap: () {
                  _tabController.animateTo(1); // Switch to Assignments tab
                },
              ),
              _buildQuickActionButton(
                label: 'Resources',
                icon: Icons.menu_book,
                color: Colors.teal,
                onTap: () {
                  _tabController.animateTo(2); // Switch to Resources tab
                },
              ),
              _buildQuickActionButton(
                label: 'Ask AI',
                icon: Icons.question_answer,
                color: Colors.orange,
                onTap: () {
                  _tabController.animateTo(3); // Switch to Doubts tab
                },
              ),
              _buildQuickActionButton(
                label: 'Students',
                icon: Icons.people,
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassStudentsScreen(
                        classModel: widget.classModel,
                        isTeacher: widget.isTeacher,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Due Assignments
          _buildSectionHeader(
            title: 'Due Assignments',
            actionText: 'View All',
            onActionTap: () {
              _tabController.animateTo(1); // Switch to Assignments tab
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildDueAssignments(),
              
          const SizedBox(height: 24),
          
          // AI Study Assistant
          _buildSectionHeader(
            title: 'AI Study Assistant',
            actionText: 'Ask Question',
            onActionTap: () {
              _tabController.animateTo(3); // Switch to Doubts tab
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildStudyAssistantCard(),
          
          const SizedBox(height: 24),
          
          // Your Progress
          _buildSectionHeader(
            title: 'Your Progress',
            actionText: 'Full Report',
            onActionTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress report coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          _buildProgressCard(),
          
          const SizedBox(height: 24),
          
          // Recent Announcements
          _buildSectionHeader(
            title: 'Recent Announcements',
            actionText: null,
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Announcements Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for updates from your teacher',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Due assignments widget
  Widget _buildDueAssignments() {
    // Example data - would be replaced with real data
    final bool hasAssignments = false;
    
    if (!hasAssignments) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No Assignments Due',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up! Check back later for new assignments',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Sample assignments would be shown here if there were any
    return const SizedBox.shrink();
  }

  // AI Study Assistant card
  Widget _buildStudyAssistantCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: classGradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Study Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Need help with your studies?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Ask any question about your class...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  _tabController.animateTo(3); // Switch to Doubts tab
                },
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Progress card
  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: classPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.insert_chart,
                      color: classPrimaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Your Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Good',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress bars
          _buildProgressItem(
            label: 'Assignments',
            progress: 0.0,
            progressText: '0/0 completed',
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            label: 'Attendance',
            progress: 1.0,
            progressText: '100%',
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            label: 'Average Score',
            progress: 0.0,
            progressText: 'No scores yet',
          ),
        ],
      ),
    );
  }

  // Progress item with label and progress bar
  Widget _buildProgressItem({
    required String label,
    required double progress,
    required String progressText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              progressText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(classPrimaryColor),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab() {
    return StreamBuilder<List<AssignmentModel>>(
      stream: _databaseService.getAssignmentsForClass(widget.classModel.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading assignments',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        final assignments = snapshot.data ?? [];
        
        if (assignments.isEmpty) {
          // No assignments, show empty state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No assignments yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.isTeacher)
                  CustomButton(
                    label: 'Create Assignment',
                    icon: Icons.add,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateAssignmentScreen(
                            classModel: widget.classModel,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }
        
        // Display assignments
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with assignment count and create button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${assignments.length} Assignment${assignments.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (widget.isTeacher)
                    CustomButton(
                      label: 'Create',
                      icon: Icons.add,
                      type: ButtonType.outline,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateAssignmentScreen(
                              classModel: widget.classModel,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // List of assignments
              Expanded(
                child: ListView.builder(
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    final bool isOverdue = assignment.isOverdue;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isOverdue
                              ? Colors.red.withOpacity(0.1)
                              : AppTheme.secondaryColor.withOpacity(0.1),
                          child: Icon(
                            _getAssignmentIcon(assignment.isAutoGraded),
                            color: isOverdue ? Colors.red : AppTheme.secondaryColor,
                          ),
                        ),
                        title: Text(
                          assignment.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOverdue ? Colors.red : Colors.black87,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              assignment.formattedDueDate,
                              style: TextStyle(
                                color: isOverdue ? Colors.red : Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Points: ${assignment.points}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Colors.grey.shade400,
                        ),
                        onTap: () {
                          // Open assignment details or submission screen
                          if (widget.isTeacher) {
                            // For teachers, navigate to assignment details/submissions screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AssignmentDetailScreen(
                                  assignment: assignment,
                                  classModel: widget.classModel,
                                ),
                              ),
                            );
                          } else {
                            // For students, navigate to submit assignment screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubmitAssignmentScreen(
                                  assignment: assignment,
                                  allowResubmit: true,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  IconData _getAssignmentIcon(bool isAutoGraded) {
    return isAutoGraded ? Icons.auto_awesome : Icons.assignment;
  }

  Widget _buildStudentsTab() {
    if (widget.isTeacher) {
      // Auto-navigate to ClassStudentsScreen
      // Using a short delay to ensure build is complete
      Future.delayed(Duration.zero, () {
        if (mounted && _tabController.index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassStudentsScreen(
                classModel: widget.classModel,
                isTeacher: widget.isTeacher,
              ),
            ),
          ).then((_) {
            // If the user navigates back, switch to the first tab
            if (_tabController.index == 2 && mounted) {
              _tabController.animateTo(0);
            }
          });
        }
      });
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Loading students...'),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<ResourceModel>>(
      stream: _databaseService.getResourcesForClass(widget.classModel.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading resources',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }
        
        final resources = snapshot.data ?? [];
        
        if (resources.isEmpty) {
          // No resources, show empty state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No resources available yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.isTeacher)
                  CustomButton(
                    label: 'Add Resource',
                    icon: Icons.add,
                    onPressed: () {
                      _showCreateResourceDialog();
                    },
                  ),
              ],
            ),
          );
        }
        
        // Group resources by type
        final Map<ResourceType, List<ResourceModel>> groupedResources = {};
        for (var resource in resources) {
          if (!groupedResources.containsKey(resource.type)) {
            groupedResources[resource.type] = [];
          }
          groupedResources[resource.type]!.add(resource);
        }
        
        // Display resources
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with resource count and add button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${resources.length} Resource${resources.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (widget.isTeacher)
                    CustomButton(
                      label: 'Add',
                      icon: Icons.add,
                      type: ButtonType.outline,
                      onPressed: () {
                        _showCreateResourceDialog();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // List of resources by type
              Expanded(
                child: ListView.builder(
                  itemCount: groupedResources.keys.length,
                  itemBuilder: (context, index) {
                    final resourceType = groupedResources.keys.elementAt(index);
                    final resourceList = groupedResources[resourceType]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _getResourceTypeDisplayName(resourceType),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: classPrimaryColor,
                            ),
                          ),
                        ),
                        ...resourceList.map((resource) => _buildResourceItem(resource)),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getResourceTypeDisplayName(ResourceType type) {
    switch (type) {
      case ResourceType.document:
        return 'Documents';
      case ResourceType.video:
        return 'Videos';
      case ResourceType.link:
        return 'Web Links';
      case ResourceType.presentation:
        return 'Presentations';
      case ResourceType.worksheet:
        return 'Worksheets';
      case ResourceType.other:
        return 'Other Resources';
      default:
        return 'Resources';
    }
  }

  Widget _buildResourceItem(ResourceModel resource) {
    IconData resourceIcon;
    Color resourceColor;
    
    switch (resource.type) {
      case ResourceType.document:
        resourceIcon = Icons.description;
        resourceColor = Colors.blue;
        break;
      case ResourceType.video:
        resourceIcon = Icons.video_library;
        resourceColor = Colors.red;
        break;
      case ResourceType.link:
        resourceIcon = Icons.link;
        resourceColor = Colors.teal;
        break;
      case ResourceType.presentation:
        resourceIcon = Icons.slideshow;
        resourceColor = Colors.orange;
        break;
      case ResourceType.worksheet:
        resourceIcon = Icons.assignment;
        resourceColor = Colors.purple;
        break;
      case ResourceType.other:
      default:
        resourceIcon = Icons.folder;
        resourceColor = Colors.grey;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: resourceColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            resourceIcon,
            color: resourceColor,
          ),
        ),
        title: Text(
          resource.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: resource.description.isNotEmpty
            ? Text(
                resource.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.open_in_new),
        onTap: () {
          _openResourceUrl(resource.url, resource.title);
        },
      ),
    );
  }

  Future<void> _openResourceUrl(String url, String title) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening $title...')),
      );
      // In a real app, you would use a URL launcher package to open the link
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open URL: $e')),
      );
    }
  }

  Widget _buildDoubtsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Help Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: classPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.psychology,
                          color: classPrimaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'AI Learning Assistant',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get instant help with your questions, assignment clarifications, or any topic related to this class.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.send,
                          color: classPrimaryColor,
                        ),
                        onPressed: () {
                          _askAIQuestion();
                        },
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Help Categories
              _buildSectionHeader(
            title: 'Quick Help Categories',
                actionText: null,
              ),
              
              const SizedBox(height: 16),
              
          // Grid of help categories
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
                  children: [
              _buildQuickHelpCard(
                title: 'Class Topics',
                icon: Icons.class_,
                color: Colors.blue,
                onTap: () => _showHelpCategoryDialog('Class Topics'),
              ),
              _buildQuickHelpCard(
                title: 'Assignment Help',
                icon: Icons.assignment,
                color: Colors.orange,
                onTap: () => _showHelpCategoryDialog('Assignment Help'),
              ),
              _buildQuickHelpCard(
                title: 'Study Tips',
                icon: Icons.psychology,
                color: Colors.green,
                onTap: () => _showHelpCategoryDialog('Study Tips'),
              ),
              _buildQuickHelpCard(
                title: 'Quiz Prep',
                icon: Icons.quiz,
                color: Colors.purple,
                onTap: () => _showHelpCategoryDialog('Quiz Prep'),
              ),
            ],
              ),
              
              const SizedBox(height: 24),
              
          // Previous Questions
              _buildSectionHeader(
            title: 'Your Previous Questions',
                actionText: null,
              ),
              
              const SizedBox(height: 16),
              
          // Empty state or example questions
              Center(
                child: Column(
                  children: [
                    Icon(
                  Icons.help_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                  'No questions yet',
                      style: TextStyle(
                    fontSize: 16,
                        fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                Text(
                  'Ask the AI assistant anything about your class',
                        style: TextStyle(
                    fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                  textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildQuickHelpCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
                  Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  void _showHelpCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category),
        content: Column(
          mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
              'Sample questions to ask:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...(_getExampleQuestions(category).map((q) => 
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.question_answer, size: 16, color: classPrimaryColor),
                title: Text(q),
                onTap: () {
                  Navigator.pop(context);
                  _askQuestion(q);
                },
              )
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<String> _getExampleQuestions(String category) {
    switch (category) {
      case 'Class Topics':
        return [
          'Explain the concept of ${widget.classModel.subject} in simple terms',
          'What are the main topics covered in ${widget.classModel.name}?',
          'How does ${widget.classModel.subject} relate to real-world applications?',
        ];
      case 'Assignment Help':
        return [
          'How do I approach the current assignment?',
          'What are some tips for completing the homework?',
          'Can you explain the requirements for the project?',
        ];
      case 'Study Tips':
        return [
          'What are effective ways to study ${widget.classModel.subject}?',
          'How can I prepare for the upcoming test?',
          'What learning techniques work best for this topic?',
        ];
      case 'Quiz Prep':
        return [
          'What topics should I focus on for the next quiz?',
          'Can you create a practice quiz on ${widget.classModel.subject}?',
          'What are common mistakes students make in ${widget.classModel.subject} quizzes?',
        ];
      default:
        return [
          'How can I learn more about ${widget.classModel.subject}?',
          'What resources do you recommend for this class?',
          'Can you explain difficult concepts in ${widget.classModel.name}?',
        ];
    }
  }

  void _askQuestion(String question) {
    // Show a demonstration dialog with sample response
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            const Text('AI Response'),
            const SizedBox(height: 4),
                              Text(
              'Q: $question',
                                style: TextStyle(
                                  fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
        content: const Text(
          'I\'ll be happy to help with that! The answer would be displayed here with relevant information from your class materials and general knowledge about the subject. This feature will be fully implemented in a future update.',
                        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
                    ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: classPrimaryColor,
                  ),
            child: const Text('Thanks!'),
          ),
        ],
      ),
    );
  }

  void _askAIQuestion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your question has been sent to the AI Assistant. Responses will be available soon!')),
    );
  }

  Widget _buildInsightsTab() {
    return widget.classModel.studentCount > 0
        ? const Center(child: Text('Class insights will appear here'))
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Add students to see insights',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildDoubtsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'AI-powered doubt solver',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ask any question about your class material and get instant answers',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'Ask a Question',
            icon: Icons.question_answer,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI doubt solver coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
    Color color = AppTheme.primaryColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: CustomButton(
                label: buttonText,
                type: ButtonType.outline,
                onPressed: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightStatistic({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 
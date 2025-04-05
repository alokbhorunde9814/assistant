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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create announcement coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.upload_file, color: classPrimaryColor),
                title: const Text('Resource'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Upload resource coming soon')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.quiz, color: classPrimaryColor),
                title: const Text('Quiz'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Create quiz coming soon')),
                  );
                },
              ),
            ],
          ),
        );
      },
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
    // For teachers with students, show a loading indicator that will be replaced by navigation
    if (widget.isTeacher && widget.classModel.studentCount > 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(classPrimaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading ${widget.classModel.studentCount} student${widget.classModel.studentCount == 1 ? '' : 's'}...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    
    // For empty classes or students viewing the screen
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: classPrimaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            widget.classModel.studentCount > 0
                ? 'View ${widget.classModel.studentCount} student${widget.classModel.studentCount == 1 ? '' : 's'}'
                : 'No students enrolled yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (widget.classModel.studentCount > 0)
            CustomButton(
              label: 'View Student List',
              icon: Icons.people,
              onPressed: _navigateToStudentsScreen,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: classGradientColors,
              ),
            )
          else
            CustomButton(
              label: 'Share Class Code',
              icon: Icons.share,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Class code: ${widget.classModel.code}')),
                );
              },
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: classGradientColors,
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToStudentsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassStudentsScreen(
          classModel: widget.classModel,
          isTeacher: widget.isTeacher,
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
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
        ],
      ),
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

  Widget _buildFeedbackTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'AI Feedback',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'View and analyze feedback for your assignments',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            label: 'View Feedback',
            icon: Icons.visibility,
            onPressed: () {
              // Navigate to feedback screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedbackScreen(
                    feedback: {
                      'pdfName': 'Assignment_Submission.pdf',
                      'pageCount': 5,
                      'score': 85,
                      'feedbackPoints': [
                        'Good understanding of the topic',
                        'Well-structured arguments',
                        'Could improve on examples',
                      ],
                      'suggestedImprovements': 'Try to include more real-world examples and applications of the concepts discussed.',
                      'rawFeedback': 'Overall, this is a well-written assignment that demonstrates a good understanding of the subject matter. The arguments are well-structured and supported with relevant information. However, including more real-world examples would strengthen the analysis.',
                    },
                  ),
                ),
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
} 
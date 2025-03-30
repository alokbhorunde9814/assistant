import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/assignment_model.dart';
import '../screens/class_students_screen.dart';
import '../screens/create_assignment_screen.dart';
import '../screens/submit_assignment_screen.dart';
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

  final List<String> _teacherTabs = ['Dashboard', 'Assignments', 'Students', 'Insights'];
  final List<String> _studentTabs = ['Dashboard', 'Assignments', 'Resources', 'Doubts'];

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
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.classModel.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
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
                      _buildInsightsTab(),
                    ]
                  : [
                      _buildStudentDashboard(),
                      _buildAssignmentsTab(),
                      _buildResourcesTab(),
                      _buildDoubtsTab(),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.classModel.subject,
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isTeacher 
                          ? '👤 Teacher: You' 
                          : '👤 Teacher: ${widget.classModel.ownerName}',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Code: ${widget.classModel.code}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.isTeacher) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📊 AI Insights:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.classModel.studentCount > 0 ? "Students struggle with Q2 in the latest quiz" : "Add students to get AI insights"}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (widget.classModel.studentCount > 0) ...[
                          const SizedBox(height: 4),
                          const Text(
                            '🔍 Low engagement detected in last quiz',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.secondaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚀 AI Study Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Review algebraic expressions - your quiz results show room for improvement',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = widget.isTeacher ? _teacherTabs : _studentTabs;
    
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildTeacherDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 AI-Powered Assistance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Auto-Graded Assignments
          _buildFeatureCard(
            icon: Icons.grading,
            title: 'Auto-Graded Assignments',
            description: 'Review and approve AI-graded assignments',
            buttonText: 'Review & Approve',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Auto-grading feature coming soon')),
              );
            },
          ),
          
          // AI-Suggested Quiz
          _buildFeatureCard(
            icon: Icons.quiz,
            title: 'AI-Suggested Quiz',
            description: 'Create a quiz based on recent topics and student performance',
            buttonText: 'Create Quiz',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Quiz Generator coming soon')),
              );
            },
          ),
          
          // Personalized Learning Paths
          _buildFeatureCard(
            icon: Icons.account_tree,
            title: 'Personalized Learning Paths',
            description: 'AI creates custom study plans based on student progress',
            buttonText: 'Set Up Paths',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Learning Paths feature coming soon')),
              );
            },
          ),
          
          // Low Participation Alert
          _buildFeatureCard(
            icon: Icons.warning_amber,
            title: 'Low Participation Alert',
            description: widget.classModel.studentCount > 0 
                ? '3 students have low engagement scores' 
                : 'No students to monitor yet',
            buttonText: 'View Details',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Participation tracking coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 24),
          const Text(
            '📢 Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'New Announcement',
                  icon: Icons.campaign,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Announcements coming soon')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Add Resource',
                  type: ButtonType.outline,
                  icon: Icons.upload_file,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resource uploading coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 Your Learning',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // Upcoming Assignments
          _buildFeatureCard(
            icon: Icons.assignment,
            title: 'Upcoming Assignments',
            description: 'No upcoming assignments due',
            buttonText: 'View All',
            color: AppTheme.secondaryColor,
            onTap: () {
              _tabController.animateTo(1); // Switch to Assignments tab
            },
          ),
          
          // AI Study Assistant
          _buildFeatureCard(
            icon: Icons.psychology,
            title: 'AI Study Assistant',
            description: 'Get personalized help with difficult topics',
            buttonText: 'Ask a Question',
            color: AppTheme.secondaryColor,
            onTap: () {
              _tabController.animateTo(3); // Switch to Doubts tab
            },
          ),
          
          // Study Resources
          _buildFeatureCard(
            icon: Icons.menu_book,
            title: 'Recommended Resources',
            description: 'AI-recommended study materials based on your performance',
            buttonText: 'View Resources',
            color: AppTheme.secondaryColor,
            onTap: () {
              _tabController.animateTo(2); // Switch to Resources tab
            },
          ),
          
          // Class Progress
          _buildFeatureCard(
            icon: Icons.insights,
            title: 'Your Progress',
            description: 'Track your performance and identify areas to improve',
            buttonText: 'View Progress',
            color: AppTheme.secondaryColor,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress tracking coming soon')),
              );
            },
          ),
          
          const SizedBox(height: 24),
          const Text(
            '📢 Class Announcements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No announcements yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
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
                              'Points: ${assignment.totalPoints}',
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
                            // For teachers, show assignment details/submissions
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Assignment details coming soon: ${assignment.title}'),
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
            const CircularProgressIndicator(),
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            widget.classModel.studentCount > 0
                ? 'View ${widget.classModel.studentCount} student${widget.classModel.studentCount == 1 ? '' : 's'}'
                : 'No students enrolled yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          if (widget.classModel.studentCount > 0)
            CustomButton(
              label: 'View Student List',
              icon: Icons.people,
              onPressed: _navigateToStudentsScreen,
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
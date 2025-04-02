import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../utils/error_handler.dart';

class StudentDetailsScreen extends StatefulWidget {
  final StudentModel student;
  final ClassModel classModel;
  final bool isTeacher;

  const StudentDetailsScreen({
    super.key,
    required this.student,
    required this.classModel,
    required this.isTeacher,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _progressData;
  String? _errorMessage;
  late TabController _tabController;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadStudentProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final progress = await _databaseService.getStudentProgress(
        widget.classModel.id,
        widget.student.id,
      );
      setState(() {
        _progressData = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.student.id == FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isCurrentUser ? 'My Profile' : 'Student Profile'),
        backgroundColor: Colors.white,
        foregroundColor: classPrimaryColor,
        elevation: 1,
        iconTheme: IconThemeData(color: classPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: classPrimaryColor,
          labelColor: classPrimaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Progress'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildProgressTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(),
          
          const SizedBox(height: 24),
          
          // Bio Section
          if (widget.student.bio != null && widget.student.bio!.isNotEmpty)
            _buildInfoCard('Bio', [
              Text(
                widget.student.bio!,
                style: const TextStyle(fontSize: 16),
              ),
            ]),
          
          const SizedBox(height: 16),
          
          // Enrollment Information
          _buildInfoCard('Class Enrollment', [
            _buildInfoRow('Class', widget.classModel.name),
            _buildInfoRow('Subject', widget.classModel.subject),
            _buildInfoRow('Role', _getStudentRole()),
            _buildInfoRow('Joined', _formatDate(widget.student.joinedAt)),
          ]),
          
          const SizedBox(height: 16),
          
          // Contact Information
          _buildInfoCard('Contact Information', [
            _buildInfoRow('Email', widget.student.email),
          ]),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          if (widget.isTeacher && widget.student.id != FirebaseAuth.instance.currentUser?.uid)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.email),
                    label: const Text('Send Message'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Messaging feature coming soon')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: classPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove_circle),
                    label: const Text('Remove from Class'),
                    onPressed: () {
                      _confirmRemoveStudent();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return _isLoading
        ? Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(classPrimaryColor),
          ))
        : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Progress',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage ?? 'An unknown error occurred.',
                        style: TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadStudentProgress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: classPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              )
            : _progressData != null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Progress Overview
                        _buildProgressOverview(),
                        
                        const SizedBox(height: 24),
                        
                        // Strengths & Areas for Improvement
                        _buildStrengthsAndWeaknesses(),
                        
                        const SizedBox(height: 24),
                        
                        // Assignment Completion
                        _buildAssignmentCompletion(),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                : const Center(
                    child: Text('No progress data available.'),
                  );
  }

  Widget _buildActivityTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Activity Timeline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Recent activity and engagement metrics will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Activity tracking coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: classPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Coming Soon'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: classPrimaryColor,
          backgroundImage: widget.student.photoUrl != null
              ? NetworkImage(widget.student.photoUrl!)
              : null,
          child: widget.student.photoUrl == null
              ? Text(
                  widget.student.name.isNotEmpty
                      ? widget.student.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          widget.student.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.student.email,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        // Label for self or role
        if (widget.student.id == FirebaseAuth.instance.currentUser?.uid)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: classGradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'You',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: classPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    final int completedAssignments = _progressData?['assignmentsCompleted'] ?? 0;
    final int totalAssignments = _progressData?['totalAssignments'] ?? 0;
    final double averageScore = _progressData?['averageScore'] ?? 0.0;
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: classPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildProgressStat(
                    'Assignments',
                    '$completedAssignments/$totalAssignments',
                    Icons.assignment,
                    classPrimaryColor,
                  ),
                ),
                Expanded(
                  child: _buildProgressStat(
                    'Average Score',
                    '${averageScore.toStringAsFixed(1)}%',
                    Icons.score,
                    averageScore >= 90
                        ? Colors.green
                        : (averageScore >= 70 ? Colors.orange : Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsAndWeaknesses() {
    final List<String> strengths = List<String>.from(_progressData?['strengths'] ?? []);
    final List<String> areasForImprovement = List<String>.from(_progressData?['areasForImprovement'] ?? []);
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Strengths & Areas for Improvement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: classPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Strengths',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            if (strengths.isNotEmpty)
              Column(
                children: strengths.map((strength) => _buildSkillItem(strength, true)).toList(),
              )
            else
              const Text('No strengths identified yet.'),
            
            const SizedBox(height: 16),
            const Text(
              'Areas for Improvement',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            if (areasForImprovement.isNotEmpty)
              Column(
                children: areasForImprovement
                    .map((area) => _buildSkillItem(area, false))
                    .toList(),
              )
            else
              const Text('No areas for improvement identified yet.'),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCompletion() {
    final int completedAssignments = _progressData?['assignmentsCompleted'] ?? 0;
    final int totalAssignments = _progressData?['totalAssignments'] ?? 0;
    final double completionRate = totalAssignments > 0
        ? (completedAssignments / totalAssignments) * 100
        : 0;
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assignment Completion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: classPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '$completedAssignments of $totalAssignments assignments completed',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Text(
                  '${completionRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: classPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalAssignments > 0 ? completedAssignments / totalAssignments : 0,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(classPrimaryColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            // Last active info
            if (_progressData?['lastActive'] != null)
              Text(
                'Last active: ${_formatDate(DateTime.parse(_progressData!['lastActive']))}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 36,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillItem(String skill, bool isStrength) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isStrength ? Icons.check_circle : Icons.info,
            color: isStrength ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              skill,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveStudent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Are you sure you want to remove ${widget.student.name} from the class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _databaseService.removeStudentFromClass(
                  widget.classModel.id,
                  widget.student.id,
                );
                if (mounted) {
                  // Pop back to the students list screen
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${widget.student.name} has been removed from the class')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Error removing student: ${ErrorHandler.getFriendlyErrorMessage(e)}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _getStudentRole() {
    return widget.classModel.ownerId == widget.student.id
        ? 'Teacher'
        : 'Student';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final month = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][date.month - 1];
      return '$month ${date.day}, ${date.year}';
    }
  }
} 
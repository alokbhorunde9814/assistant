import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../utils/error_handler.dart';
import 'student_details_screen.dart';

class ClassStudentsScreen extends StatefulWidget {
  final ClassModel classModel;
  final bool isTeacher;

  const ClassStudentsScreen({
    super.key,
    required this.classModel,
    required this.isTeacher,
  });

  @override
  State<ClassStudentsScreen> createState() => _ClassStudentsScreenState();
}

class _ClassStudentsScreenState extends State<ClassStudentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  List<StudentModel> _students = [];
  String? _errorMessage;

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
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final students = await _databaseService.getStudentsForClass(widget.classModel.id);
      setState(() {
        _students = students;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Students - ${widget.classModel.name}'),
        backgroundColor: Colors.white,
        foregroundColor: classPrimaryColor,
        elevation: 1,
        iconTheme: IconThemeData(color: classPrimaryColor),
        actions: [
          if (widget.isTeacher)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadStudents,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(classPrimaryColor),
            ))
          : _errorMessage != null
              ? _buildErrorView()
              : _students.isEmpty
                  ? _buildEmptyView()
                  : _buildStudentsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
              'Error Loading Students',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unknown error occurred.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStudents,
              style: ElevatedButton.styleFrom(
                backgroundColor: classPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              color: classPrimaryColor,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'No Students Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.isTeacher
                  ? 'Share the class code with your students to invite them to join.'
                  : 'Be the first to join this class!',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: classGradientColors,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.key,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Class Code: ${widget.classModel.code}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.white),
                    onPressed: () {
                      // Logic to copy class code
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Class code copied to clipboard!')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: classGradientColors,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_students.length} Student${_students.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.isTeacher)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.key,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.classModel.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final isCurrentUser = student.id == currentUserId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isCurrentUser
                        ? BorderSide(color: classPrimaryColor, width: 1)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isCurrentUser
                          ? classPrimaryColor
                          : classGradientColors[0].withOpacity(0.7),
                      child: student.photoUrl != null
                          ? null
                          : Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      backgroundImage: student.photoUrl != null
                          ? NetworkImage(student.photoUrl!)
                          : null,
                    ),
                    title: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      student.email,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    trailing: widget.isTeacher
                        ? IconButton(
                            icon: Icon(Icons.more_vert, color: classPrimaryColor),
                            onPressed: () {
                              _showStudentOptions(student);
                            },
                          )
                        : (isCurrentUser
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: classGradientColors,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null),
                    onTap: () {
                      _navigateToStudentDetails(student);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentOptions(StudentModel student) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: classPrimaryColor,
              backgroundImage: student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
              child: student.photoUrl == null
                  ? Text(
                      student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              student.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              student.email,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            ListTile(
              leading: Icon(Icons.person, color: classPrimaryColor),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToStudentDetails(student);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: classPrimaryColor),
              title: const Text('View Assignments'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to student assignments
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View assignments coming soon')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment, color: classPrimaryColor),
              title: const Text('View Progress'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to student progress
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View progress coming soon')),
                );
              },
            ),
            if (widget.isTeacher && student.id != FirebaseAuth.instance.currentUser?.uid) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: const Text('Remove from Class', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveStudent(student);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRemoveStudent(StudentModel student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Are you sure you want to remove ${student.name} from the class?'),
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
                  student.id,
                );
                if (mounted) {
                  _loadStudents(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${student.name} has been removed from the class')),
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

  void _navigateToStudentDetails(StudentModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailsScreen(
          student: student,
          classModel: widget.classModel,
          isTeacher: widget.isTeacher,
        ),
      ),
    );
  }
} 
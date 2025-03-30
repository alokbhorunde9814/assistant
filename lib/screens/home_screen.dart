import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/common_layout.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/theme.dart';
import '../utils/error_handler.dart';
import '../models/class_model.dart';
import 'create_class_screen.dart';
import 'join_class_screen.dart';
import 'class_dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // For showing loading state
  bool _isLoading = false;
  int _notificationCount = 2;
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'AI Teacher Assistant',
        isHomeScreen: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  // Show notifications
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificationCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create/Join Class buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Create Class',
                    icon: Icons.add,
                    onPressed: () {
                      _showCreateClassDialog(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    label: 'Join Class',
                    type: ButtonType.outline,
                    icon: Icons.key,
                    onPressed: () {
                      _navigateToJoinClass();
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Classes section
          Expanded(
            child: _buildClassesContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
          
          // Handle navigation based on the selected tab
          if (index == 3) { // Profile tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ).then((_) {
              // Reset to home tab after returning from profile
              setState(() {
                _currentNavIndex = 0;
              });
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _navigateToJoinClass() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JoinClassScreen()),
    );
    
    if (result != null && result['success'] == true) {
      // The class is already added to Firestore by the JoinClassScreen
      // So we don't need to update state here as the StreamBuilder will refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully joined ${result['name'] ?? 'the class'}!')),
        );
      }
    }
  }

  Widget _buildClassesContent() {
    return StreamBuilder<List<ClassModel>>(
      stream: _databaseService.getAllClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading classes: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        
        final classes = snapshot.data ?? [];
        
        if (classes.isEmpty) {
          return _buildEmptyState();
        }
        
        // Separate owned and joined classes
        final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final ownedClasses = classes.where((c) => c.ownerId == currentUserId).toList();
        final joinedClasses = classes.where((c) => c.ownerId != currentUserId).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Classes I Teach section
                if (ownedClasses.isNotEmpty) ...[
                  _buildSectionHeader('Classes I Teach', Icons.school, AppTheme.primaryColor),
                  ...ownedClasses.map((classModel) => _buildClassTile(classModel, true)),
                  const SizedBox(height: 20),
                ],
                
                // Classes I've Joined section
                if (joinedClasses.isNotEmpty) ...[
                  _buildSectionHeader('Classes I\'ve Joined', Icons.menu_book, AppTheme.secondaryColor),
                  ...joinedClasses.map((classModel) => _buildClassTile(classModel, false)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTile(ClassModel classData, bool isOwner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isOwner ? AppTheme.primaryColor : AppTheme.secondaryColor,
          child: Icon(
            isOwner ? Icons.school : Icons.menu_book,
            color: Colors.white,
          ),
        ),
        title: Text(
          classData.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(classData.subject),
            Text(
              '${classData.studentCount} ${classData.studentCount == 1 ? 'student' : 'students'}'
              + (isOwner ? '' : ' • ${classData.ownerName}'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                classData.code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate to class dashboard
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDashboardScreen(
                classModel: classData,
                isTeacher: isOwner,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Classes Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a class or join one using a class code',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomButton(
                label: 'Create Class',
                icon: Icons.add,
                onPressed: () {
                  _showCreateClassDialog(context);
                },
              ),
              const SizedBox(width: 16),
              CustomButton(
                label: 'Join Class',
                type: ButtonType.outline,
                icon: Icons.key,
                onPressed: () {
                  _navigateToJoinClass();
                },
              ),
            ],
          ),
          
          // Advanced setup button
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: CustomButton(
              label: 'Advanced Class Setup',
              type: ButtonType.text,
              icon: Icons.tune,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateClassScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    bool isCreating = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Quick Class Setup'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      label: 'Class Name',
                      hint: 'e.g., Mathematics 101',
                      controller: nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a class name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Subject',
                      hint: 'e.g., Mathematics',
                      controller: subjectController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    if (isCreating) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              CustomButton(
                label: 'Advanced Setup',
                type: ButtonType.text,
                onPressed: isCreating ? () {} : () {
                  Navigator.pop(context);
                  // Navigate to the full Create Class screen for advanced options
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateClassScreen()),
                  );
                },
              ),
              CustomButton(
                label: isCreating ? 'Creating...' : 'Create',
                onPressed: isCreating ? () {} : () async {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      isCreating = true;
                      errorMessage = null;
                    });
                    
                    try {
                      // Create class in Firestore
                      await _databaseService.createClass(
                        name: nameController.text.trim(),
                        subject: subjectController.text.trim(),
                        description: 'Created via quick setup',
                      );
                      
                      if (mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Class created successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        isCreating = false;
                        errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
                      });
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 
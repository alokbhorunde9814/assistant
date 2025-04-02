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
  bool _showAllCreatedClasses = false;
  bool _showAllJoinedClasses = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'AI Teacher Assistant', 
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // Implement search functionality
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                onPressed: () {
                  // Show notifications
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _notificationCount.toString(),
                      style: const TextStyle(
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
          const SizedBox(width: 8),
          // Profile avatar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create/Join Class buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Class'),
                    onPressed: () {
                      _showCreateClassDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.link, size: 18),
                    label: const Text('Join Class'),
                    onPressed: () {
                      _navigateToJoinClass();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
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
          if (index == 2) { // AI tab
            Navigator.pushNamed(context, '/vertex-ai-chat');
          } else if (index == 3) { // Profile tab
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
        selectedItemColor: const Color(0xFF4285F4),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
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

        // For UI display, limit to 2 classes in each section initially
        final int maxInitialDisplay = 2;
        final displayedOwnedClasses = ownedClasses.length > maxInitialDisplay && !_showAllCreatedClasses 
            ? ownedClasses.sublist(0, maxInitialDisplay) 
            : ownedClasses;
        
        final displayedJoinedClasses = joinedClasses.length > maxInitialDisplay && !_showAllJoinedClasses 
            ? joinedClasses.sublist(0, maxInitialDisplay) 
            : joinedClasses;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Created Classes section
                if (ownedClasses.isNotEmpty) ...[
                  _buildSectionHeader('Created Classes', Icons.folder, const Color(0xFF4285F4)),
                  ...displayedOwnedClasses.map((classModel) => _buildClassTile(classModel, true)),
                  if (ownedClasses.length > maxInitialDisplay) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllCreatedClasses = !_showAllCreatedClasses;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showAllCreatedClasses ? 'Show Less' : 'View All (${ownedClasses.length})',
                              style: const TextStyle(
                                color: Color(0xFF4285F4),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showAllCreatedClasses ? Icons.keyboard_arrow_up : Icons.arrow_forward,
                              size: 16,
                              color: const Color(0xFF4285F4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12), // Spacing when "View All" is not needed
                  ],
                ],
                
                // Joined Classes section
                if (joinedClasses.isNotEmpty) ...[
                  _buildSectionHeader('Joined Classes', Icons.folder_shared, const Color(0xFF7B1FA2)),
                  ...displayedJoinedClasses.map((classModel) => _buildClassTile(classModel, false)),
                  if (joinedClasses.length > maxInitialDisplay) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAllJoinedClasses = !_showAllJoinedClasses;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showAllJoinedClasses ? 'Show Less' : 'View All (${joinedClasses.length})',
                              style: const TextStyle(
                                color: Color(0xFF7B1FA2),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showAllJoinedClasses ? Icons.keyboard_arrow_up : Icons.arrow_forward,
                              size: 16,
                              color: const Color(0xFF7B1FA2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTile(ClassModel classData, bool isOwner) {
    // Use a different color gradient based on the class name's first character
    // This ensures each class gets a consistent but different color
    final String firstChar = classData.name.isNotEmpty ? classData.name[0].toUpperCase() : 'A';
    final int colorSeed = firstChar.codeUnitAt(0) % 6; // Use 6 different color schemes
    
    // Define gradient colors based on whether the user is owner and the color seed
    List<Color> gradientColors;
    Color cardColor;
    
    if (isOwner) {
      // Blue-based gradients for created classes - more subtle variations
      switch (colorSeed) {
        case 0:
          gradientColors = [const Color(0xFF1A73E8), const Color(0xFF3C8CE7)]; // Google blue
          cardColor = const Color(0xFF1A73E8);
          break;
        case 1:
          gradientColors = [const Color(0xFF4285F4), const Color(0xFF5C9EFF)]; // Light blue
          cardColor = const Color(0xFF4285F4);
          break;
        case 2:
          gradientColors = [const Color(0xFF2979FF), const Color(0xFF448AFF)]; // Material blue
          cardColor = const Color(0xFF2979FF);
          break;
        case 3:
          gradientColors = [const Color(0xFF0277BD), const Color(0xFF039BE5)]; // Sky blue
          cardColor = const Color(0xFF0277BD);
          break;
        case 4:
          gradientColors = [const Color(0xFF0288D1), const Color(0xFF29B6F6)]; // Light blue accent
          cardColor = const Color(0xFF0288D1);
          break;
        case 5:
          gradientColors = [const Color(0xFF1565C0), const Color(0xFF42A5F5)]; // Blue to light blue
          cardColor = const Color(0xFF1565C0);
          break;
        default:
          gradientColors = [const Color(0xFF1A73E8), const Color(0xFF3C8CE7)]; // Default blue
          cardColor = const Color(0xFF1A73E8);
      }
    } else {
      // Purple-based gradients for joined classes - more subtle variations
      switch (colorSeed) {
        case 0:
          gradientColors = [const Color(0xFF8E24AA), const Color(0xFFAB47BC)]; // Light purple
          cardColor = const Color(0xFF8E24AA);
          break;
        case 1:
          gradientColors = [const Color(0xFF7B1FA2), const Color(0xFF9C27B0)]; // Medium purple
          cardColor = const Color(0xFF7B1FA2);
          break;
        case 2:
          gradientColors = [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)]; // Dark purple
          cardColor = const Color(0xFF6A1B9A);
          break;
        case 3:
          gradientColors = [const Color(0xFF5E35B1), const Color(0xFF7986CB)]; // Indigo to purple
          cardColor = const Color(0xFF5E35B1);
          break;
        case 4:
          gradientColors = [const Color(0xFF9C27B0), const Color(0xFFCE93D8)]; // Purple to light purple
          cardColor = const Color(0xFF9C27B0);
          break;
        case 5:
          gradientColors = [const Color(0xFF7E57C2), const Color(0xFF9575CD)]; // Deep purple to light
          cardColor = const Color(0xFF7E57C2);
          break;
        default:
          gradientColors = [const Color(0xFF7B1FA2), const Color(0xFF9C27B0)]; // Default purple
          cardColor = const Color(0xFF7B1FA2);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4, // Increased elevation for better shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
        splashColor: cardColor.withOpacity(0.3), // Better splash effect
        highlightColor: cardColor.withOpacity(0.2), // Better highlight effect
        child: Stack(
          children: [
            // Background container with gradient
            Container(
              height: 140, // Fixed height for consistent cards
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
            
            // Top decorative element with gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 70, // Half of the card height
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circular elements for visual interest
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Class content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top section with title and options
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Class name with potential overflow handling
                          Expanded(
                            child: Text(
                              classData.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          
                          // More options button
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              _showClassOptions(context, classData, isOwner);
                            },
                          ),
                        ],
                      ),
                      
                      // Subject or info line
                      Text(
                        classData.subject,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  
                  // Bottom section with additional info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Class code and student count row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Class code
                          Row(
                            children: [
                              Icon(Icons.tag, size: 16, color: cardColor),
                              const SizedBox(width: 4),
                              Text(
                                'Code: ${classData.code}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: cardColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          
                          // Student count
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.people, size: 14, color: cardColor),
                                const SizedBox(width: 4),
                                Text(
                                  '${classData.studentCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cardColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Teacher/Creator name row
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOwner ? Icons.person : Icons.school,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isOwner ? 'Created by you' : 'Created by ${classData.ownerName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show class options in a bottom sheet
  void _showClassOptions(BuildContext context, ClassModel classData, bool isOwner) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF4285F4)),
                title: const Text('View Dashboard'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
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
              
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Color(0xFF4285F4)),
                  title: const Text('Edit Class'),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    // TODO: Add navigation to edit class screen
                    // For now, just show a snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit Class feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Class'),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showDeleteClassConfirmation(context, classData);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Leave Class'),
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showUnenrollConfirmation(context, classData);
                  },
                ),
              ],
              
              ListTile(
                leading: const Icon(Icons.content_copy_outlined, color: Color(0xFF4285F4)),
                title: const Text('Copy Class Code'),
                onTap: () {
                  // Close bottom sheet and copy class code to clipboard
                  Navigator.pop(context);
                  // Implement clipboard functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Class code ${classData.code} copied to clipboard!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Show confirmation dialog for deleting a class
  void _showDeleteClassConfirmation(BuildContext context, ClassModel classData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Class'),
          content: Text(
            'Are you sure you want to delete "${classData.name}"? '
            'This action cannot be undone and will remove all assignments, announcements, and student data.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                
                try {
                  await _databaseService.deleteClass(classData.id);
                  
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Class deleted successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting class: ${e.toString()}'),
                      duration: const Duration(seconds: 4),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Show confirmation dialog for leaving a class
  void _showUnenrollConfirmation(BuildContext context, ClassModel classData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave Class'),
          content: Text(
            'Are you sure you want to leave "${classData.name}"? '
            'You will need the class code to rejoin.'
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                
                try {
                  await _databaseService.leaveClass(classData.id);
                  
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have left the class'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error leaving class: ${e.toString()}'),
                      duration: const Duration(seconds: 4),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Classes Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4285F4),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Class'),
                onPressed: () {
                  _showCreateClassDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Join Class'),
                onPressed: () {
                  _navigateToJoinClass();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
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
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                      ),
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
              TextButton(
                child: Text(
                  'Advanced Setup',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                onPressed: isCreating ? null : () {
                  Navigator.pop(context);
                  // Navigate to the full Create Class screen for advanced options
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateClassScreen()),
                  );
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4285F4),
                ),
                onPressed: isCreating ? null : () async {
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
                child: Text(isCreating ? 'Creating...' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No email';
    final name = user?.displayName ?? 'User';
    final String userInitial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User info header
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF4285F4),
            ),
            accountName: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              email,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userInitial,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
          ),
          
          // Profile & Preferences section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              '👤 Profile & Preferences',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            subtitle: const Text('View & edit profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Change Profile Picture'),
            onTap: () {
              Navigator.pop(context);
              // Implement change profile picture functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Change profile picture coming soon')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy & Security'),
            onTap: () {
              Navigator.pop(context);
              // Implement privacy & security screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy & Security settings coming soon')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('App Settings'),
            subtitle: const Text('Theme, notifications, etc.'),
            onTap: () {
              Navigator.pop(context);
              // Implement app settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App Settings coming soon')),
              );
            },
          ),
          
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode Toggle'),
            value: false, // Replace with actual theme state
            onChanged: (bool value) {
              // Implement theme toggling
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dark mode ${value ? 'enabled' : 'disabled'}')),
              );
            },
          ),
          
          // Communication section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              '💬 Communication',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages & Chat'),
            trailing: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Implement messages screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Messages coming soon')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Announcements'),
            subtitle: const Text('From teachers/admins'),
            onTap: () {
              Navigator.pop(context);
              // Implement announcements screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcements coming soon')),
              );
            },
          ),
          
          // Quick Actions section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              '📌 Quick Actions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.push_pin),
            title: const Text('Pinned Classes'),
            subtitle: const Text('Favorite classes for quick access'),
            onTap: () {
              Navigator.pop(context);
              // Implement pinned classes screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pinned Classes coming soon')),
              );
            },
          ),
          
          // Help & Logout section
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
            child: Text(
              '❓ Help & Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('FAQs, contact support'),
            onTap: () {
              Navigator.pop(context);
              // Implement help screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync Data'),
            onTap: () {
              Navigator.pop(context);
              // Implement sync functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing data...')),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              _showLogoutConfirmationDialog();
            },
          ),
          
          const SizedBox(height: 16),
          
          // App version
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'App Version 1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                setState(() {
                  _isLoading = true;
                });
                await _authService.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/auth');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
} 
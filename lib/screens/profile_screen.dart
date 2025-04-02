import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';
import 'edit_profile_screen.dart';
import 'all_classes_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'Not available';
    final userName = user?.displayName ?? userEmail.split('@').first;
    final userPhotoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Information Section
                  _buildProfileSection(
                    context,
                    userPhotoUrl,
                    userName,
                    userEmail,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Classes Section
                  _buildClassesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // AI Insights Section
                  _buildInsightsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Settings Section
                  _buildSettingsSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    String? photoUrl,
    String name,
    String email,
  ) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.gradientDecoration.copyWith(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            
            // Name, Email and Edit Button
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Edit Profile Button
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                        ).then((_) {
                          // Refresh the profile data when returning from edit screen
                          setState(() {});
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E88E5),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientDecoration.gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.class_, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'My Classes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Classes Stream
            StreamBuilder<List<ClassModel>>(
              stream: _databaseService.getAllClasses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading classes: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                
                final classes = snapshot.data ?? [];
                
                if (classes.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'No classes yet. Join or create a class to get started!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Separate classes into created and joined
                final userId = FirebaseAuth.instance.currentUser?.uid;
                final createdClasses = classes.where((c) => c.ownerId == userId).toList();
                final joinedClasses = classes.where((c) => c.ownerId != userId && c.studentIds.contains(userId)).toList();
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (createdClasses.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Classes You Teach',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...createdClasses.take(2).map(
                        (classModel) => _buildClassTile(
                          classModel.name,
                          classModel.subject,
                          'Created',
                          const Color(0xFF1E88E5),
                        ),
                      ),
                      if (createdClasses.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.visibility, size: 16),
                            label: Text(
                              'View All (${createdClasses.length})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onPressed: () {
                              // Navigate to the screen showing all teaching classes
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllClassesScreen(
                                    classes: createdClasses,
                                    type: "teaching",
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1E88E5),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                    
                    if (joinedClasses.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Classes You\'re Taking',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      ...joinedClasses.take(2).map(
                        (classModel) => _buildClassTile(
                          classModel.name,
                          classModel.subject,
                          'Joined',
                          const Color(0xFF26A69A),
                        ),
                      ),
                      if (joinedClasses.length > 2)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.visibility, size: 16),
                            label: Text(
                              'View All (${joinedClasses.length})',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onPressed: () {
                              // Navigate to the screen showing all enrolled classes
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllClassesScreen(
                                    classes: joinedClasses,
                                    type: "enrolled",
                                  ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF26A69A),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassTile(
    String name,
    String subject,
    String status,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            status == 'Created' ? Icons.person_outline : Icons.school_outlined,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subject,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // Navigate to the class dashboard (to be implemented)
        },
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientDecoration.gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI Insights & Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDD835).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up, 
                          color: Color(0xFFFDD835),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Engagement Analytics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsightItem('Time Spent per Class', '2 hours this week'),
                  const SizedBox(height: 8),
                  _buildInsightItem('AI Feedback Summary', 'Great progress in Math!'),
                  const SizedBox(height: 8),
                  _buildInsightItem('Total Assignments', '12 (8 graded)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: AppTheme.gradientDecoration.gradient,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.gradientDecoration.gradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.settings, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSettingsTile(
                    'Notifications Preferences',
                    Icons.notifications_outlined,
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon')),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios, 
                      size: 16, 
                      color: Colors.grey
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingsTile(
                    'Linked Accounts',
                    Icons.link,
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account linking coming soon')),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios, 
                      size: 16, 
                      color: Colors.grey
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSettingsTile(
                    'Security & Password',
                    Icons.security_outlined,
                    () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Security settings coming soon')),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios, 
                      size: 16, 
                      color: Colors.grey
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap, {Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon, 
              color: const Color(0xFF1E88E5),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final bool confirmLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    ) ?? false;
    
    // If user cancels, don't proceed
    if (!confirmLogout) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _authService.signOut();
      
      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login', 
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 
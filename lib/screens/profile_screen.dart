import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';
import 'edit_profile_screen.dart';

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
      appBar: CustomAppBar(
        title: 'Profile',
        isHomeScreen: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: CustomButton(
                        label: 'Logout',
                        icon: Icons.logout,
                        type: ButtonType.outline,
                        onPressed: _handleLogout,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.purple.shade100,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade400,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Name and Email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: $name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: $email',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Edit Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  ).then((_) {
                    // Refresh the profile data when returning from edit screen
                    setState(() {});
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder, color: Colors.purple, size: 22),
            const SizedBox(width: 8),
            Text(
              'Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Classes Stream
        StreamBuilder<List<ClassModel>>(
          stream: _databaseService.getAllClasses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading classes: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            
            final classes = snapshot.data ?? [];
            
            if (classes.isEmpty) {
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No classes yet. Join or create a class to get started!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }
            
            // Separate classes into created and joined
            final userId = FirebaseAuth.instance.currentUser?.uid;
            final createdClasses = classes.where((c) => c.ownerId == userId).toList();
            final joinedClasses = classes.where((c) => c.ownerId != userId).toList();
            
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ...createdClasses.map(
                    (classModel) => _buildClassTile(
                      classModel.name,
                      classModel.subject,
                      'Created',
                      Colors.purple,
                    ),
                  ),
                  ...joinedClasses.map(
                    (classModel) => _buildClassTile(
                      classModel.name,
                      classModel.subject,
                      'Joined',
                      Colors.pink,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildClassTile(
    String name,
    String subject,
    String status,
    Color color,
  ) {
    final formattedClass = '$subject ($name)';
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(Icons.arrow_right, color: color),
      title: Text(
        formattedClass,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: status == 'Created' ? Colors.purple.withOpacity(0.1) : Colors.pink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            color: status == 'Created' ? Colors.purple : Colors.pink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () {
        // Navigate to the class dashboard (to be implemented)
      },
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.insights, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'AI Insights & Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Card(
          elevation: 1,
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
                    Icon(
                      Icons.trending_up, 
                      color: Colors.pink,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Engagement Analytics (Teacher)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInsightItem('Time Spent per Class', '2 hours this week'),
                const SizedBox(height: 8),
                _buildInsightItem('AI Feedback Summary', 'Great progress in Math!'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightItem(String title, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.purple,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.settings, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                'Notifications Preferences',
                Icons.notifications,
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings coming soon')),
                ),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'Linked Accounts (Google)',
                Icons.link,
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account linking coming soon')),
                ),
              ),
              const Divider(height: 1),
              _buildSettingsTile(
                'Security & Password Reset',
                Icons.security,
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Security settings coming soon')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
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
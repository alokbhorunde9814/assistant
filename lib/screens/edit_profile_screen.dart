import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Notification preferences
  bool _aiFeedbackAlerts = true;
  bool _assignmentReminders = true;
  
  // Authentication information
  bool _isGoogleLinked = false;
  bool _isAppleLinked = false;
  bool _is2FAEnabled = false;
  
  bool _isLoading = false;
  bool _changesMade = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = user.displayName ?? '';
        
        // Check if user has Google provider
        _isGoogleLinked = user.providerData
            .any((info) => info.providerId == 'google.com');
        
        // Check if user has Apple provider
        _isAppleLinked = user.providerData
            .any((info) => info.providerId == 'apple.com');
            
        // These would come from user preferences stored in Firestore
        // For now, just setting default values
        _bioController.text = 'AI Education Enthusiast';
        _phoneController.text = '+1 (555) 123-4567';
      });
    }
  }
  
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update profile information
        await user.updateDisplayName(_nameController.text.trim());
        
        // Here you would also update additional user information in Firestore
        // such as bio, phone, notification preferences, etc.
        
        setState(() {
          _changesMade = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
  
  void _markChangesMade() {
    setState(() {
      _changesMade = true;
    });
  }
  
  Future<void> _changeProfilePicture() async {
    // Show bottom sheet with options to take photo or choose from gallery
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(context);
              // Implement camera functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Camera functionality coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context);
              // Implement gallery picker
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gallery picker coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              // Implement photo removal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remove photo functionality coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: 'Current Password',
              hint: 'Enter your current password',
              controller: currentPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'New Password',
              hint: 'Enter your new password',
              controller: newPasswordController,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Confirm New Password',
              hint: 'Confirm your new password',
              controller: confirmPasswordController,
              obscureText: true,
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
              // Implement password change logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password change coming soon')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'Not available';
    final userPhotoUrl = user?.photoURL;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_changesMade)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              onChanged: _markChangesMade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture Section
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.secondaryColor.withOpacity(0.2),
                            backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                            child: userPhotoUrl == null
                                ? Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _changeProfilePicture,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Basic Information Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              label: 'Name',
                              hint: 'Enter your name',
                              controller: _nameController,
                              prefixIcon: Icons.person,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Email',
                              initialValue: userEmail,
                              prefixIcon: Icons.email,
                              enabled: false,
                              suffixIcon: _isGoogleLinked ? Icons.lock : null,
                              suffixTooltip: _isGoogleLinked 
                                  ? 'Email cannot be changed for Google accounts' 
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Bio',
                              hint: 'Add a short bio...',
                              controller: _bioController,
                              prefixIcon: Icons.info,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Phone',
                              hint: 'Enter your phone number',
                              controller: _phoneController,
                              prefixIcon: Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Notification Preferences Section
                    _buildSectionHeader('Notification Preferences', Icons.notifications),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('AI Feedback Alerts'),
                            subtitle: const Text('Receive alerts for AI-generated feedback'),
                            value: _aiFeedbackAlerts,
                            onChanged: (value) {
                              setState(() {
                                _aiFeedbackAlerts = value;
                                _changesMade = true;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Assignment Reminders'),
                            subtitle: const Text('Receive reminders for upcoming assignments'),
                            value: _assignmentReminders,
                            onChanged: (value) {
                              setState(() {
                                _assignmentReminders = value;
                                _changesMade = true;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Security Settings Section
                    _buildSectionHeader('Security Settings', Icons.security),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.lock_reset, color: AppTheme.secondaryColor),
                            title: const Text('Change Password'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: _showChangePasswordDialog,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Two-Factor Authentication'),
                            subtitle: const Text('Add an extra layer of security'),
                            secondary: const Icon(Icons.security, color: AppTheme.secondaryColor),
                            value: _is2FAEnabled,
                            onChanged: (value) {
                              setState(() {
                                _is2FAEnabled = value;
                                _changesMade = true;
                                
                                // Show coming soon message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('2FA functionality coming soon')),
                                );
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Linked Accounts Section
                    _buildSectionHeader('Linked Accounts', Icons.link),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Image.asset(
                                'assets/google_logo.png',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            title: const Text('Google'),
                            subtitle: Text(_isGoogleLinked ? 'Linked' : 'Not Linked'),
                            trailing: _isGoogleLinked
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () {
                                      // Implement Google linking
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Google linking coming soon')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Link'),
                                  ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.apple, color: Colors.white, size: 20),
                            ),
                            title: const Text('Apple'),
                            subtitle: Text(_isAppleLinked ? 'Linked' : 'Not Linked'),
                            trailing: _isAppleLinked
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : ElevatedButton(
                                    onPressed: () {
                                      // Implement Apple linking
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Apple linking coming soon')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Link'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Changes Button
                    Center(
                      child: CustomButton(
                        label: 'Save Changes',
                        icon: Icons.save,
                        fullWidth: true,
                        onPressed: (_isLoading || !_changesMade) 
                            ? () {}
                            : _saveChanges,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 
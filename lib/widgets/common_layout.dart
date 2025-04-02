import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/search_screen.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class CommonLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showDrawer;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final int currentNavIndex;
  final Function(int)? onNavIndexChanged;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showSearch;
  final Function(String)? onSearch;
  final String searchHint;
  final bool showNotification;
  final int notificationCount;
  final VoidCallback? onNotificationTap;

  const CommonLayout({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showDrawer = true,
    this.showBackButton = false,
    this.onBackPressed,
    this.currentNavIndex = 0,
    this.onNavIndexChanged,
    this.scaffoldKey,
    this.showSearch = false,
    this.onSearch,
    this.searchHint = 'Search...',
    this.showNotification = false,
    this.notificationCount = 0,
    this.onNotificationTap,
  });

  // Show confirmation dialog before logging out
  Future<bool> _confirmLogout(BuildContext context) async {
    return await showDialog(
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
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.menu_book, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              )
            : showDrawer
                ? IconButton(
                    icon: Icon(Icons.menu, color: AppTheme.primaryColor),
                    onPressed: () {
                      if (scaffoldKey != null) {
                        scaffoldKey!.currentState?.openDrawer();
                      }
                    },
                  )
                : null,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.primaryColor),
            onPressed: () {
              print('Search icon clicked');
              // Use direct navigation instead of named route
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              ).then((value) {
                print('Returned from SearchScreen');
              });
            },
          ),
          if (showNotification)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: AppTheme.primaryColor),
                  onPressed: onNotificationTap ?? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications')),
                    );
                  },
                ),
                if (notificationCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(width: 8),
          if (user != null)
            GestureDetector(
              onTap: () {
                _showProfileOptions(context);
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                backgroundColor: AppTheme.primaryColor,
                child: user.photoURL == null
                    ? Text(
                        user.displayName?.isNotEmpty == true
                            ? user.displayName![0].toUpperCase()
                            : (user.email?.isNotEmpty == true ? user.email![0].toUpperCase() : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
          const SizedBox(width: 16),
          if (actions != null) ...actions!,
        ],
      ),
      drawer: showDrawer ? _buildDrawer(context, user) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSearch)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Text(
                        searchHint,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar ?? (onNavIndexChanged != null ? _buildBottomNav() : null),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    final authService = AuthService();
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientDecoration.gradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                  backgroundColor: Colors.white,
                  child: user?.photoURL == null
                      ? Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U'),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  user?.displayName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text('My Classes'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Assignments'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // Show confirmation dialog
              final bool confirmLogout = await _confirmLogout(context);
              
              // If user cancels, don't proceed
              if (!confirmLogout) return;
              
              try {
                await authService.signOut();
                Navigator.pop(context);
                // AuthenticationWrapper will handle navigation
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: currentNavIndex,
      onTap: onNavIndexChanged,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey.shade600,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Tasks',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_outlined),
              if (notificationCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 10,
                      minHeight: 10,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Notifications',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  void _showProfileOptions(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              backgroundColor: AppTheme.primaryColor,
              child: user?.photoURL == null
                  ? Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : 'U'),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit profile
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                // Show confirmation dialog
                final bool confirmLogout = await _confirmLogout(context);
                
                // If user cancels, don't proceed
                if (!confirmLogout) return;
                
                try {
                  await authService.signOut();
                  Navigator.pop(context);
                  // AuthenticationWrapper will handle navigation
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error signing out: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
} 
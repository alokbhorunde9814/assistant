import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Add debug print to see what's happening
        print('Auth state changed: hasData=${snapshot.hasData}, connectionState=${snapshot.connectionState}');
        
        // Show loading indicator while waiting for authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check for errors
        if (snapshot.hasError) {
          print('Auth stream error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Text('Authentication Error: ${snapshot.error}'),
            ),
          );
        }

        // If user data exists, they're authenticated
        if (snapshot.hasData) {
          print('User is authenticated: ${snapshot.data?.uid}');
          
          // Use pushReplacement to replace the current route with HomeScreen
          // This prevents stack build-up and back button issues
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
          
          // Show loading while navigating
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Not authenticated, show login screen
        print('User is not authenticated, showing login screen');
        return const LoginScreen();
      },
    );
  }
} 
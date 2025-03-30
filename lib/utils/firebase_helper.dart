import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseHelper {
  /// Shows Android-specific SHA-1 setup instructions
  static void showAndroidSignInTroubleshootingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Android SHA-1 Setup Required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'To use Google Sign-In on Android, you need to add your SHA-1 fingerprint:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Get your SHA-1 fingerprint by running:'),
              SizedBox(height: 8),
              Text(
                'cd android && ./gradlew signingReport',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, backgroundColor: Color(0xFFF5F5F5)),
              ),
              SizedBox(height: 16),
              Text('2. In Firebase Console:'),
              Text('   • Go to Project Settings'),
              Text('   • Select your Android app'),
              Text('   • Click "Add fingerprint"'),
              Text('   • Paste your SHA-1 value and save'),
              SizedBox(height: 16),
              Text('3. Download the updated google-services.json'),
              Text('4. Replace your existing file in android/app/'),
              SizedBox(height: 24),
              Text(
                'After making these changes, restart your app.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows a comprehensive dialog with steps to fix common Firebase Google Sign-In issues
  static void showGoogleSignInTroubleshootingDialog(BuildContext context) {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Google Sign-In Unavailable'),
          content: const SingleChildScrollView(
            child: Text(
              'Google Sign-In has been disabled for web in this app. It is only available on Android and iOS.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Google Sign-In Troubleshooting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Follow these steps to fix Google Sign-In:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('1. Go to Firebase Console'),
                Text('2. Select your project'),
                Text('3. Go to Authentication → Sign-in method'),
                Text('4. Enable Google as a sign-in provider'),
                Text('5. Add your support email'),
                Text('6. Save the changes'),
                SizedBox(height: 16),
                Text(
                  'For Android:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Make sure google-services.json is up to date'),
                Text('• Add SHA-1 fingerprint to your Firebase project'),
                SizedBox(height: 16),
                Text(
                  'For iOS:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Verify your Bundle ID matches Firebase config'),
                Text('• Make sure GoogleService-Info.plist is up to date'),
                SizedBox(height: 24),
                Text(
                  'After making these changes, restart your app.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
} 
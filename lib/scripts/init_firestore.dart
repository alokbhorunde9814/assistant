import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get Firestore instance
  final firestore = FirebaseFirestore.instance;

  // Create collections if they don't exist
  final collections = [
    'classes',
    'users',
    'announcements',
    'assignments',
    'resources',
    'submissions',
  ];

  for (final collection in collections) {
    try {
      // Try to create a dummy document to ensure the collection exists
      await firestore.collection(collection).doc('init').set({
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Created collection: $collection');
    } catch (e) {
      print('Error creating collection $collection: $e');
    }
  }

  // Set up security rules
  final rules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isClassMember(classId) {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/classes/$(classId)/students/$(request.auth.uid));
    }
    
    // Classes collection
    match /classes/{classId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(resource.data.ownerId);
      
      // Class students subcollection
      match /students/{studentId} {
        allow read: if isAuthenticated();
        allow write: if isOwner(resource.data.ownerId);
      }
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isOwner(userId);
    }
    
    // Announcements collection
    match /announcements/{announcementId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(resource.data.authorId);
    }
    
    // Assignments collection
    match /assignments/{assignmentId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(resource.data.ownerId);
    }
    
    // Resources collection
    match /resources/{resourceId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(resource.data.ownerId);
    }
    
    // Submissions collection
    match /submissions/{submissionId} {
      allow read: if isAuthenticated() && (
        isOwner(resource.data.studentId) || 
        isOwner(resource.data.ownerId)
      );
      allow create: if isAuthenticated() && isClassMember(resource.data.classId);
      allow update: if isAuthenticated() && (
        isOwner(resource.data.studentId) || 
        isOwner(resource.data.ownerId)
      );
      allow delete: if isOwner(resource.data.ownerId);
    }
  }
}
''';

  try {
    // Note: Security rules need to be set in the Firebase Console
    print('Please copy these security rules to your Firebase Console:');
    print(rules);
  } catch (e) {
    print('Error setting security rules: $e');
  }

  print('Firestore initialization complete!');
} 
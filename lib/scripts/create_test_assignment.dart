import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting script...');
  
  try {
    print('Step 1: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    print('Step 2: Getting Firestore instance...');
    final firestore = FirebaseFirestore.instance;
    print('Firestore instance obtained');

    print('Step 3: Creating test class...');
    // Create a test class first
    final classRef = firestore.collection('classes').doc();
    final classData = {
      'id': classRef.id,
      'name': 'Test Class',
      'code': 'TEST123',
      'description': 'Test class for assignment submission',
      'ownerId': 'test_teacher',
      'ownerName': 'Test Teacher',
      'subject': 'Test Subject',
      'studentIds': ['VKMuiKY4A0PmhvlTYvd9NJBM7D73'], // Your user ID
      'createdAt': FieldValue.serverTimestamp(),
      'hasAutomatedGrading': true,
      'hasAiFeedback': true,
    };
    await classRef.set(classData);
    print('Test class created with ID: ${classRef.id}');

    print('Step 4: Creating test assignment...');
    final assignmentRef = firestore.collection('assignments').doc();
    final assignmentData = {
      'id': assignmentRef.id,
      'classId': classRef.id,
      'title': 'Test Assignment',
      'description': 'Please submit your PDF file for this test assignment.',
      'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      'points': 100,
      'isAutoGraded': true,
      'hasAiFeedback': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'attachments': [],
      'status': 'active',
    };
    await assignmentRef.set(assignmentData);
    print('Test assignment created with ID: ${assignmentRef.id}');
    
    print('Script completed successfully!');
    print('Class ID: ${classRef.id}');
    print('Assignment ID: ${assignmentRef.id}');
    
  } catch (e, stackTrace) {
    print('Error occurred:');
    print('Error message: $e');
    print('Stack trace: $stackTrace');
  }
} 
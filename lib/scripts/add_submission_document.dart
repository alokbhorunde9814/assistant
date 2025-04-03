import 'package:flutter/material.dart';
import 'dart:io';
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

    print('Step 3: Creating document reference...');
    final docRef = firestore.collection('submissions').doc();
    print('Document reference created with ID: ${docRef.id}');
    
    print('Step 4: Preparing submission data...');
    final submissionData = {
      'id': docRef.id,
      'assignmentId': 'test_assignment_1',
      'classId': 'test_class_1',
      'studentId': 'test_student_1',
      'studentName': 'Test Student',
      'studentPhotoUrl': null,
      'content': 'This is a test submission',
      'fileUrls': ['https://example.com/test.pdf'],
      'submittedAt': FieldValue.serverTimestamp(),
      'notes': 'Test submission for initial setup',
      'isGraded': false,
      'score': 0.0,
      'feedback': null,
      'isAiFeedbackGenerated': false,
      'isAiFeedbackReviewed': false,
      'aiFeedback': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp()
    };
    print('Submission data prepared');

    print('Step 5: Attempting to write document...');
    await docRef.set(submissionData);
    print('Document written successfully');

    print('Step 6: Verifying document...');
    final doc = await docRef.get();
    if (doc.exists) {
      print('Document verified successfully');
      print('Document data: ${doc.data()}');
    } else {
      print('Error: Document verification failed - document does not exist');
    }
    
    print('Script completed successfully!');
    
  } catch (e, stackTrace) {
    print('Error occurred:');
    print('Error message: $e');
    print('Stack trace: $stackTrace');
  }
  
  // Exit the script
  exit(0);
} 
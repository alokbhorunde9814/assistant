import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  
  try {
    print('Creating submissions collection...');
    
    // Create a test submission document
    final submissionData = {
      'id': 'test_submission',
      'assignmentId': 'test_assignment',
      'classId': 'test_class',
      'studentId': 'test_student',
      'studentName': 'Test Student',
      'studentPhotoUrl': null,
      'content': 'Test submission content',
      'fileUrls': ['https://example.com/test.pdf'],
      'submittedAt': FieldValue.serverTimestamp(),
      'notes': 'Test notes',
      'isGraded': false,
      'score': 0.0,
      'feedback': null,
      'isAiFeedbackGenerated': false,
      'isAiFeedbackReviewed': false,
      'aiFeedback': null
    };

    await firestore.collection('submissions').doc('test_submission').set(submissionData);
    print('Successfully created submissions collection with test document!');
    
    // Verify the collection exists
    final snapshot = await firestore.collection('submissions').get();
    print('Number of documents in submissions collection: ${snapshot.docs.length}');
    
  } catch (e) {
    print('Error creating submissions collection: $e');
  }
} 
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/class_model.dart';
import '../models/announcement_model.dart';
import '../models/assignment_model.dart';
import '../models/resource_model.dart';
import '../models/student_model.dart';
import '../models/submission_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  final CollectionReference _classesCollection = 
      FirebaseFirestore.instance.collection('classes');
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _announcementsCollection = 
      FirebaseFirestore.instance.collection('announcements');
  final CollectionReference _assignmentsCollection = 
      FirebaseFirestore.instance.collection('assignments');
  final CollectionReference _resourcesCollection = 
      FirebaseFirestore.instance.collection('resources');
  final CollectionReference _submissionsCollection = 
      FirebaseFirestore.instance.collection('submissions');
  
  // Get current user ID or throw error if not logged in
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }
  
  // Get current user display name or email
  String get _currentUserName {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.displayName ?? user.email ?? 'Unknown user';
  }
  
  // Generate a unique class code
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Create a new class
  Future<ClassModel> createClass({
    required String name,
    required String subject,
    required String description,
    bool hasAutomatedGrading = false,
    bool hasAiFeedback = false,
  }) async {
    try {
      // Generate a unique class code
      final code = _generateClassCode();
      
      // Create class document data
      final classData = ClassModel(
        id: '', // Will be set after document creation
        name: name,
        code: code,
        description: description,
        ownerId: _currentUserId,
        ownerName: _currentUserName,
        subject: subject,
        studentIds: [], // No students initially
        createdAt: DateTime.now(),
        hasAutomatedGrading: hasAutomatedGrading,
        hasAiFeedback: hasAiFeedback,
      ).toFirestore();
      
      // Add the class to Firestore
      final docRef = await _classesCollection.add(classData);
      
      // Update the class with its document ID
      await docRef.update({'id': docRef.id});
      
      // Get the updated class
      final docSnapshot = await docRef.get();
      return ClassModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error creating class: $e');
      rethrow;
    }
  }
  
  // Join a class using a class code
  Future<ClassModel> joinClassWithCode(String code) async {
    try {
      // Find the class with the given code
      final querySnapshot = await _classesCollection
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Class not found with this code');
      }
      
      final classDoc = querySnapshot.docs.first;
      final classModel = ClassModel.fromFirestore(classDoc);
      
      // Check if user is already in the class
      if (classModel.hasStudent(_currentUserId)) {
        throw Exception('You are already a member of this class');
      }
      
      // Add user to the class
      final updatedStudentIds = [...classModel.studentIds, _currentUserId];
      await classDoc.reference.update({'studentIds': updatedStudentIds});
      
      // Get the updated class
      final updatedDoc = await classDoc.reference.get();
      return ClassModel.fromFirestore(updatedDoc);
    } catch (e) {
      print('Error joining class: $e');
      rethrow;
    }
  }
  
  // Get classes where user is the owner
  Stream<List<ClassModel>> getOwnedClasses() {
    return _classesCollection
        .where('ownerId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }
  
  // Get classes where user is a student
  Stream<List<ClassModel>> getJoinedClasses() {
    return _classesCollection
        .where('studentIds', arrayContains: _currentUserId)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }
  
  // Get all classes for a user (both owned and joined)
  Stream<List<ClassModel>> getAllClasses() {
    // Combine owned and joined classes streams
    return _firestore.collection('classes')
        .where(Filter.or(
          Filter('ownerId', isEqualTo: _currentUserId),
          Filter('studentIds', arrayContains: _currentUserId)
        ))
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ClassModel.fromFirestore(doc)).toList());
  }
  
  // Check if a class code exists
  Future<bool> classCodeExists(String code) async {
    final querySnapshot = await _classesCollection
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    
    return querySnapshot.docs.isNotEmpty;
  }
  
  // Get a class by ID
  Future<ClassModel?> getClassById(String classId) async {
    try {
      final docSnapshot = await _classesCollection.doc(classId).get();
      if (!docSnapshot.exists) {
        return null;
      }
      return ClassModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error getting class: $e');
      rethrow;
    }
  }

  // ========== ANNOUNCEMENTS METHODS ==========

  // Create a new announcement for a class
  Future<AnnouncementModel> createAnnouncement({
    required String classId,
    required String title,
    required String content,
    List<String> attachmentUrls = const [],
  }) async {
    try {
      // Verify the user is the class owner
      final classDoc = await _classesCollection.doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }
      
      final classModel = ClassModel.fromFirestore(classDoc);
      if (classModel.ownerId != _currentUserId) {
        throw Exception('Only the class owner can create announcements');
      }
      
      // Create announcement document data
      final announcementData = AnnouncementModel(
        id: '', // Will be set after document creation
        classId: classId,
        title: title,
        content: content,
        authorId: _currentUserId,
        authorName: _currentUserName,
        createdAt: DateTime.now(),
        attachmentUrls: attachmentUrls,
      ).toFirestore();
      
      // Add the announcement to Firestore
      final docRef = await _announcementsCollection.add(announcementData);
      
      // Update the announcement with its document ID
      await docRef.update({'id': docRef.id});
      
      // Get the updated announcement
      final docSnapshot = await docRef.get();
      return AnnouncementModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error creating announcement: $e');
      rethrow;
    }
  }

  // Get all announcements for a class
  Stream<List<AnnouncementModel>> getAnnouncementsForClass(String classId) {
    return _announcementsCollection
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => AnnouncementModel.fromFirestore(doc)).toList());
  }

  // ========== ASSIGNMENTS METHODS ==========

  // Create a new assignment for a class
  Future<AssignmentModel> createAssignment({
    required String classId,
    required String title,
    required String description,
    required DateTime dueDate,
    required int totalPoints,
    bool isAutoGraded = false,
    List<String> resourceUrls = const [],
    Map<String, dynamic> aiData = const {},
  }) async {
    try {
      // Verify the user is the class owner
      final classDoc = await _classesCollection.doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }
      
      final classModel = ClassModel.fromFirestore(classDoc);
      if (classModel.ownerId != _currentUserId) {
        throw Exception('Only the class owner can create assignments');
      }
      
      // Create assignment document data
      final assignmentData = AssignmentModel(
        id: '', // Will be set after document creation
        classId: classId,
        title: title,
        description: description,
        authorId: _currentUserId,
        authorName: _currentUserName,
        createdAt: DateTime.now(),
        dueDate: dueDate,
        totalPoints: totalPoints,
        isAutoGraded: isAutoGraded,
        resourceUrls: resourceUrls,
        aiData: aiData,
      ).toFirestore();
      
      // Add the assignment to Firestore
      final docRef = await _assignmentsCollection.add(assignmentData);
      
      // Update the assignment with its document ID
      await docRef.update({'id': docRef.id});
      
      // Get the updated assignment
      final docSnapshot = await docRef.get();
      return AssignmentModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error creating assignment: $e');
      rethrow;
    }
  }

  // Get all assignments for a class
  Stream<List<AssignmentModel>> getAssignmentsForClass(String classId) {
    return _assignmentsCollection
        .where('classId', isEqualTo: classId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => AssignmentModel.fromFirestore(doc)).toList());
  }

  // ========== RESOURCES METHODS ==========

  // Create a new resource for a class
  Future<ResourceModel> createResource({
    required String classId,
    required String title,
    required String description,
    required String url,
    required ResourceType type,
    bool isAiRecommended = false,
    Map<String, dynamic> aiData = const {},
  }) async {
    try {
      // Verify the user is the class owner
      final classDoc = await _classesCollection.doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }
      
      final classModel = ClassModel.fromFirestore(classDoc);
      if (classModel.ownerId != _currentUserId) {
        throw Exception('Only the class owner can add resources');
      }
      
      // Create resource document data
      final resourceData = ResourceModel(
        id: '', // Will be set after document creation
        classId: classId,
        title: title,
        description: description,
        url: url,
        authorId: _currentUserId,
        authorName: _currentUserName,
        createdAt: DateTime.now(),
        type: type,
        isAiRecommended: isAiRecommended,
        aiData: aiData,
      ).toFirestore();
      
      // Add the resource to Firestore
      final docRef = await _resourcesCollection.add(resourceData);
      
      // Update the resource with its document ID
      await docRef.update({'id': docRef.id});
      
      // Get the updated resource
      final docSnapshot = await docRef.get();
      return ResourceModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error creating resource: $e');
      rethrow;
    }
  }

  // Get all resources for a class
  Stream<List<ResourceModel>> getResourcesForClass(String classId) {
    return _resourcesCollection
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => ResourceModel.fromFirestore(doc)).toList());
  }

  // ========== STUDENTS METHODS ==========

  // Get all students for a class
  Future<List<StudentModel>> getStudentsForClass(String classId) async {
    try {
      // Get the class to check ownership and get student IDs
      final classDoc = await _classesCollection.doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }

      final classModel = ClassModel.fromFirestore(classDoc);
      
      // Check if user is owner or member of the class
      if (classModel.ownerId != _currentUserId && !classModel.hasStudent(_currentUserId)) {
        throw Exception('You do not have permission to view students in this class');
      }

      // If no students, return empty list
      if (classModel.studentIds.isEmpty) {
        return [];
      }

      // Get user data for each student
      List<StudentModel> students = [];
      
      // Get all users from Firebase Auth who are in the class
      for (String studentId in classModel.studentIds) {
        try {
          // Try to get user from Firestore first (if they have a profile)
          final userDoc = await _usersCollection.doc(studentId).get();
          
          if (userDoc.exists) {
            // User has a profile in Firestore
            students.add(StudentModel.fromFirestore(userDoc));
          } else {
            // Otherwise create a basic student model with just the user ID
            // In a real app, you would get more info from Firebase Auth
            students.add(StudentModel(
              id: studentId,
              name: 'Student ${students.length + 1}', // Placeholder name
              email: 'student${students.length + 1}@example.com', // Placeholder email
              joinedAt: DateTime.now(),
            ));
          }
        } catch (e) {
          print('Error getting student $studentId: $e');
          // Continue with next student
        }
      }
      
      return students;
    } catch (e) {
      print('Error getting students: $e');
      rethrow;
    }
  }

  // Get a specific student by ID
  Future<StudentModel?> getStudentById(String studentId) async {
    try {
      final docSnapshot = await _usersCollection.doc(studentId).get();
      if (!docSnapshot.exists) {
        return null;
      }
      return StudentModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error getting student: $e');
      rethrow;
    }
  }

  // Remove a student from a class
  Future<void> removeStudentFromClass(String classId, String studentId) async {
    try {
      // Get the class
      final classDoc = await _classesCollection.doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }
      
      final classModel = ClassModel.fromFirestore(classDoc);
      
      // Check if user is the class owner
      if (classModel.ownerId != _currentUserId) {
        throw Exception('Only the class owner can remove students');
      }
      
      // Update the class by removing the student
      final updatedStudentIds = classModel.studentIds.where((id) => id != studentId).toList();
      await _classesCollection.doc(classId).update({'studentIds': updatedStudentIds});
    } catch (e) {
      print('Error removing student: $e');
      rethrow;
    }
  }

  // Get student progress for a specific class
  Future<Map<String, dynamic>> getStudentProgress(String classId, String studentId) async {
    try {
      // Verify the user is authorized to view this data
      final classDoc = await _classesCollection.doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }
      
      final classModel = ClassModel.fromFirestore(classDoc);
      
      // Check if user is owner, the student themselves, or a parent (to be implemented)
      if (classModel.ownerId != _currentUserId && 
          _currentUserId != studentId) {
        throw Exception('You do not have permission to view this student\'s progress');
      }
      
      // Get student's progress (placeholder - in a real app, you'd have a progress collection)
      // For now, return mock data
      return {
        'assignmentsCompleted': 5,
        'totalAssignments': 10,
        'averageScore': 85.5,
        'lastActive': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'strengths': ['Mathematics', 'Problem Solving'],
        'areasForImprovement': ['Time Management', 'Reading Comprehension'],
      };
    } catch (e) {
      print('Error getting student progress: $e');
      rethrow;
    }
  }

  // ========== SUBMISSIONS METHODS ==========

  // Submit an assignment
  Future<SubmissionModel> submitAssignment({
    required String assignmentId,
    required String classId,
    required List<String> fileUrls,
    String notes = '',
  }) async {
    try {
      // Get the assignment to check if it exists and is still open for submission
      final assignmentDoc = await _assignmentsCollection.doc(assignmentId).get();
      if (!assignmentDoc.exists) {
        throw Exception('Assignment not found');
      }
      
      final assignmentModel = AssignmentModel.fromFirestore(assignmentDoc);
      
      // Check if the assignment is past due date
      final bool isLate = DateTime.now().isAfter(assignmentModel.dueDate);
      final SubmissionStatus status = isLate ? SubmissionStatus.late : SubmissionStatus.submitted;
      
      // Check if the student is in this class
      final classDoc = await _classesCollection.doc(classId).get();
      if (!classDoc.exists) {
        throw Exception('Class not found');
      }
      
      final classModel = ClassModel.fromFirestore(classDoc);
      if (!classModel.hasStudent(_currentUserId) && classModel.ownerId != _currentUserId) {
        throw Exception('You are not enrolled in this class');
      }
      
      // Mark any previous submissions as not latest
      final previousSubmissions = await _submissionsCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: _currentUserId)
          .where('isLatest', isEqualTo: true)
          .get();
      
      for (var doc in previousSubmissions.docs) {
        await doc.reference.update({'isLatest': false});
      }
      
      // Create submission document data
      final submissionData = SubmissionModel(
        id: '', // Will be set after document creation
        assignmentId: assignmentId,
        classId: classId,
        studentId: _currentUserId,
        studentName: _currentUserName,
        submittedAt: DateTime.now(),
        fileUrls: fileUrls,
        notes: notes,
        status: status,
        isLatest: true,
      ).toFirestore();
      
      // Add the submission to Firestore
      final docRef = await _submissionsCollection.add(submissionData);
      
      // Update the submission with its document ID
      await docRef.update({'id': docRef.id});
      
      // Generate AI feedback if enabled
      if (assignmentModel.isAutoGraded) {
        // In a real app, you would call an AI service here
        // For now, we'll simulate AI feedback with mock data
        final Map<String, dynamic> aiFeedback = {
          'score': 85,
          'feedbackPoints': [
            'Good work on explaining the core concepts',
            'Consider adding more examples to illustrate your points',
            'The conclusion could be strengthened with a summary of key takeaways',
          ],
          'suggestedImprovements': 'Try to connect your ideas more explicitly to the assignment prompt.'
        };
        
        await docRef.update({'aiFeedback': aiFeedback});
      }
      
      // Get the updated submission
      final docSnapshot = await docRef.get();
      return SubmissionModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('Error submitting assignment: $e');
      rethrow;
    }
  }
  
  // Get all submissions for a specific student and assignment
  Future<List<SubmissionModel>> getSubmissionsForStudentAssignment(
    String assignmentId, 
    String studentId,
  ) async {
    try {
      final querySnapshot = await _submissionsCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting submissions: $e');
      rethrow;
    }
  }
  
  // Get the latest submission for a student and assignment
  Future<SubmissionModel?> getLatestSubmission(String assignmentId, String studentId) async {
    try {
      final querySnapshot = await _submissionsCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: studentId)
          .where('isLatest', isEqualTo: true)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      return SubmissionModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting latest submission: $e');
      rethrow;
    }
  }
  
  // Get all submissions for an assignment (teacher only)
  Future<List<SubmissionModel>> getAllSubmissionsForAssignment(String assignmentId) async {
    try {
      // Get the assignment to check ownership
      final assignmentDoc = await _assignmentsCollection.doc(assignmentId).get();
      if (!assignmentDoc.exists) {
        throw Exception('Assignment not found');
      }
      
      final assignmentModel = AssignmentModel.fromFirestore(assignmentDoc);
      
      // Check if the user is the class owner
      final classDoc = await _classesCollection.doc(assignmentModel.classId).get();
      final classModel = ClassModel.fromFirestore(classDoc);
      
      if (classModel.ownerId != _currentUserId) {
        throw Exception('Only the class owner can view all submissions');
      }
      
      // Get all latest submissions for this assignment
      final querySnapshot = await _submissionsCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .where('isLatest', isEqualTo: true)
          .orderBy('submittedAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all submissions: $e');
      rethrow;
    }
  }
  
  // Grade a submission (teacher only)
  Future<SubmissionModel> gradeSubmission({
    required String submissionId,
    required int score,
    required String feedback,
  }) async {
    try {
      // Get the submission
      final submissionDoc = await _submissionsCollection.doc(submissionId).get();
      if (!submissionDoc.exists) {
        throw Exception('Submission not found');
      }
      
      final submissionModel = SubmissionModel.fromFirestore(submissionDoc);
      
      // Get the class to check ownership
      final classDoc = await _classesCollection.doc(submissionModel.classId).get();
      final classModel = ClassModel.fromFirestore(classDoc);
      
      if (classModel.ownerId != _currentUserId) {
        throw Exception('Only the class owner can grade submissions');
      }
      
      // Update the submission with grade and feedback
      await _submissionsCollection.doc(submissionId).update({
        'status': 'graded',
        'score': score,
        'feedback': feedback,
      });
      
      // Get the updated submission
      final updatedDoc = await _submissionsCollection.doc(submissionId).get();
      return SubmissionModel.fromFirestore(updatedDoc);
    } catch (e) {
      print('Error grading submission: $e');
      rethrow;
    }
  }
  
  // Check if a student has submitted an assignment
  Future<bool> hasSubmittedAssignment(String assignmentId) async {
    try {
      final querySnapshot = await _submissionsCollection
          .where('assignmentId', isEqualTo: assignmentId)
          .where('studentId', isEqualTo: _currentUserId)
          .where('isLatest', isEqualTo: true)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking submission status: $e');
      rethrow;
    }
  }
} 
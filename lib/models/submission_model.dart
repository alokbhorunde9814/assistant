import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum SubmissionStatus {
  notSubmitted,
  submitted,
  graded,
  returned
}

class SubmissionModel {
  final String id;
  final String classId;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String? studentPhotoUrl;
  final String content;
  final List<String> fileUrls; // This will store Firebase Storage URLs
  final List<String> fileNames; // Store original file names
  final List<String> filePaths; // Store Firebase Storage paths
  final DateTime? submittedAt;
  final bool isGraded;
  final double? score;
  final String? feedback;
  final bool isAiFeedbackGenerated;
  final bool isAiFeedbackReviewed;
  final Map<String, dynamic>? aiData;
  final String? notes;
  final Map<String, dynamic>? aiFeedback;
  final Map<String, int> pageCounts;

  SubmissionModel({
    required this.id,
    required this.classId,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    this.studentPhotoUrl,
    this.content = '',
    this.fileUrls = const [],
    this.fileNames = const [],
    this.filePaths = const [],
    this.submittedAt,
    this.isGraded = false,
    this.score,
    this.feedback,
    this.isAiFeedbackGenerated = false,
    this.isAiFeedbackReviewed = false,
    this.aiData,
    this.notes,
    this.aiFeedback,
    this.pageCounts = const {},
  });
  
  // Create an empty submission with default values
  factory SubmissionModel.empty() {
    return SubmissionModel(
      id: '',
      classId: '',
      assignmentId: '',
      studentId: '',
      studentName: '',
      content: '',
    );
  }
  
  // Create a submission from a Firestore document
  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubmissionModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentPhotoUrl: data['studentPhotoUrl'],
      content: data['content'] ?? '',
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      fileNames: List<String>.from(data['fileNames'] ?? []),
      filePaths: List<String>.from(data['filePaths'] ?? []),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      isGraded: data['isGraded'] ?? false,
      score: data['score']?.toDouble(),
      feedback: data['feedback'],
      isAiFeedbackGenerated: data['isAiFeedbackGenerated'] ?? false,
      isAiFeedbackReviewed: data['isAiFeedbackReviewed'] ?? false,
      aiData: data['aiData'] as Map<String, dynamic>?,
      notes: data['notes'],
      aiFeedback: data['aiFeedback'] as Map<String, dynamic>?,
      pageCounts: Map<String, int>.from(data['pageCounts'] ?? {}),
    );
  }
  
  // Convert submission to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentPhotoUrl': studentPhotoUrl,
      'content': content,
      'fileUrls': fileUrls,
      'fileNames': fileNames,
      'filePaths': filePaths,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'isGraded': isGraded,
      'score': score,
      'feedback': feedback,
      'isAiFeedbackGenerated': isAiFeedbackGenerated,
      'isAiFeedbackReviewed': isAiFeedbackReviewed,
      'aiData': aiData,
      'notes': notes,
      'aiFeedback': aiFeedback,
      'pageCounts': pageCounts,
    };
  }
  
  // Create a copy of the submission with updated fields
  SubmissionModel copyWith({
    String? id,
    String? classId,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? studentPhotoUrl,
    String? content,
    List<String>? fileUrls,
    List<String>? fileNames,
    List<String>? filePaths,
    DateTime? submittedAt,
    bool? isGraded,
    double? score,
    String? feedback,
    bool? isAiFeedbackGenerated,
    bool? isAiFeedbackReviewed,
    Map<String, dynamic>? aiData,
    String? notes,
    Map<String, dynamic>? aiFeedback,
    Map<String, int>? pageCounts,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentPhotoUrl: studentPhotoUrl ?? this.studentPhotoUrl,
      content: content ?? this.content,
      fileUrls: fileUrls ?? this.fileUrls,
      fileNames: fileNames ?? this.fileNames,
      filePaths: filePaths ?? this.filePaths,
      submittedAt: submittedAt ?? this.submittedAt,
      isGraded: isGraded ?? this.isGraded,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      isAiFeedbackGenerated: isAiFeedbackGenerated ?? this.isAiFeedbackGenerated,
      isAiFeedbackReviewed: isAiFeedbackReviewed ?? this.isAiFeedbackReviewed,
      aiData: aiData ?? this.aiData,
      notes: notes ?? this.notes,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      pageCounts: pageCounts ?? this.pageCounts,
    );
  }
  
  // Get formatted submission date
  String get formattedSubmissionDate {
    if (submittedAt == null) return 'Not submitted';
    return '${submittedAt!.day}/${submittedAt!.month}/${submittedAt!.year}';
  }
  
  // Get submission status
  SubmissionStatus get status {
    if (submittedAt == null) return SubmissionStatus.notSubmitted;
    if (isGraded) return SubmissionStatus.graded;
    if (feedback != null) return SubmissionStatus.returned;
    return SubmissionStatus.submitted;
  }
  
  // Format score for display
  String get formattedScore {
    if (score == null) {
      return 'Not graded';
    }
    return score!.toStringAsFixed(1);
  }
  
  // Check if submission is late based on assignment due date
  bool isLate(DateTime dueDate) {
    // Add a 1-minute buffer to handle slight delays in submission processing
    final DateTime bufferedDueDate = dueDate.add(const Duration(minutes: 1));
    if (submittedAt == null) return false;
    return submittedAt!.isAfter(bufferedDueDate);
  }
} 
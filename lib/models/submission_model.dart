import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum SubmissionStatus {
  pending,
  submitted,
  graded,
  late,
  resubmitted
}

class SubmissionModel {
  final String id;
  final String assignmentId;
  final String classId;
  final String studentId;
  final String studentName;
  final DateTime submittedAt;
  final List<String> fileUrls;
  final String notes;
  final SubmissionStatus status;
  final int? score;
  final String? feedback;
  final Map<String, dynamic>? aiFeedback;
  final bool isLatest;

  SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.submittedAt,
    required this.fileUrls,
    this.notes = '',
    this.status = SubmissionStatus.submitted,
    this.score,
    this.feedback,
    this.aiFeedback,
    this.isLatest = true,
  });
  
  // Create an empty submission
  factory SubmissionModel.empty() {
    return SubmissionModel(
      id: '',
      assignmentId: '',
      classId: '',
      studentId: '',
      studentName: '',
      submittedAt: DateTime.now(),
      fileUrls: [],
    );
  }
  
  // Create from Firestore document
  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert string status to enum
    final String statusStr = data['status'] ?? 'submitted';
    final SubmissionStatus submissionStatus;
    switch (statusStr) {
      case 'pending':
        submissionStatus = SubmissionStatus.pending;
        break;
      case 'submitted':
        submissionStatus = SubmissionStatus.submitted;
        break;
      case 'graded':
        submissionStatus = SubmissionStatus.graded;
        break;
      case 'late':
        submissionStatus = SubmissionStatus.late;
        break;
      case 'resubmitted':
        submissionStatus = SubmissionStatus.resubmitted;
        break;
      default:
        submissionStatus = SubmissionStatus.submitted;
    }
    
    return SubmissionModel(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      classId: data['classId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileUrls: List<String>.from(data['fileUrls'] ?? []),
      notes: data['notes'] ?? '',
      status: submissionStatus,
      score: data['score'],
      feedback: data['feedback'],
      aiFeedback: data['aiFeedback'],
      isLatest: data['isLatest'] ?? true,
    );
  }
  
  // Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    // Convert status enum to string
    String statusStr;
    switch (status) {
      case SubmissionStatus.pending:
        statusStr = 'pending';
        break;
      case SubmissionStatus.submitted:
        statusStr = 'submitted';
        break;
      case SubmissionStatus.graded:
        statusStr = 'graded';
        break;
      case SubmissionStatus.late:
        statusStr = 'late';
        break;
      case SubmissionStatus.resubmitted:
        statusStr = 'resubmitted';
        break;
    }
    
    return {
      'assignmentId': assignmentId,
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'fileUrls': fileUrls,
      'notes': notes,
      'status': statusStr,
      'score': score,
      'feedback': feedback,
      'aiFeedback': aiFeedback,
      'isLatest': isLatest,
    };
  }
  
  // Create a copy with updated fields
  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? classId,
    String? studentId,
    String? studentName,
    DateTime? submittedAt,
    List<String>? fileUrls,
    String? notes,
    SubmissionStatus? status,
    int? score,
    String? feedback,
    Map<String, dynamic>? aiFeedback,
    bool? isLatest,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      submittedAt: submittedAt ?? this.submittedAt,
      fileUrls: fileUrls ?? this.fileUrls,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      isLatest: isLatest ?? this.isLatest,
    );
  }
  
  // Get formatted submission date
  String get formattedSubmissionDate {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(submittedAt);
  }
  
  // Check if submission is late based on assignment due date
  bool isLate(DateTime dueDate) {
    // Add a 1-minute buffer to handle slight delays in submission processing
    final DateTime bufferedDueDate = dueDate.add(const Duration(minutes: 1));
    return submittedAt.isAfter(bufferedDueDate);
  }
} 
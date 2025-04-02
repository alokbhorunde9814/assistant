import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime? dueDate;
  final int points;
  final bool isAutoGraded;
  final List<String> fileUrls;
  final Map<String, dynamic> aiData; // Stores AI-related data for grading
  final String creatorName; // This is the same as authorName for consistency

  AssignmentModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.dueDate,
    this.points = 100,
    this.isAutoGraded = false,
    this.fileUrls = const [],
    this.aiData = const {},
    String? creatorName,
  }) : creatorName = creatorName ?? authorName;

  // Create an empty assignment with default values
  factory AssignmentModel.empty() {
    return AssignmentModel(
      id: '',
      classId: '',
      title: '',
      description: '',
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 7)),
      points: 100,
    );
  }

  // Create an assignment from a Firestore document
  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      points: data['points'] ?? data['totalPoints'] ?? 100,
      isAutoGraded: data['isAutoGraded'] ?? false,
      fileUrls: List<String>.from(data['fileUrls'] ?? data['resourceUrls'] ?? []),
      aiData: data['aiData'] ?? {},
      creatorName: data['creatorName'] ?? data['authorName'] ?? '',
    );
  }

  // Convert assignment to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'points': points,
      'isAutoGraded': isAutoGraded,
      'fileUrls': fileUrls,
      'aiData': aiData,
      'creatorName': creatorName,
    };
  }

  // Create a copy of the assignment with updated fields
  AssignmentModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? dueDate,
    int? points,
    bool? isAutoGraded,
    List<String>? fileUrls,
    Map<String, dynamic>? aiData,
    String? creatorName,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      points: points ?? this.points,
      isAutoGraded: isAutoGraded ?? this.isAutoGraded,
      fileUrls: fileUrls ?? this.fileUrls,
      aiData: aiData ?? this.aiData,
      creatorName: creatorName ?? this.creatorName,
    );
  }

  // Determine if the assignment is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Format due date for display
  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    
    final difference = dueDay.difference(today).inDays;
    
    if (difference == 0) {
      return 'Due Today';
    } else if (difference == 1) {
      return 'Due Tomorrow';
    } else if (difference < 0) {
      return 'Overdue by ${-difference} days';
    } else {
      return 'Due in $difference days';
    }
  }
} 
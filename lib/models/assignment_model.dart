import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime dueDate;
  final int totalPoints;
  final bool isAutoGraded;
  final List<String> resourceUrls;
  final Map<String, dynamic> aiData; // Stores AI-related data for grading

  AssignmentModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.dueDate,
    required this.totalPoints,
    this.isAutoGraded = false,
    this.resourceUrls = const [],
    this.aiData = const {},
  });

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
      totalPoints: 100,
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
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 7)),
      totalPoints: data['totalPoints'] ?? 100,
      isAutoGraded: data['isAutoGraded'] ?? false,
      resourceUrls: List<String>.from(data['resourceUrls'] ?? []),
      aiData: data['aiData'] ?? {},
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
      'dueDate': Timestamp.fromDate(dueDate),
      'totalPoints': totalPoints,
      'isAutoGraded': isAutoGraded,
      'resourceUrls': resourceUrls,
      'aiData': aiData,
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
    int? totalPoints,
    bool? isAutoGraded,
    List<String>? resourceUrls,
    Map<String, dynamic>? aiData,
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
      totalPoints: totalPoints ?? this.totalPoints,
      isAutoGraded: isAutoGraded ?? this.isAutoGraded,
      resourceUrls: resourceUrls ?? this.resourceUrls,
      aiData: aiData ?? this.aiData,
    );
  }

  // Determine if the assignment is overdue
  bool get isOverdue => DateTime.now().isAfter(dueDate);

  // Format due date for display
  String get formattedDueDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
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
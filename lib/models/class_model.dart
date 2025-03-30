import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String name;
  final String code;
  final String description;
  final String ownerId;
  final String ownerName;
  final String subject;
  final List<String> studentIds;
  final DateTime createdAt;
  final bool hasAutomatedGrading;
  final bool hasAiFeedback;

  ClassModel({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.subject,
    required this.studentIds,
    required this.createdAt,
    this.hasAutomatedGrading = false,
    this.hasAiFeedback = false,
  });

  // Create an empty class with default values
  factory ClassModel.empty() {
    return ClassModel(
      id: '',
      name: '',
      code: '',
      description: '',
      ownerId: '',
      ownerName: '',
      subject: '',
      studentIds: [],
      createdAt: DateTime.now(),
    );
  }

  // Create a class from a Firestore document
  factory ClassModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClassModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      subject: data['subject'] ?? '',
      studentIds: List<String>.from(data['studentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hasAutomatedGrading: data['hasAutomatedGrading'] ?? false,
      hasAiFeedback: data['hasAiFeedback'] ?? false,
    );
  }

  // Convert class to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'subject': subject,
      'studentIds': studentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'hasAutomatedGrading': hasAutomatedGrading,
      'hasAiFeedback': hasAiFeedback,
    };
  }

  // Create a copy of the class with updated fields
  ClassModel copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    String? ownerId,
    String? ownerName,
    String? subject,
    List<String>? studentIds,
    DateTime? createdAt,
    bool? hasAutomatedGrading,
    bool? hasAiFeedback,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      subject: subject ?? this.subject,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt ?? this.createdAt,
      hasAutomatedGrading: hasAutomatedGrading ?? this.hasAutomatedGrading,
      hasAiFeedback: hasAiFeedback ?? this.hasAiFeedback,
    );
  }

  // Check if a student is in this class
  bool hasStudent(String studentId) {
    return studentIds.contains(studentId);
  }
  
  // Get the number of students in the class
  int get studentCount => studentIds.length;
} 
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final DateTime joinedAt;
  final Map<String, dynamic> progress;
  final List<String> enrolledClasses;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    required this.joinedAt,
    this.progress = const {},
    this.enrolledClasses = const [],
  });

  // Create an empty student with default values
  factory StudentModel.empty() {
    return StudentModel(
      id: '',
      name: '',
      email: '',
      joinedAt: DateTime.now(),
    );
  }

  // Create a student from a Firestore document
  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: data['progress'] as Map<String, dynamic>? ?? {},
      enrolledClasses: List<String>.from(data['enrolledClasses'] ?? []),
    );
  }

  // Create a student from Firebase User data
  factory StudentModel.fromUser(String id, String name, String email, String? photoUrl) {
    return StudentModel(
      id: id,
      name: name,
      email: email,
      photoUrl: photoUrl,
      joinedAt: DateTime.now(),
    );
  }

  // Convert student to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'progress': progress,
      'enrolledClasses': enrolledClasses,
    };
  }

  // Create a copy of the student with updated fields
  StudentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    DateTime? joinedAt,
    Map<String, dynamic>? progress,
    List<String>? enrolledClasses,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      joinedAt: joinedAt ?? this.joinedAt,
      progress: progress ?? this.progress,
      enrolledClasses: enrolledClasses ?? this.enrolledClasses,
    );
  }
} 
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String classId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final List<String> attachmentUrls;

  AnnouncementModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.attachmentUrls = const [],
  });

  // Create an empty announcement with default values
  factory AnnouncementModel.empty() {
    return AnnouncementModel(
      id: '',
      classId: '',
      title: '',
      content: '',
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
    );
  }

  // Create an announcement from a Firestore document
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachmentUrls: List<String>.from(data['attachmentUrls'] ?? []),
    );
  }

  // Convert announcement to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'attachmentUrls': attachmentUrls,
    };
  }

  // Create a copy of the announcement with updated fields
  AnnouncementModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    List<String>? attachmentUrls,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }
} 
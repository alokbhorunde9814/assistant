import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ResourceType {
  document,
  link,
  video,
  image,
  audio,
  other,
}

class ResourceModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String url;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final ResourceType type;
  final bool isAiRecommended;
  final Map<String, dynamic> aiData; // AI metadata about the resource

  ResourceModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.url,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.type,
    this.isAiRecommended = false,
    this.aiData = const {},
  });

  // Create an empty resource with default values
  factory ResourceModel.empty() {
    return ResourceModel(
      id: '',
      classId: '',
      title: '',
      description: '',
      url: '',
      authorId: '',
      authorName: '',
      createdAt: DateTime.now(),
      type: ResourceType.document,
    );
  }

  // Create a resource from a Firestore document
  factory ResourceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert string to ResourceType
    final typeStr = data['type'] ?? 'document';
    final ResourceType resourceType;
    switch (typeStr) {
      case 'document':
        resourceType = ResourceType.document;
        break;
      case 'link':
        resourceType = ResourceType.link;
        break;
      case 'video':
        resourceType = ResourceType.video;
        break;
      case 'image':
        resourceType = ResourceType.image;
        break;
      case 'audio':
        resourceType = ResourceType.audio;
        break;
      default:
        resourceType = ResourceType.other;
    }
    
    return ResourceModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: resourceType,
      isAiRecommended: data['isAiRecommended'] ?? false,
      aiData: data['aiData'] ?? {},
    );
  }

  // Convert resource to a map for Firestore
  Map<String, dynamic> toFirestore() {
    // Convert ResourceType to string
    final String typeStr;
    switch (type) {
      case ResourceType.document:
        typeStr = 'document';
        break;
      case ResourceType.link:
        typeStr = 'link';
        break;
      case ResourceType.video:
        typeStr = 'video';
        break;
      case ResourceType.image:
        typeStr = 'image';
        break;
      case ResourceType.audio:
        typeStr = 'audio';
        break;
      case ResourceType.other:
        typeStr = 'other';
        break;
    }
    
    return {
      'classId': classId,
      'title': title,
      'description': description,
      'url': url,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': typeStr,
      'isAiRecommended': isAiRecommended,
      'aiData': aiData,
    };
  }

  // Create a copy of the resource with updated fields
  ResourceModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    String? url,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    ResourceType? type,
    bool? isAiRecommended,
    Map<String, dynamic>? aiData,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isAiRecommended: isAiRecommended ?? this.isAiRecommended,
      aiData: aiData ?? this.aiData,
    );
  }

  // Get icon based on resource type
  IconData get icon {
    switch (type) {
      case ResourceType.document:
        return Icons.description;
      case ResourceType.link:
        return Icons.link;
      case ResourceType.video:
        return Icons.video_library;
      case ResourceType.image:
        return Icons.image;
      case ResourceType.audio:
        return Icons.audio_file;
      case ResourceType.other:
        return Icons.attach_file;
    }
  }
} 
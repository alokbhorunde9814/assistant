import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ResourceType {
  document,
  video,
  link,
  presentation,
  worksheet,
  other,
}

class ResourceModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String url;
  final ResourceType type;
  final DateTime createdAt;
  final String createdBy;

  ResourceModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.url,
    required this.type,
    required this.createdAt,
    required this.createdBy,
  });

  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    return ResourceModel(
      id: map['id'] as String,
      classId: map['classId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      url: map['url'] as String,
      type: ResourceType.values.firstWhere(
        (e) => e.toString() == 'ResourceType.${map['type']}',
        orElse: () => ResourceType.other,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'title': title,
      'description': description,
      'url': url,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  // Create an empty resource with default values
  factory ResourceModel.empty() {
    return ResourceModel(
      id: '',
      classId: '',
      title: '',
      description: '',
      url: '',
      type: ResourceType.document,
      createdAt: DateTime.now(),
      createdBy: '',
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
      case 'presentation':
        resourceType = ResourceType.presentation;
        break;
      case 'worksheet':
        resourceType = ResourceType.worksheet;
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
      type: resourceType,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
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
      case ResourceType.presentation:
        typeStr = 'presentation';
        break;
      case ResourceType.worksheet:
        typeStr = 'worksheet';
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
      'type': typeStr,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  // Create a copy of the resource with updated fields
  ResourceModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    String? url,
    ResourceType? type,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
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
      case ResourceType.presentation:
        return Icons.slideshow;
      case ResourceType.worksheet:
        return Icons.assignment;
      case ResourceType.other:
        return Icons.attach_file;
    }
  }
} 
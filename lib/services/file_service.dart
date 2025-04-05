import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class FileService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;
  
  // Pick a file from device
  Future<List<PlatformFile>?> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      debugPrint('Starting file picker with options: allowMultiple=$allowMultiple, allowedExtensions=$allowedExtensions');
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true, // Always get file bytes
      );
      
      if (result != null) {
        debugPrint('Files picked successfully: ${result.files.length} files');
        for (var file in result.files) {
          debugPrint('File details: name=${file.name}, size=${file.size}, bytes=${file.bytes != null}, bytesLength=${file.bytes?.length}');
        }
        return result.files;
      }
      debugPrint('No files were picked');
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }
  
  // Upload a file to Firebase Storage
  Future<Map<String, String>> uploadFile(PlatformFile file, String path) async {
    try {
      debugPrint('Starting file upload process...');
      debugPrint('Current user ID: $_currentUserId');
      debugPrint('File details: name=${file.name}, size=${file.size}, bytes=${file.bytes != null}, bytesLength=${file.bytes?.length}');
      
      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }
      
      debugPrint('Attempting to upload file: ${file.name} to path: $path');
      
      // Create a reference to the file location
      final storageRef = _storage.ref().child(path);
      debugPrint('Created storage reference: ${storageRef.fullPath}');
      
      UploadTask uploadTask;
      
      if (kIsWeb) {
        debugPrint('Running on web platform');
        if (file.bytes == null) {
          throw Exception('File bytes are null, cannot upload');
        }
        debugPrint('File bytes available, size: ${file.bytes!.length}');
        try {
          debugPrint('Creating metadata for web upload...');
          final metadata = SettableMetadata(
            contentType: _getContentType(file.extension ?? ''),
            customMetadata: {
              'uploadedBy': _currentUserId ?? 'unknown',
              'fileName': file.name,
              'fileSize': file.size.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          debugPrint('Created metadata: ${metadata.contentType}');
          
          debugPrint('Starting web upload...');
          uploadTask = storageRef.putData(file.bytes!, metadata);
          debugPrint('Created upload task for web platform');
        } catch (e, stackTrace) {
          debugPrint('Error creating upload task for web: $e');
          debugPrint('Stack trace: $stackTrace');
          rethrow;
        }
      } else {
        debugPrint('Running on non-web platform');
        if (file.path == null) {
          throw Exception('File path is null, cannot upload');
        }
        
        final fileToUpload = File(file.path!);
        
        if (!await fileToUpload.exists()) {
          throw Exception('File does not exist at path: ${file.path}');
        }
        
        final metadata = SettableMetadata(
          contentType: _getContentType(file.extension ?? ''),
          customMetadata: {
            'uploadedBy': _currentUserId ?? 'unknown',
            'fileName': file.name,
            'fileSize': file.size.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        uploadTask = storageRef.putFile(fileToUpload, metadata);
      }
      
      debugPrint('Waiting for upload to complete...');
      
      // Listen for upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        debugPrint('Upload progress: ${progress.toStringAsFixed(2)}%, state: ${snapshot.state}');
      });
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      debugPrint('Upload task completed with state: ${snapshot.state}');
      
      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        debugPrint('File uploaded successfully. URL: $downloadUrl');
        
        return {
          'url': downloadUrl,
          'name': file.name,
          'path': path,
        };
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }
  
  // Upload multiple files to Firebase Storage
  Future<Map<String, dynamic>> uploadFiles(
    List<PlatformFile> files,
    String assignmentId,
    String classId, {
    Map<String, int>? pageCounts,
  }) async {
    try {
      debugPrint('Starting batch file upload process...');
      debugPrint('Number of files to upload: ${files.length}');
      
      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }
      
      final List<String> urls = [];
      final List<String> names = [];
      final List<String> paths = [];
      
      for (var file in files) {
        final path = 'assignments/$classId/$assignmentId/$_currentUserId/${file.name}';
        final result = await uploadFile(file, path);
        
        urls.add(result['url']!);
        names.add(result['name']!);
        paths.add(result['path']!);
        
        // Add page count to metadata if available
        if (pageCounts != null && pageCounts.containsKey(file.name)) {
          final storageRef = _storage.ref().child(path);
          await storageRef.updateMetadata(
            SettableMetadata(
              customMetadata: {
                'pageCount': pageCounts[file.name].toString(),
              },
            ),
          );
        }
      }
      
      return {
        'urls': urls,
        'names': names,
        'paths': paths,
      };
    } catch (e) {
      debugPrint('Error uploading files: $e');
      rethrow;
    }
  }
  
  // Delete a file from Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      debugPrint('File deleted successfully: $fileUrl');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }
  
  // Helper method to determine content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'ppt':
      case 'pptx':
        return 'application/vnd.ms-powerpoint';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
} 
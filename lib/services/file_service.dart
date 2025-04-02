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
  
  // Pick a file from device - optimized for mobile
  Future<List<PlatformFile>?> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      // Simple file picker configuration
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        // Don't load file bytes into memory on mobile - we only need the path
        withData: kIsWeb, // Only load data in web
      );
      
      if (result != null) {
        // Log success for debugging
        debugPrint('Files picked successfully: ${result.files.length} files');
        if (result.files.isNotEmpty) {
          debugPrint('First file name: ${result.files.first.name}');
          debugPrint('First file path: ${result.files.first.path}');
        }
        return result.files;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (e.toString().contains('MissingPluginException')) {
        debugPrint('This may be due to missing plugin implementation.');
        debugPrint('Ensure you have proper setup for file_picker in your mobile app.');
      }
      return null;
    }
  }
  
  // Upload a file to Firebase Storage - optimized for mobile
  Future<String?> uploadFile(PlatformFile file, String path) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }
      
      debugPrint('Attempting to upload file: ${file.name}');
      
      // Create a reference to the file location
      final storageRef = _storage.ref().child('$path/${file.name}');
      
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // Web implementation - fallback only
        if (file.bytes == null) {
          throw Exception('File bytes are null, cannot upload');
        }
        uploadTask = storageRef.putData(file.bytes!);
      } else {
        // Mobile implementation - primary focus
        if (file.path == null) {
          throw Exception('File path is null, cannot upload');
        }
        
        final fileToUpload = File(file.path!);
        
        // Check if file exists
        if (!await fileToUpload.exists()) {
          throw Exception('File does not exist at path: ${file.path}');
        }
        
        debugPrint('File exists, starting upload: ${fileToUpload.path}');
        
        // Upload with file metadata for better organization
        uploadTask = storageRef.putFile(
          fileToUpload,
          SettableMetadata(
            contentType: _getContentType(file.extension ?? ''),
            customMetadata: {
              'uploadedBy': _currentUserId ?? 'unknown',
              'fileName': file.name,
              'fileSize': file.size.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          ),
        );
        
        // Add progress listener for debugging
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });
      }
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('File uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }
  
  // Upload multiple files to Firebase Storage
  Future<List<String>> uploadFiles(
    List<PlatformFile> files,
    String assignmentId,
    String classId,
  ) async {
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }
    
    debugPrint('Starting upload of ${files.length} files');
    final List<String> uploadedUrls = [];
    final path = 'submissions/$classId/$assignmentId/$_currentUserId';
    
    for (var file in files) {
      final url = await uploadFile(file, path);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    debugPrint('Uploaded ${uploadedUrls.length} files successfully');
    return uploadedUrls;
  }
  
  // Delete a file from Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      // Extract file path from the URL
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
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
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
      default:
        return 'application/octet-stream'; // Default binary data
    }
  }
} 
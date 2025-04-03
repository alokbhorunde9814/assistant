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
      final storageRef = _storage.ref().child('$path/${file.name}');
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
        
        debugPrint('File exists, starting upload: ${fileToUpload.path}');
        
        try {
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
          debugPrint('Created upload task for non-web platform');
        } catch (e) {
          debugPrint('Error creating upload task for non-web: $e');
          rethrow;
        }
      }
      
      // Add progress tracking
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%, state: ${snapshot.state}');
        },
        onError: (error) {
          debugPrint('Error during upload progress: $error');
        },
        cancelOnError: false,
      );
      
      debugPrint('Waiting for upload to complete...');
      try {
        // Wait for the upload to complete
        final snapshot = await uploadTask;
        debugPrint('Upload task completed with state: ${snapshot.state}');
        
        // Check if the upload was successful
        if (snapshot.state == TaskState.success) {
          final downloadUrl = await snapshot.ref.getDownloadURL();
          debugPrint('File uploaded successfully. URL: $downloadUrl');
          return {
            'url': downloadUrl,
            'path': snapshot.ref.fullPath,
            'name': file.name,
          };
        } else {
          throw Exception('Upload failed with state: ${snapshot.state}');
        }
      } catch (e, stackTrace) {
        debugPrint('Error during upload task: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading file: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow; // Rethrow to handle in the calling code
    }
  }
  
  // Upload multiple files to Firebase Storage
  Future<Map<String, List<String>>> uploadFiles(
    List<PlatformFile> files,
    String assignmentId,
    String classId,
  ) async {
    debugPrint('Starting uploadFiles method');
    debugPrint('Current user ID: $_currentUserId');
    debugPrint('Assignment ID: $assignmentId, Class ID: $classId');
    
    if (_currentUserId == null) {
      throw Exception('User not logged in');
    }
    
    debugPrint('Starting upload of ${files.length} files');
    final List<String> uploadedUrls = [];
    final List<String> fileNames = [];
    final List<String> filePaths = [];
    final path = 'submissions/$classId/$assignmentId/$_currentUserId';
    debugPrint('Storage path: $path');
    
    try {
      for (var file in files) {
        try {
          debugPrint('Uploading file: ${file.name}');
          final result = await uploadFile(file, path);
          uploadedUrls.add(result['url']!);
          fileNames.add(result['name']!);
          filePaths.add(result['path']!);
          debugPrint('Successfully uploaded: ${file.name}');
        } catch (e) {
          debugPrint('Failed to upload ${file.name}: $e');
          // Continue with next file even if one fails
          continue;
        }
      }
      
      if (uploadedUrls.isEmpty) {
        throw Exception('No files were successfully uploaded');
      }
      
      debugPrint('Uploaded ${uploadedUrls.length} files successfully');
      return {
        'urls': uploadedUrls,
        'names': fileNames,
        'paths': filePaths,
      };
    } catch (e) {
      debugPrint('Error in uploadFiles: $e');
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
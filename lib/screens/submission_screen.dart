import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/gemini_service.dart';
import '../widgets/photo_capture_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SubmissionScreen extends StatefulWidget {
  final String assignmentId;

  const SubmissionScreen({super.key, required this.assignmentId});

  @override
  State<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends State<SubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _geminiService = GeminiService();
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;
  String? _aiFeedback;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMessage = null;
        });
        _uploadAndAnalyze();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    }
  }

  Future<void> _uploadAndAnalyze() async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a file first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _aiFeedback = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create a reference to the file location
      final storageRef = FirebaseStorage.instance.ref();
      final fileRef = storageRef.child('assignments/${user.uid}/${_selectedFile!.name}');

      // Upload the file
      if (kIsWeb) {
        if (_selectedFile!.bytes == null) {
          throw Exception('File bytes are null');
        }
        await fileRef.putData(
          _selectedFile!.bytes!,
          SettableMetadata(contentType: _selectedFile!.extension),
        );
      } else {
        if (_selectedFile!.path == null) {
          throw Exception('File path is null');
        }
        final file = File(_selectedFile!.path!);
        await fileRef.putFile(
          file,
          SettableMetadata(contentType: _selectedFile!.extension),
        );
      }

      // Get the download URL
      final downloadUrl = await fileRef.getDownloadURL();

      // Generate AI feedback
      final feedback = await _geminiService.analyzeFile(_selectedFile!);

      // Save submission details to Firestore
      await FirebaseFirestore.instance.collection('submissions').add({
        'userId': user.uid,
        'assignmentId': widget.assignmentId,
        'fileName': _selectedFile!.name,
        'fileUrl': downloadUrl,
        'fileType': _selectedFile!.extension,
        'feedback': feedback,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _aiFeedback = feedback;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading file: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Assignment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_isUploading ? 'Uploading...' : 'Select File'),
              ),
              const SizedBox(height: 16),
              PhotoCaptureButton(
                onFileSelected: (path) {
                  setState(() {
                    _selectedFile = PlatformFile(
                      name: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      path: path,
                      size: 0,
                    );
                    _errorMessage = null;
                  });
                  _uploadAndAnalyze();
                },
                isLoading: _isUploading,
              ),
              if (_selectedFile != null) ...[
                const SizedBox(height: 16),
                Text('Selected file: ${_selectedFile!.name}'),
                Text('Size: ${(_selectedFile!.size / 1024).toStringAsFixed(2)} KB'),
              ],
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (_aiFeedback != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'AI Feedback:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_aiFeedback!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 
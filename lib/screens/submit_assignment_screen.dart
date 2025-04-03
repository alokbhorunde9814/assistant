import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../utils/error_handler.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/photo_capture_button.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final bool allowResubmit;
  
  const SubmitAssignmentScreen({
    super.key,
    required this.assignment,
    this.allowResubmit = true,
  });

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<PlatformFile> _selectedFiles = [];
  List<SubmissionModel> _previousSubmissions = [];
  SubmissionModel? _latestSubmission;
  bool _hasSubmitted = false;
  bool _showPreviousSubmissions = false;
  bool _uploadingFiles = false;
  
  @override
  void initState() {
    super.initState();
    _loadSubmissionData();
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSubmissionData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Check if there are any previous submissions
      final hasSubmitted = await _databaseService.hasSubmittedAssignment(widget.assignment.id);
      
      if (hasSubmitted) {
        // Get all previous submissions
        final submissions = await _databaseService.getSubmissionsForStudentAssignment(
          widget.assignment.id,
          currentUser.uid,
        );
        
        // Get latest submission
        final latestSubmission = await _databaseService.getLatestSubmission(
          widget.assignment.id,
          currentUser.uid,
        );
        
        setState(() {
          _previousSubmissions = submissions;
          _latestSubmission = latestSubmission;
          _hasSubmitted = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_errorMessage}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _submitAssignment() async {
    // Basic validation
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one file to submit')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _uploadingFiles = true;
      _errorMessage = null;
    });
    
    try {
      // Upload the files to Firebase Storage
      final uploadResult = await _fileService.uploadFiles(
        _selectedFiles,
        widget.assignment.id,
        widget.assignment.classId,
      );
      
      setState(() {
        _uploadingFiles = false;
      });
      
      // Submit the assignment
      final submission = await _databaseService.submitAssignment(
        assignmentId: widget.assignment.id,
        classId: widget.assignment.classId,
        fileUrls: uploadResult['urls']!,
        fileNames: uploadResult['names']!,
        filePaths: uploadResult['paths']!,
        content: _notesController.text,
        points: widget.assignment.points.toDouble(),
      );
      
      setState(() {
        _latestSubmission = submission;
        _hasSubmitted = true;
        _previousSubmissions.insert(0, submission);  // Add to beginning of list
        _selectedFiles = []; // Clear selected files
        _notesController.clear(); // Clear notes
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment submitted successfully!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${_errorMessage}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadingFiles = false;
      });
    }
  }
  
  Future<void> _pickFiles() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening file browser...')),
      );
      
      // Configure file picker to directly open device file browser
      final files = await _fileService.pickFiles(
        allowMultiple: true,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      );
      
      // Clear the loading indicator
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (files != null && files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(files);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${files.length} file(s)')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      if (e.toString().contains('MissingPluginException')) {
        // Handle file picker issues on Android
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'There was an issue with the file picker on your device. Please try again later.'
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting files: $e')),
        );
      }
    }
  }
  
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }
  
  Future<void> _captureImage() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing camera...')),
      );
      
      // The PhotoCaptureButton will handle the actual capture and upload
      // We just need to wait for the result
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Take Photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Use the camera button to take a photo'),
              const SizedBox(height: 16),
              PhotoCaptureButton(
                onFileSelected: (url) {
                  Navigator.pop(context, url);
                },
              ),
            ],
          ),
        ),
      );
      
      if (result != null) {
        setState(() {
          _selectedFiles.add(PlatformFile(
            name: 'photo_${DateTime.now().millisecondsSinceEpoch}.pdf',
            size: 0, // Size will be updated after upload
            path: result,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }
  
  String _formatDueDate(DateTime date) {
    return DateFormat('MMM d, yyyy \'at\' h:mm a').format(date);
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isOverdue = widget.assignment.dueDate?.isBefore(DateTime.now()) ?? false;
    final bool canSubmit = !isOverdue || widget.allowResubmit;
    final bool showResubmitOption = _hasSubmitted && widget.allowResubmit;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        title: 'Submit Assignment',
        isHomeScreen: false,
      ),
      body: _isLoading && !_uploadingFiles
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Details Section
                  _buildAssignmentDetailsCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Submission Status
                  if (_hasSubmitted)
                    _buildSubmissionStatusCard(),
                    
                  const SizedBox(height: 16),
                  
                  // Upload Section (if can submit)
                  if (canSubmit && (!_hasSubmitted || showResubmitOption))
                    _buildUploadSection(),
                  
                  const SizedBox(height: 16),
                  
                  // AI Feedback (if available)
                  if (_latestSubmission?.aiFeedback != null)
                    _buildAiFeedbackCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Previous Submissions
                  if (_previousSubmissions.length > 1)
                    _buildPreviousSubmissionsSection(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildAssignmentDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.assignment.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Deadline: ${_formatDueDate(widget.assignment.dueDate ?? DateTime.now())}',
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.assignment.isOverdue ? Colors.red : Colors.black87,
                    fontWeight: widget.assignment.isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.score, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Points: ${widget.assignment.points}',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.assignment.description,
              style: const TextStyle(fontSize: 15),
            ),
            if (widget.assignment.isAutoGraded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Feedback Enabled',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubmissionStatusCard() {
    final status = _latestSubmission?.status ?? SubmissionStatus.submitted;
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case SubmissionStatus.notSubmitted:
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case SubmissionStatus.submitted:
        statusColor = Colors.green;
        statusText = 'Submitted';
        statusIcon = Icons.check_circle;
        break;
      case SubmissionStatus.graded:
        statusColor = Colors.blue;
        statusText = 'Graded';
        statusIcon = Icons.star;
        break;
      case SubmissionStatus.returned:
        statusColor = Colors.purple;
        statusText = 'Resubmitted';
        statusIcon = Icons.repeat;
        break;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Submission Status: $statusText',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_latestSubmission != null) ...[
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Submitted on ${_latestSubmission!.formattedSubmissionDate}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Files:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ..._latestSubmission!.fileUrls.map((url) {
                final filename = url.split('/').last;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(filename),
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(filename),
                    ],
                  ),
                );
              }).toList(),
              if (_latestSubmission!.notes?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                const Text(
                  'Notes:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_latestSubmission!.notes ?? ''),
              ],
              if (_latestSubmission!.status == SubmissionStatus.graded) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.grade,
                            color: Colors.blue.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Grade: ${_latestSubmission!.score}/${widget.assignment.points}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (_latestSubmission!.feedback != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Feedback: ${_latestSubmission!.feedback}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildUploadSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hasSubmitted ? 'Resubmit Assignment' : 'Upload Your Submission',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            
            // File Upload Progress
            if (_uploadingFiles)
              Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Uploading files...',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // Selected Files
            if (_selectedFiles.isNotEmpty) ...[
              const Text(
                'Selected Files:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: List.generate(_selectedFiles.length, (index) {
                    final file = _selectedFiles[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(file.name),
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${(file.size / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: _uploadingFiles ? null : () => _removeFile(index),
                            color: Colors.red.shade400,
                            tooltip: 'Remove file',
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Add File Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Attach Files'),
                    onPressed: _uploadingFiles ? null : _pickFiles,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    onPressed: _uploadingFiles ? null : _captureImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Notes TextField
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
              enabled: !_uploadingFiles,
            ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _hasSubmitted ? 'Resubmit Assignment' : 'Submit Assignment',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAiFeedbackCard() {
    final aiFeedback = _latestSubmission?.aiFeedback;
    if (aiFeedback == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'AI Feedback',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (aiFeedback['score'] != null) ...[
              Row(
                children: [
                  const Icon(Icons.score, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Score: ${aiFeedback['score']}%',
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (aiFeedback['feedbackPoints'] != null) ...[
              const Text(
                'Feedback Points:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...(aiFeedback['feedbackPoints'] as List).map((point) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          point.toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            if (aiFeedback['suggestedImprovements'] != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Suggested Improvements:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                aiFeedback['suggestedImprovements'].toString(),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreviousSubmissionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Previous Submissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _showPreviousSubmissions ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPreviousSubmissions = !_showPreviousSubmissions;
                    });
                  },
                ),
              ],
            ),
            if (_showPreviousSubmissions) ...[
              const Divider(height: 24),
              ..._previousSubmissions.skip(1).map((submission) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      _getSubmissionStatusIcon(submission.status),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              submission.formattedSubmissionDate,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Files: ${submission.fileUrls.length} file(s)',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  if (submission.status == SubmissionStatus.graded) 
                                    Text(
                                      'Grade: ${submission.score}/${widget.assignment.points}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
  
  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  Widget _getSubmissionStatusIcon(SubmissionStatus status) {
    Color color;
    IconData icon;
    
    switch (status) {
      case SubmissionStatus.notSubmitted:
        color = Colors.orange;
        icon = Icons.assignment_late;
        break;
      case SubmissionStatus.submitted:
        color = Colors.green;
        icon = Icons.assignment_turned_in;
        break;
      case SubmissionStatus.graded:
        color = Colors.blue;
        icon = Icons.grading;
        break;
      case SubmissionStatus.returned:
        color = Colors.purple;
        icon = Icons.assignment_return;
        break;
    }
    
    return Icon(icon, color: color, size: 16);
  }
} 
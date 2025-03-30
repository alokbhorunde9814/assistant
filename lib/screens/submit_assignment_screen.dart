import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/assignment_model.dart';
import '../models/submission_model.dart';
import '../services/database_service.dart';
import '../utils/error_handler.dart';
import '../utils/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';

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
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _selectedFiles = [];
  List<SubmissionModel> _previousSubmissions = [];
  SubmissionModel? _latestSubmission;
  bool _hasSubmitted = false;
  bool _showPreviousSubmissions = false;
  
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
      _errorMessage = null;
    });
    
    try {
      // In a real app, you'd upload the files to storage here
      // For this demo, we'll just use mock file URLs
      final mockFileUrls = _selectedFiles.map((filename) => 
        'https://example.com/submissions/${widget.assignment.id}/$filename'
      ).toList();
      
      // Submit the assignment
      final submission = await _databaseService.submitAssignment(
        assignmentId: widget.assignment.id,
        classId: widget.assignment.classId,
        fileUrls: mockFileUrls,
        notes: _notesController.text,
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
      });
    }
  }
  
  void _addFile(String filename) {
    setState(() {
      _selectedFiles.add(filename);
    });
  }
  
  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }
  
  void _captureAndSubmit() {
    // In a real app, this would open the camera
    // For this demo, we'll just add a mock file
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _addFile('photo_$timestamp.jpg');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo captured successfully')),
    );
  }
  
  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(date.year, date.month, date.day);
    
    final formatter = DateFormat('MMM dd, yyyy \'at\' h:mm a');
    String formattedDate = formatter.format(date);
    
    if (dueDate == today) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (dueDate.difference(today).inDays == 1) {
      return 'Tomorrow at ${DateFormat('h:mm a').format(date)}';
    } else if (today.difference(dueDate).inDays == 1) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    }
    
    return formattedDate;
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isOverdue = widget.assignment.dueDate.isBefore(DateTime.now());
    final bool canSubmit = !isOverdue || widget.allowResubmit;
    final bool showResubmitOption = _hasSubmitted && widget.allowResubmit;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: CustomAppBar(
        title: 'Submit Assignment',
        isHomeScreen: false,
      ),
      body: _isLoading
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
                  'Deadline: ${_formatDueDate(widget.assignment.dueDate)}',
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
                  'Points: ${widget.assignment.totalPoints}',
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
      case SubmissionStatus.pending:
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
      case SubmissionStatus.late:
        statusColor = Colors.red;
        statusText = 'Submitted Late';
        statusIcon = Icons.warning;
        break;
      case SubmissionStatus.resubmitted:
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
              if (_latestSubmission!.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Notes:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_latestSubmission!.notes),
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
                            'Grade: ${_latestSubmission!.score}/${widget.assignment.totalPoints}',
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
              ...List.generate(_selectedFiles.length, (index) {
                final filename = _selectedFiles[index];
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
                      Expanded(child: Text(filename)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => _removeFile(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            // Add File Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_upload),
                    label: const Text('Attach File'),
                    onPressed: () {
                      // In a real app, this would open a file picker
                      // For this demo, we'll just add a mock file
                      final timestamp = DateTime.now().millisecondsSinceEpoch;
                      _addFile('assignment_$timestamp.pdf');
                    },
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
                    onPressed: _captureAndSubmit,
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
    final aiFeedback = _latestSubmission!.aiFeedback!;
    final feedbackPoints = aiFeedback['feedbackPoints'] as List;
    
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
                  'AI Feedback on Your Submission',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Suggested Score: ${aiFeedback['score']}/${widget.assignment.totalPoints}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Feedback Points:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...feedbackPoints.map((point) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 10,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(point.toString())),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            const Text(
              'Suggested Improvements:',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(aiFeedback['suggestedImprovements'].toString()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This feedback is generated by AI and may not fully reflect your instructor\'s assessment.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            InkWell(
              onTap: () {
                setState(() {
                  _showPreviousSubmissions = !_showPreviousSubmissions;
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.history, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Previous Submissions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _showPreviousSubmissions
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            if (_showPreviousSubmissions) ...[
              const Divider(height: 24),
              ...List.generate(_previousSubmissions.length, (index) {
                final submission = _previousSubmissions[index];
                if (submission.id == _latestSubmission?.id) {
                  return const SizedBox.shrink(); // Skip the current submission
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _getSubmissionStatusIcon(submission.status),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Submitted on ${submission.formattedSubmissionDate}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
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
                                'Grade: ${submission.score}/${widget.assignment.totalPoints}',
                                style: const TextStyle(fontSize: 13),
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
      case SubmissionStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case SubmissionStatus.submitted:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case SubmissionStatus.graded:
        color = Colors.blue;
        icon = Icons.star;
        break;
      case SubmissionStatus.late:
        color = Colors.red;
        icon = Icons.warning;
        break;
      case SubmissionStatus.resubmitted:
        color = Colors.purple;
        icon = Icons.repeat;
        break;
    }
    
    return Icon(icon, color: color, size: 16);
  }
} 
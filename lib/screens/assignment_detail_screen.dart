import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:firebase_login/models/assignment_model.dart';
import 'package:firebase_login/models/class_model.dart';
import 'package:firebase_login/models/submission_model.dart';
import 'package:firebase_login/services/database_service.dart';
import 'package:firebase_login/theme/app_theme.dart';
import 'package:firebase_login/utils/utils.dart';
import 'package:firebase_login/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final AssignmentModel assignment;
  final ClassModel classModel;

  const AssignmentDetailScreen({
    Key? key,
    required this.assignment,
    required this.classModel,
  }) : super(key: key);

  @override
  _AssignmentDetailScreenState createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  late TabController _tabController;
  List<SubmissionModel> _submissions = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isExporting = false;

  // Statistics
  int _totalSubmissions = 0;
  int _gradedSubmissions = 0;
  int _aiFeedbackGenerated = 0;
  int _aiFeedbackReviewed = 0;
  double _averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSubmissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmissions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get submissions from the database
      final submissions = await _databaseService.getSubmissionsForAssignment(
        widget.classModel.id,
        widget.assignment.id,
      );

      _calculateStatistics(submissions);

      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load submissions: ${e.toString()}';
      });
    }
  }

  void _calculateStatistics(List<SubmissionModel> submissions) {
    _totalSubmissions = submissions.length;
    _gradedSubmissions = submissions.where((s) => s.isGraded).length;
    _aiFeedbackGenerated = submissions.where((s) => s.isAiFeedbackGenerated).length;
    _aiFeedbackReviewed = submissions.where((s) => s.isAiFeedbackReviewed).length;
    
    if (_gradedSubmissions > 0) {
      final totalScore = submissions
          .where((s) => s.isGraded && s.score != null)
          .map((s) => s.score!)
          .fold(0.0, (sum, score) => sum + score);
      _averageScore = totalScore / _gradedSubmissions;
    } else {
      _averageScore = 0.0;
    }
  }

  Color _getGradientColor(int index) {
    final colors = [
      const Color(0xFF4158D0),
      const Color(0xFFC850C0),
      const Color(0xFFFFCC70),
    ];
    return colors[index % colors.length];
  }

  Color _getStatusColor(SubmissionModel submission) {
    if (submission.isGraded) {
      return Colors.green;
    } else if (submission.submittedAt != null) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  String _getStatusText(SubmissionModel submission) {
    if (submission.isGraded) {
      return 'Graded';
    } else if (submission.submittedAt != null) {
      return 'Submitted';
    } else {
      return 'Not Submitted';
    }
  }

  Future<void> _exportSubmissions() async {
    try {
      setState(() {
        _isExporting = true;
      });

      // Create CSV data
      List<List<dynamic>> csvData = [
        [
          'Student Name', 
          'Status', 
          'Submitted At', 
          'Score', 
          'AI Feedback Generated', 
          'AI Feedback Reviewed'
        ],
      ];

      for (var submission in _submissions) {
        csvData.add([
          submission.studentName,
          _getStatusText(submission),
          submission.submittedAt != null 
              ? DateFormat('MM/dd/yyyy hh:mm a').format(submission.submittedAt!)
              : 'N/A',
          submission.isGraded ? submission.score.toString() : 'N/A',
          submission.isAiFeedbackGenerated ? 'Yes' : 'No',
          submission.isAiFeedbackReviewed ? 'Yes' : 'No',
        ]);
      }

      String csv = const ListToCsvConverter().convert(csvData);
      
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final String fileName = '${widget.assignment.title.replaceAll(' ', '_')}_submissions.csv';
      final String path = '${directory.path}/$fileName';
      
      // Write to file
      final File file = File(path);
      await file.writeAsString(csv);
      
      // Share the file
      await Share.shareXFiles([XFile(path)], text: 'Assignment Submissions');
      
      setState(() {
        _isExporting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export successful')),
      );
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    }
  }

  Widget _buildAssignmentHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getGradientColor(0),
            _getGradientColor(1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.assignment.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.assignment.points > 0 ? '${widget.assignment.points} points' : 'No points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Due: ${widget.assignment.dueDate != null ? Utils.formatDate(widget.assignment.dueDate!) : 'No due date'}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                'Posted by: ${widget.assignment.creatorName}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
          if (widget.assignment.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Description:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.assignment.description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Feedback Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Generated',
                    '$_aiFeedbackGenerated / $_totalSubmissions',
                    Colors.blue,
                    _totalSubmissions > 0 ? _aiFeedbackGenerated / _totalSubmissions : 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatItem(
                    'Reviewed',
                    '$_aiFeedbackReviewed / $_aiFeedbackGenerated',
                    Colors.green,
                    _aiFeedbackGenerated > 0 ? _aiFeedbackReviewed / _aiFeedbackGenerated : 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    // Generate AI feedback for all submissions
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI Feedback generation coming soon')),
                    );
                  },
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Generate All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isExporting ? null : _exportSubmissions,
                  icon: const Icon(Icons.file_download),
                  label: Text(_isExporting ? 'Exporting...' : 'Export Data'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSubmissionsList() {
    if (_submissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment_late, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No submissions yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Students haven\'t submitted this assignment yet',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _submissions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final submission = _submissions[index];
        return _buildSubmissionCard(submission);
      },
    );
  }

  Widget _buildSubmissionCard(SubmissionModel submission) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to submission detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission detail view coming soon')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: submission.studentPhotoUrl != null && submission.studentPhotoUrl!.isNotEmpty
                        ? NetworkImage(submission.studentPhotoUrl!)
                        : null,
                    child: submission.studentPhotoUrl == null || submission.studentPhotoUrl!.isEmpty
                        ? Text(submission.studentName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          submission.studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          submission.submittedAt != null
                              ? 'Submitted: ${DateFormat('MM/dd/yyyy hh:mm a').format(submission.submittedAt!)}'
                              : 'Not submitted yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(submission).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(submission),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getStatusText(submission),
                      style: TextStyle(
                        color: _getStatusColor(submission),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (submission.isGraded) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.score, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Score: ${submission.score?.toStringAsFixed(1) ?? 'N/A'}/${widget.assignment.points}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 16,
                          color: submission.isAiFeedbackGenerated ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          submission.isAiFeedbackGenerated
                              ? submission.isAiFeedbackReviewed
                                  ? 'AI Feedback Reviewed'
                                  : 'AI Feedback Generated'
                              : 'No AI Feedback',
                          style: TextStyle(
                            fontSize: 12,
                            color: submission.isAiFeedbackGenerated ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (submission.submittedAt != null) ...[
                    TextButton.icon(
                      onPressed: () {
                        // View submission
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View submission coming soon')),
                        );
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                  if (!submission.isGraded && submission.submittedAt != null) ...[
                    TextButton.icon(
                      onPressed: () {
                        // Grade submission
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Grade submission coming soon')),
                        );
                      },
                      icon: const Icon(Icons.grading, size: 16),
                      label: const Text('Grade'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                  if (submission.isAiFeedbackGenerated && !submission.isAiFeedbackReviewed) ...[
                    TextButton.icon(
                      onPressed: () {
                        // Review AI feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review AI feedback coming soon')),
                        );
                      },
                      icon: const Icon(Icons.smart_toy, size: 16),
                      label: const Text('Review AI'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppTheme.primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignment Details', style: TextStyle(color: primaryColor)),
        iconTheme: IconThemeData(color: primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.edit, color: primaryColor),
                        title: const Text('Edit Assignment'),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to edit assignment
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit assignment coming soon')),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: const Text('Delete Assignment'),
                        onTap: () {
                          Navigator.pop(context);
                          // Show delete confirmation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Delete assignment coming soon')),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.share, color: primaryColor),
                        title: const Text('Share Assignment'),
                        onTap: () {
                          Navigator.pop(context);
                          // Share assignment
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Share assignment coming soon')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryColor,
          tabs: const [
            Tab(text: 'Submissions'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadSubmissions,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Submissions Tab
                    RefreshIndicator(
                      onRefresh: _loadSubmissions,
                      color: primaryColor,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildFeedbackStats(),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _buildSubmissionsList(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Details Tab
                    RefreshIndicator(
                      onRefresh: _loadSubmissions,
                      color: primaryColor,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAssignmentHeader(),
                            const SizedBox(height: 24),
                            const Text(
                              'Assignment Statistics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            'Total Students',
                                            widget.classModel.studentIds.length.toString(),
                                            Icons.people,
                                            Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            'Submissions',
                                            '$_totalSubmissions/${widget.classModel.studentIds.length}',
                                            Icons.assignment_turned_in,
                                            Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            'Graded',
                                            '$_gradedSubmissions/$_totalSubmissions',
                                            Icons.grading,
                                            Colors.orange,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildStatCard(
                                            'Average Score',
                                            _gradedSubmissions > 0 
                                                ? '${_averageScore.toStringAsFixed(1)}/${widget.assignment.points}'
                                                : 'N/A',
                                            Icons.score,
                                            Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.assignment.fileUrls.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              const Text(
                                'Attachments',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...widget.assignment.fileUrls.map((fileUrl) {
                                final fileName = fileUrl.split('/').last;
                                return Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  child: ListTile(
                                    leading: const Icon(Icons.attachment),
                                    title: Text(fileName),
                                    trailing: const Icon(Icons.download),
                                    onTap: () {
                                      // Download attachment
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Download attachment coming soon')),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 
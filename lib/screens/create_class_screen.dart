import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';
import '../utils/error_handler.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _classCodeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedSubject = AppConstants.subjectOptions[0];
  final DatabaseService _databaseService = DatabaseService();
  bool _isCreating = false;

  // Toggle switches for smart features
  bool _automatedGrading = true;
  bool _instantAiFeedback = true;
  bool _classroomInsights = true;

  // Selection for assignment types
  final Map<String, bool> _assignmentTypes = {
    'Quizzes': true,
    'Projects': true,
    'Discussions': true,
    'Homework': false,
    'Exams': false,
    'Presentations': false,
  };

  @override
  void initState() {
    super.initState();
    // Generate a random class code
    _classCodeController.text = _generateClassCode();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _classCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        6, // Length of code
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  void _showPreviewDialog() {
    final aiGeneratedSummary = '''
# ${_classNameController.text.isEmpty ? 'New Class' : _classNameController.text}

This ${_selectedSubject.toLowerCase()} class will focus on key concepts and practical applications. 
Students will engage in ${_assignmentTypes.entries.where((e) => e.value).map((e) => e.key.toLowerCase()).join(', ')} 
to demonstrate their understanding.

## Learning Objectives:
- Master fundamental ${_selectedSubject.toLowerCase()} concepts
- Develop critical thinking and problem-solving skills
- Apply theoretical knowledge to real-world situations
- Collaborate effectively with peers on group projects

${_automatedGrading ? '✓ Automated grading will provide immediate feedback on assignments.\n' : ''}
${_instantAiFeedback ? '✓ AI-powered feedback will help identify areas for improvement.\n' : ''}
${_classroomInsights ? '✓ Advanced analytics will track student progress throughout the course.\n' : ''}
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI-Generated Class Summary'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              aiGeneratedSummary,
              style: const TextStyle(height: 1.5),
            ),
          ),
        ),
        actions: [
          CustomButton(
            label: 'Close',
            type: ButtonType.outline,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      // Create class in Firestore
      await _databaseService.createClass(
        name: _classNameController.text.trim(),
        subject: _selectedSubject,
        description: _descriptionController.text.trim(),
        hasAutomatedGrading: _automatedGrading,
        hasAiFeedback: _instantAiFeedback,
      );

      if (mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, {'success': true});
      }
    } catch (e) {
      // Show error message with friendly text
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${ErrorHandler.getFriendlyErrorMessage(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user for teacher details
    final user = FirebaseAuth.instance.currentUser;
    final teacherName = user?.displayName ?? 'Not available';
    final teacherEmail = user?.email ?? 'Not available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Class'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                AppTheme.sectionHeader('📌 Class Details'),
                const SizedBox(height: 16),
                
                // Class Name field
                CustomTextField(
                  label: 'Class Name',
                  hint: 'e.g., Math - Grade 10',
                  controller: _classNameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a class name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Subject dropdown
                CustomDropdownField<String>(
                  label: 'Subject',
                  value: _selectedSubject,
                  items: AppConstants.subjectOptions.map((String subject) {
                    return DropdownMenuItem<String>(
                      value: subject,
                      child: Text(subject),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Class Code field with edit option
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Class Code',
                        controller: _classCodeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a class code';
                          }
                          return null;
                        },
                      ),
                    ),
                    CustomIconButton(
                      icon: Icons.refresh,
                      tooltip: 'Generate new code',
                      onPressed: () {
                        setState(() {
                          _classCodeController.text = _generateClassCode();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Class Description field
                CustomTextField(
                  label: 'Class Description',
                  hint: 'Briefly describe the class...',
                  controller: _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                
                // Teacher Details section
                AppTheme.sectionHeader('👨‍🏫 Teacher Details (Auto-Fetched)'),
                const SizedBox(height: 16),
                _buildInfoRow('Teacher Name', teacherName),
                const SizedBox(height: 8),
                _buildInfoRow('Teacher Email', teacherEmail),
                const SizedBox(height: 32),
                
                // Smart Features section
                AppTheme.sectionHeader('⚡ Smart Features'),
                const SizedBox(height: 16),
                _buildFeatureRow(
                  'AI-Generated Class Summary',
                  true,
                  onToggle: null,
                  trailing: CustomIconButton(
                    icon: Icons.description_outlined,
                    tooltip: 'Show Preview',
                    onPressed: _showPreviewDialog,
                  ),
                ),
                _buildFeatureRow(
                  'Automated Grading System',
                  _automatedGrading,
                  onToggle: (value) {
                    setState(() {
                      _automatedGrading = value;
                    });
                  },
                ),
                _buildFeatureRow(
                  'Instant AI Feedback',
                  _instantAiFeedback,
                  onToggle: (value) {
                    setState(() {
                      _instantAiFeedback = value;
                    });
                  },
                ),
                _buildCollaborationRow(),
                _buildFeatureRow(
                  'Classroom Insights',
                  _classroomInsights,
                  onToggle: (value) {
                    setState(() {
                      _classroomInsights = value;
                    });
                  },
                ),
                const SizedBox(height: 32),
                
                // Additional Customization section
                AppTheme.sectionHeader('📌 Additional Customization'),
                const SizedBox(height: 16),
                
                // Assignment Types
                const Text(
                  'Assignment Types:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _assignmentTypes.keys.map((type) {
                    return FilterChip(
                      label: Text(type),
                      selected: _assignmentTypes[type]!,
                      onSelected: (selected) {
                        setState(() {
                          _assignmentTypes[type] = selected;
                        });
                      },
                      selectedColor: AppTheme.secondaryColor.withOpacity(0.2),
                      checkmarkColor: AppTheme.secondaryColor,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                
                // Class Schedule button
                CustomButton(
                  label: 'Set Class Schedule',
                  type: ButtonType.outline,
                  icon: Icons.calendar_today,
                  onPressed: () {
                    // Handle schedule setting
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Schedule setting feature coming soon'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // Class Rules button
                CustomButton(
                  label: 'Edit Class Rules',
                  type: ButtonType.outline,
                  icon: Icons.rule,
                  onPressed: () {
                    // Handle rules editing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rules editing feature coming soon'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Cancel',
                        type: ButtonType.outline,
                        onPressed: _isCreating ? () {} : () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        label: _isCreating ? 'Creating...' : 'Create Class',
                        isLoading: _isCreating,
                        onPressed: _isCreating ? () {} : _createClass,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(
    String title,
    bool value, {
    Function(bool)? onToggle,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
          if (onToggle != null)
            Switch(
              value: value,
              onChanged: onToggle,
              activeColor: AppTheme.secondaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildCollaborationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Collaboration Mode (Add Co-Teacher)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          CustomButton(
            label: 'Invite',
            type: ButtonType.outline,
            icon: Icons.person_add,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Co-teacher invitation feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 
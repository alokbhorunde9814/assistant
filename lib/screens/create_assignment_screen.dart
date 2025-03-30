import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../utils/error_handler.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_app_bar.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final ClassModel classModel;

  const CreateAssignmentScreen({
    super.key,
    required this.classModel,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  
  // Assignment details
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController(text: '10');
  
  // File attachments (would be implemented with Firebase Storage)
  final List<String> _attachments = [];
  
  // Date and time
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _dueTime = TimeOfDay.now();
  
  // Assignment settings
  String _taskType = 'Assignment';
  bool _enableAiFeedback = false;
  bool _isCreatingAssignment = false;
  String? _errorMessage;
  
  // Submission type
  List<String> _selectedSubmissionTypes = ['Text Entry'];
  
  // Assign to students
  bool _assignToAll = true;
  List<StudentModel> _students = [];
  List<String> _selectedStudentIds = [];
  bool _isLoadingStudents = false;
  
  // Visibility
  String _visibility = 'Public';
  
  // Options for dropdowns
  final List<String> _taskTypes = [
    'Assignment',
    'Quiz',
    'Research',
    'Discussion',
    'Project',
    'Presentation',
    'Other'
  ];
  
  final List<String> _submissionTypes = [
    'Text Entry',
    'File Upload',
    'Code Submission',
    'URL Link',
    'Voice Recording',
    'No Submission (Material Only)'
  ];
  
  final List<String> _visibilityOptions = [
    'Public',
    'Private',
    'Scheduled'
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    if (mounted) {
      setState(() {
        _isLoadingStudents = true;
      });
    }

    try {
      final students = await _databaseService.getStudentsForClass(widget.classModel.id);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: ${ErrorHandler.getFriendlyErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreatingAssignment = true;
      _errorMessage = null;
    });

    try {
      // Combine due date and time
      final dueDateTime = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      );

      // Create AI data based on settings
      final Map<String, dynamic> aiData = {};
      if (_enableAiFeedback) {
        aiData['enableFeedback'] = true;
        aiData['feedbackPrompt'] = 'Provide constructive feedback on this ${_taskType.toLowerCase()}';
      }

      // Determine students to assign to
      final List<String> assignedStudentIds = _assignToAll 
          ? widget.classModel.studentIds 
          : _selectedStudentIds;

      // Create the assignment using DatabaseService
      await _databaseService.createAssignment(
        classId: widget.classModel.id,
        title: _titleController.text,
        description: _descriptionController.text,
        dueDate: dueDateTime,
        totalPoints: int.tryParse(_pointsController.text) ?? 10,
        isAutoGraded: _enableAiFeedback,
        resourceUrls: _attachments,
        aiData: {
          ...aiData,
          'taskType': _taskType,
          'submissionTypes': _selectedSubmissionTypes,
          'visibility': _visibility,
          'assignedStudentIds': assignedStudentIds,
        },
      );
      
      if (mounted) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
        _isCreatingAssignment = false;
      });
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && pickedDate != _dueDate) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _selectDueTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );

    if (pickedTime != null && pickedTime != _dueTime) {
      setState(() {
        _dueTime = pickedTime;
      });
    }
  }

  void _addAttachment() {
    // In a real app, this would open a file picker
    // For the demo, we'll just add a placeholder
    setState(() {
      _attachments.add('Sample Attachment ${_attachments.length + 1}');
    });
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _toggleSubmissionType(String type) {
    setState(() {
      if (_selectedSubmissionTypes.contains(type)) {
        _selectedSubmissionTypes.remove(type);
      } else {
        _selectedSubmissionTypes.add(type);
      }
    });
  }

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _generateAiSuggestions() {
    // In a real app, this would call an AI service
    // For the demo, we'll just show a sample suggestion
    final suggestions = _taskType == 'Quiz'
        ? "1. What is the capital of France?\n2. Who wrote 'Romeo and Juliet'?\n3. What is the chemical formula for water?"
        : "Consider analyzing the impact of climate change on local ecosystems. Compare historical data with current trends and propose sustainable solutions.";

    setState(() {
      _descriptionController.text = suggestions;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI-generated content added to description!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Create Assignment',
      ),
      body: _isCreatingAssignment
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Assignment Title
                    _buildSectionHeader('Title', Icons.title),
                    CustomTextField(
                      controller: _titleController,
                      hintText: 'Enter assignment title',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Description
                    _buildSectionHeader('Description', Icons.description),
                    CustomTextField(
                      controller: _descriptionController,
                      hintText: 'Enter details here...',
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    
                    // AI Suggestions Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _generateAiSuggestions,
                        icon: const Icon(Icons.psychology, size: 18),
                        label: const Text('Generate AI Suggestions'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Attachments
                    _buildSectionHeader('Attachments', Icons.attach_file),
                    if (_attachments.isEmpty)
                      const Text(
                        'No attachments added yet',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    
                    // List of attachments
                    ..._attachments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final attachment = entry.value;
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(attachment),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeAttachment(index),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    
                    // Add attachment button
                    OutlinedButton.icon(
                      onPressed: _addAttachment,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Attachment'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Due Date and Time
                    _buildSectionHeader('Due Date & Time', Icons.calendar_today),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _selectDueDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: const Icon(Icons.calendar_month),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_dueDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: _selectDueTime,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                suffixIcon: const Icon(Icons.access_time),
                              ),
                              child: Text(
                                _dueTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Task Type
                    _buildSectionHeader('Task Type', Icons.category),
                    DropdownButtonFormField<String>(
                      value: _taskType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _taskTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _taskType = newValue;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Grading
                    _buildSectionHeader('Grading', Icons.grade),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _pointsController,
                            hintText: 'Points',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.numbers,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'points',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Enable AI Feedback
                    _buildSectionHeader('AI Auto-Feedback', Icons.psychology),
                    SwitchListTile(
                      title: const Text('Enable AI feedback and grading assistance'),
                      value: _enableAiFeedback,
                      onChanged: (bool value) {
                        setState(() {
                          _enableAiFeedback = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Submission Types
                    _buildSectionHeader('Submission Type', Icons.upload_file),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _submissionTypes.map((type) {
                        final isSelected = _selectedSubmissionTypes.contains(type);
                        return FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryColor,
                          onSelected: (bool selected) {
                            _toggleSubmissionType(type);
                          },
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Assign To
                    _buildSectionHeader('Assign To', Icons.people),
                    
                    // All students switch
                    SwitchListTile(
                      title: const Text('Assign to all students'),
                      value: _assignToAll,
                      onChanged: (bool value) {
                        setState(() {
                          _assignToAll = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    
                    // Student selection list (visible when not assigning to all)
                    if (!_assignToAll) ...[
                      if (_isLoadingStudents)
                        const Center(child: CircularProgressIndicator())
                      else if (_students.isEmpty)
                        const Text(
                          'No students in this class yet',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        )
                      else
                        ...List.generate(_students.length, (index) {
                          final student = _students[index];
                          final isSelected = _selectedStudentIds.contains(student.id);
                          
                          return CheckboxListTile(
                            title: Text(student.name),
                            subtitle: Text(student.email),
                            value: isSelected,
                            onChanged: (bool? value) {
                              if (value != null) {
                                _toggleStudentSelection(student.id);
                              }
                            },
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                    ],
                    
                    const SizedBox(height: 20),
                    
                    // Visibility
                    _buildSectionHeader('Visibility', Icons.visibility),
                    DropdownButtonFormField<String>(
                      value: _visibility,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _visibilityOptions.map((String visibility) {
                        return DropdownMenuItem<String>(
                          value: visibility,
                          child: Text(visibility),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _visibility = newValue;
                          });
                        }
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Error message
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    
                    // Create button
                    CustomButton(
                      label: 'Save & Publish',
                      icon: Icons.save,
                      fullWidth: true,
                      onPressed: _createAssignment,
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import '../services/database_service.dart';
import '../utils/error_handler.dart';

class JoinClassScreen extends StatefulWidget {
  const JoinClassScreen({super.key});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classCodeController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  bool _isJoining = false;
  String? _errorMessage;

  void _joinClass() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isJoining = true;
        _errorMessage = null;
      });

      try {
        // Join class using the database service
        final classModel = await _databaseService.joinClassWithCode(
          _classCodeController.text.trim(),
        );

        if (mounted) {
          // Show success and navigate back with the class info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined ${classModel.name}!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, {
            'success': true, 
            'code': classModel.code,
            'name': classModel.name,
            'subject': classModel.subject,
          });
        }
      } catch (e) {
        // Show error message with friendly text
        setState(() {
          _errorMessage = ErrorHandler.getFriendlyErrorMessage(e);
        });
      } finally {
        if (mounted) {
          setState(() {
            _isJoining = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Class'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Join a Class',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the class code provided by your teacher to join',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Class Code Section
                const Text(
                  'Enter Class Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask your teacher for the class code, then enter it here.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'Class Code',
                  hint: 'e.g., ABC123',
                  controller: _classCodeController,
                  prefixIcon: Icons.key,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a class code';
                    }
                    if (value.length < 5) {
                      return 'Class code must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                
                // Error message if any
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Information Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'What happens when you join?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• You\'ll be added to the class roster\n'
                        '• You\'ll receive notifications for assignments\n'
                        '• Your teacher will see your name and email\n'
                        '• You can access all class materials and resources',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Cancel',
                        type: ButtonType.outline,
                        onPressed: _isJoining ? () {} : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        label: _isJoining ? 'Joining...' : 'Join Class',
                        isLoading: _isJoining,
                        onPressed: _isJoining ? () {} : _joinClass,
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
} 
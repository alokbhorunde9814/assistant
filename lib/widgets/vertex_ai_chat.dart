import 'package:flutter/material.dart';
import '../services/vertex_ai_service.dart';

class VertexAIChat extends StatefulWidget {
  const VertexAIChat({super.key});

  @override
  State<VertexAIChat> createState() => _VertexAIChatState();
}

class _VertexAIChatState extends State<VertexAIChat> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _messages = [];
  bool _isLoading = false;
  final VertexAIService _vertexAIService = VertexAIService();

  @override
  void initState() {
    super.initState();
    _initializeVertexAI();
  }

  Future<void> _initializeVertexAI() async {
    try {
      // Load the credentials file
      final String credentialsJson = await DefaultAssetBundle.of(context).loadString('assets/credentials/vertex_ai_credentials.json');
      await _vertexAIService.initialize(credentialsJson);
      setState(() {
        _messages.add('AI: Vertex AI initialized successfully. How can I help you today?');
      });
    } catch (e) {
      setState(() {
        _messages.add('Error: Failed to initialize Vertex AI. Please check the following:\n'
            '1. Make sure the Vertex AI API is enabled in your Google Cloud Console\n'
            '2. Verify that your service account has the necessary permissions\n'
            '3. Check if your credentials file is properly formatted\n\n'
            'Error details: $e');
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _messages.add('You: ${_promptController.text}');
      _isLoading = true;
    });

    try {
      final response = await _vertexAIService.generateText(_promptController.text);
      setState(() {
        _messages.add('AI: $response');
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add('Error: $e');
        _isLoading = false;
      });
    }

    _promptController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                padding: const EdgeInsets.all(16.0),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUserMessage = message.startsWith('You: ');
                  
                  return Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isUserMessage ? Theme.of(context).primaryColor : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _vertexAIService.dispose();
    super.dispose();
  }
} 
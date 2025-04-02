import 'package:flutter/material.dart';
import '../services/vertex_ai_service.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

class VertexAIChat extends StatefulWidget {
  const VertexAIChat({super.key});

  @override
  State<VertexAIChat> createState() => _VertexAIChatState();
}

class _VertexAIChatState extends State<VertexAIChat> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final VertexAIService _vertexAIService;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      final credentialsJson = await rootBundle.loadString('assets/credentials/vertex_ai_credentials.json');
      final credentialsMap = json.decode(credentialsJson) as Map<String, dynamic>;
      _vertexAIService = VertexAIService();
      await _vertexAIService.initialize(credentialsMap);
      setState(() {
        _isInitialized = true;
        _messages.add(ChatMessage(
          text: 'Vertex AI initialized successfully. How can I help you today?',
          isUser: false,
        ));
      });
    } catch (e) {
      print('Error loading credentials: $e');
      setState(() {
        _error = 'Failed to initialize Vertex AI: $e';
        _messages.add(ChatMessage(
          text: 'Error: Failed to initialize Vertex AI. Please check the following:\n'
              '1. Make sure the Vertex AI API is enabled in your Google Cloud Console\n'
              '2. Verify that your service account has the necessary permissions\n'
              '3. Check if your credentials file is properly formatted\n\n'
              'Error details: $e',
          isUser: false,
          isError: true,
        ));
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: 'You: ${_textController.text}',
        isUser: true,
      ));
      _isLoading = true;
    });

    try {
      final response = await _vertexAIService.generateText(_textController.text);
      setState(() {
        _messages.add(ChatMessage(
          text: 'AI: $response',
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _textController.clear();
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
                  final isUserMessage = message.isUser;
                  
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
                        message.text,
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
                      controller: _textController,
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
    _textController.dispose();
    _vertexAIService.dispose();
    super.dispose();
  }
} 
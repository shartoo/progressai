import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:flutter_gemma/core/chat.dart';
import '../model_chat.dart';

class BookChatScreen extends StatefulWidget {
  final String bookTitle;
  final String contentFilePath; // Path to the local TXT/PDF file
  final InferenceChat chatEngine; // LLM chat engine

  const BookChatScreen({
    Key? key,
    required this.bookTitle,
    required this.contentFilePath,
    required this.chatEngine,
  }) : super(key: key);

  @override
  State<BookChatScreen> createState() => _BookChatScreenState();
}

class _BookChatScreenState extends State<BookChatScreen> with SingleTickerProviderStateMixin {
  PdfController? _pdfController; // Changed to nullable PdfController
  late String _bookContent; // Stores the full book content (text)
  int _currentPage = 1; // Current page number (for PDF/simulated for TXT)
  int _totalPages = 1; // Total pages (for PDF/simulated for TXT)

  bool _showChat = false; // Controls chat dialog visibility
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Stores chat messages
  final ModelChat _modelChat = ModelChat();
  final ScrollController _chatScrollController = ScrollController(); // For chat ListView

  bool _isLoadingBook = true; // Book loading status
  bool _isLLMThinking = false; // LLM thinking status

  @override
  void initState() {
    super.initState();
    _loadBookContent();
  }

  @override
  void dispose() {
    // Ensure _pdfController is initialized before disposing
    _pdfController?.dispose(); // Safely dispose if not null
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  // Load book content (PDF or TXT)
  Future<void> _loadBookContent() async {
    setState(() {
      _isLoadingBook = true;
    });

    try {
      final file = File(widget.contentFilePath);
      final fileExtension = widget.contentFilePath.split('.').last.toLowerCase();

      if (fileExtension == 'pdf') {
        // Correctly open PdfDocument and then create PdfController
        final pdfDocument = await PdfDocument.openFile(file.path);
        _pdfController = PdfController(document: Future.value(pdfDocument)); // Wrap PdfDocument in a Future.value

        setState(() {
          _totalPages = pdfDocument.pagesCount; // Access pagesCount directly
        });

        // For LLM context, extract all text from PDF
        _bookContent = await ReadPdfText.getPDFtext(file.path);
      } else if (fileExtension == 'txt') {
        _bookContent = await file.readAsString();
        // For TXT, simulate pages by chunking content
        _totalPages = (_bookContent.length / 1000).ceil(); // Roughly 1000 chars per page
        // No PdfController needed for TXT files, so _pdfController remains null
      } else {
        _bookContent = 'Unsupported file type.';
        _showMessage('Unsupported file type. Only PDF and TXT are supported.');
      }
    } catch (e) {
      _bookContent = 'Error loading book content: $e';
      _showMessage('Error loading book content: $e');
      print('Error loading book content: $e');
    } finally {
      setState(() {
        _isLoadingBook = false;
      });
    }
  }

  // Get current page's text content for LLM
  String _getCurrentPageContent() {
    if (_bookContent.isEmpty) return 'No content available.';

    final fileExtension = widget.contentFilePath.split('.').last.toLowerCase();

    if (fileExtension == 'pdf') {
      // For PDF, we have the full text, so we can extract based on current page
      // This is a simplification. A real PDF reader would provide text per page.
      // Here, we'll just take a chunk from the overall text based on page number.
      final int chunkSize = (_bookContent.length / _totalPages).ceil();
      final int startIndex = (_currentPage - 1) * chunkSize;
      final int endIndex = (startIndex + chunkSize).clamp(0, _bookContent.length);
      return _bookContent.substring(startIndex, endIndex);
    } else if (fileExtension == 'txt') {
      // For TXT, we chunked it earlier, so use that logic
      final int chunkSize = (_bookContent.length / _totalPages).ceil();
      final int startIndex = (_currentPage - 1) * chunkSize;
      final int endIndex = (startIndex + chunkSize).clamp(0, _bookContent.length);
      return _bookContent.substring(startIndex, endIndex);
    }
    return 'Content not available for current page.';
  }

  // Toggle chat dialog visibility
  void _toggleChat() {
    setState(() {
      _showChat = !_showChat;
    });
    if (_showChat) {
      _chatScrollToBottom();
    }
  }

  // Send message to LLM
  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add({
        'role': 'user',
        'text': userMessage,
        'time': DateFormat('hh:mma').format(DateTime.now()),
      });
      _isLLMThinking = true;
    });
    _chatScrollToBottom();

    final currentPageContent = _getCurrentPageContent();

    // Construct the prompt for the LLM
    final String prompt = """
      You are an AI assistant helping a user understand a book.
      The user is currently reading a book. Here is the content of their current page:
      ---
      $currentPageContent
      ---
      
      User's question/comment: "$userMessage"
      
      Based on the current page content and the user's input, please provide a helpful and concise response.
      If the question is directly related to the content, explain it. If it's a general question, answer it.
      """;

    try {
      final jsonResponse = await _modelChat.chat(
        chatEngine: widget.chatEngine,
        text: prompt,
      );
      final response = ModelChat.parseResponse(jsonResponse);
      final llmResponseText = ModelChat.getMessage(response) ?? 'I could not process that. Please try again.';

      setState(() {
        _messages.add({
          'role': 'llm',
          'text': llmResponseText,
          'time': DateFormat('hh:mma').format(DateTime.now()),
        });
      });
    } catch (e) {
      print('LLM interaction error: $e');
      setState(() {
        _messages.add({
          'role': 'llm',
          'text': 'Sorry, I encountered an error while processing your request.',
          'time': DateFormat('hh:mma').format(DateTime.now()),
        });
      });
    } finally {
      setState(() {
        _isLLMThinking = false;
      });
      _chatScrollToBottom();
    }
  }

  // Scroll chat to bottom
  void _chatScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Show SnackBar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine file type
    final fileExtension = widget.contentFilePath.split('.').last.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Stack(
        children: [
          // Book Content Area
          _isLoadingBook
              ? const Center(child: CircularProgressIndicator())
              : (fileExtension == 'pdf' && _pdfController != null) // Only show PdfView if it's a PDF and controller is initialized
              ? PdfView(
            controller: _pdfController!, // Use non-nullable access here
            onPageChanged: (page) {
              setState(() {
                _currentPage = page; // Update current page directly here
              });
            },
          )
              : SingleChildScrollView( // For TXT files or if PDF controller is not ready
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _bookContent,
              style: const TextStyle(fontSize: 16.0),
            ),
          ),

          // Page Number Display (for PDF and simulated for TXT)
          if (!_isLoadingBook)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Page $_currentPage / $_totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),

          // Chat Dialog
          if (_showChat)
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
                height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AI Book Assistant',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.blueGrey),
                            onPressed: _toggleChat,
                          ),
                        ],
                      ),
                    ),
                    // Chat Messages Area
                    Expanded(
                      child: ListView.builder(
                        controller: _chatScrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Column(
                                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['text']!,
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    message['time']!,
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // LLM Thinking Indicator
                    if (_isLLMThinking)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(strokeWidth: 2),
                            const SizedBox(width: 10),
                            Text('AI is thinking...', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    // Message Input Area
                    Padding(
                      padding: EdgeInsets.only(
                        left: 8.0,
                        right: 8.0,
                        bottom: 8.0 + MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              maxLines: null, // Auto-wrap
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                hintText: 'Ask about the book...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          FloatingActionButton(
                            onPressed: _sendMessage,
                            mini: true,
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Floating Chat Button
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.5 - 28, // Center vertically
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              child: Icon(_showChat ? Icons.close : Icons.chat),
            ),
          ),
        ],
      ),
    );
  }
}

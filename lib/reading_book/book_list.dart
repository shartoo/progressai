import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart'; // Ensure this library is imported
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model_chat.dart';
import 'book_detail.dart';
import 'package:flutter_gemma/flutter_gemma.dart'; // Import type required for chatEngine


// Book data model
class Book {
  final String id; // Unique book ID
  final String title; // Title
  final String author; // Author
  final double progress; // Reading progress (0-100)
  final String description; // Brief description
  final String coverImage; // Cover image URL or local path (using placeholder URL here)
  final String contentFilePath; // Local TXT file path
  String mindMapData; // Mind map JSON data (stores JSON string of hierarchy) - mutable
  String roleMapData; // Character relationship map JSON data (stores JSON string of character_relationships) - mutable
  final int pageNum;  // Number of pages

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.progress,
    required this.description,
    required this.coverImage,
    required this.contentFilePath,
    this.mindMapData = '', // Default to empty
    this.roleMapData = '', // Default to empty
    required this.pageNum
  });

  // Create Book object from JSON data
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      pageNum: json['pageNum'] ?? 0, // Provide default value
      progress: json['progress']?.toDouble() ?? 0.0, // Provide default value
      description: json['description'] ?? '', // Provide default value
      coverImage: json['coverImage'] ?? 'https://placehold.co/100x150/e0e0e0/333333?text=Book', // Provide default value
      contentFilePath: json['contentFilePath'] ?? '', // Provide default value
      mindMapData: json['mindMapData'] ?? '', // Provide default value
      roleMapData: json['roleMapData'] ?? '', // Provide default value
    );
  }

  // Convert Book object to JSON data
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'progress': progress,
      'description': description,
      'coverImage': coverImage,
      'pageNum': pageNum,
      'contentFilePath': contentFilePath,
      'mindMapData': mindMapData,
      'roleMapData': roleMapData,
    };
  }

  // New method: Read full book content
  Future<String> readContent() async {
    try {
      final file = File(contentFilePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return 'File does not exist or cannot be read.';
    } catch (e) {
      print('Failed to read book content: $e');
      return 'Failed to read book content.';
    }
  }
}

class BookListScreen extends StatefulWidget {
  final InferenceChat chatEngine;
  const BookListScreen({
    super.key,
    required this.chatEngine,
  });

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List<Book> _books = []; // List of books
  bool _isLoading = true; // Loading status
  bool _isUploading = false; // Uploading status
  // Removed _isAnalyzing and _analysisProgress as analysis runs in background
  final ModelChat _modelChat = ModelChat();
  late String _localBooksMetadataPath; // Local book metadata file path (using SharedPreferences now, but kept for future file storage)
  late String _localBookContentsDirPath; // Local book content directory path

  @override
  void initState() {
    super.initState();
    _initializePathsAndLoadBooks(); // Initialize paths and load books
  }

  // Initialize local file paths and load book data
  Future<void> _initializePathsAndLoadBooks() async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // Get application documents directory
      // Define book metadata file path (now mainly managed by SharedPreferences)
      _localBooksMetadataPath = '${directory.path}/books_metadata.json';
      // Define book content storage directory
      _localBookContentsDirPath = '${directory.path}/book_contents';
      // Ensure book content directory exists
      final contentDir = Directory(_localBookContentsDirPath);
      if (!await contentDir.exists()) {
        await contentDir.create(recursive: true);
      }

      await _loadBooks(); // Load books
    } catch (e) {
      _showMessage('Initialization failed: $e'); // Show error message
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  // Load book list from local file (now via SharedPreferences)
  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? booksJsonString = prefs.getString('books_data'); // Get JSON string from SharedPreferences

      if (booksJsonString != null && booksJsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(booksJsonString); // Parse JSON string
        setState(() {
          _books = jsonList.map((json) => Book.fromJson(json)).toList(); // Convert to Book object list
        });
      } else {
        setState(() {
          _books = []; // If no data, set to empty list
        });
      }
    } catch (e) {
      _showMessage('Failed to load books: $e'); // Show error message
      _books = []; // Ensure list is empty to avoid UI errors
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  // Save book list to local file (now via SharedPreferences)
  Future<void> _saveBooks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_books.map((book) => book.toJson()).toList()); // Convert book list to JSON string
      await prefs.setString('books_data', jsonString); // Save to SharedPreferences
    } catch (e) {
      _showMessage('Failed to save books: $e'); // Show error message
    }
  }

  // Delete a book
  Future<void> _deleteBook(Book book) async {
    try {
      // Delete local content file
      final contentFile = File(book.contentFilePath);
      if (await contentFile.exists()) {
        await contentFile.delete();
      }

      // Remove book from list
      setState(() {
        _books.removeWhere((b) => b.id == book.id);
      });

      // Save updated book list
      await _saveBooks();

      _showMessage('Book deleted successfully!');
    } catch (e) {
      _showMessage('Failed to delete book: $e');
      print('Failed to delete book: $e');
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteConfirmDialog(Book book) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete "${book.title}"?\n\nThis action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBook(book);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Split text into larger chunks to reduce parsing frequency
  List<String> _splitTextIntoChunks(String text, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(text.substring(i, end));
    }
    return chunks;
  }

  // Clean LLM JSON response text
  String _cleanJsonResponse(String responseText) {
    String cleaned = responseText.trim();
    // Remove Markdown code block tags from the beginning
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    // Remove Markdown code block tags from the end
    if (cleaned.endsWith('```--- END ---')) {
      cleaned = cleaned.substring(0, cleaned.length - 14);
    } else if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    // Remove possible extra tags
    cleaned = cleaned.replaceAll('--- END ---', '');
    cleaned = cleaned.replaceAll('END', '');

    // Clean leading/trailing whitespace again
    cleaned = cleaned.trim();

    return cleaned;
  }

  // Use LLM to analyze text chunks, extracting hierarchy and character relationships
  Future<Map<String, dynamic>> _analyzeTextChunk(String textChunk) async {
    try {
      String prompt = '''
         Please act as a professional text analyst. Your task is to extract key information from the following book content. You need to identify and organize two categories of information:
          Book Chapter Structure and Summary (Hierarchy):
          Identify main chapters, sub-chapters, or core themes within the text.
          Provide a concise summary for each chapter/theme.
          If there are clear hierarchical relationships (e.g., sections within chapters, or sub-themes within themes), represent this structure as a nested list.
          Character Relationships:
          Identify all main characters appearing in the text.
          Analyze and extract key relationships between these characters.
          Provide a brief description for each relationship.
          Please strictly return all extracted information in the following JSON format:
          {
          "hierarchy": [
            {
              "id": "unique_chapter_or_theme_ID (string)",
              "title": "Chapter/Theme Title (string)",
              "summary": "Concise summary of the chapter/theme (string)",
              "children": [
                {
                  "id": "unique_sub_chapter_or_sub_theme_ID (string)",
                  "title": "Sub-chapter/Sub-theme Title (string)",
                  "summary": "Concise summary of the sub-chapter/sub-theme (string)",
                  "children": [] // Empty array if no deeper nested children
                }
                // ... more sub-chapters/sub-themes
              ]
            }
            // ... more chapters/themes
          ],
          "character_relationships": [
            {
            "nodes": [
                  {"id": "Short Name of Character A (string)", "label": "Name of Character A (string)"},
                  {"id": "Short Name of Character A (string)", "label": "Name of Character B (string)"},
                  // .. more character name(title)
              ],
               "edges": [
                      {"source": "Id in nodes", "target": "Another Id in nodes", "label": "Type of relationship (e.g., 'friend', 'enemy', 'family', 'mentor-mentee', 'colleague', etc., summarize based on text content)"},
                      // .. more relationship of modes
                   ]
            }
            // ... more character relationships
          ]
        }
         Important: Return only pure JSON format, do not include any Markdown tags, code block tags, or other text. Do not use ```json or ``` tags。
         Book Content:
         $textChunk
         ''';
      print("Sending chat message to LLM!");
      final jsonResponse = await _modelChat.chat(
        chatEngine: widget.chatEngine,
        text: prompt,
      );
      print("Waiting for model chat result!");
      print(jsonResponse);
      print("------------JSON 直接结果----------- ");
      String cleanedText = _cleanJsonResponse(jsonResponse); // 使用ModelChat的静态方法
      // 尝试解析JSON响应
      try {
        final Map<String, dynamic> result = jsonDecode(cleanedText);
        return result;
      } catch (e) {
        print('JSON parsing failed: $e');
        print('Cleaned text: $cleanedText');
        return {
          "hierarchy": [],
          "character_relationships": []
        };
      }
    } catch (e) {
      print('LLM analysis failed: $e');
      return {
        "hierarchy": [],
        "character_relationships": []
      };
    }
  }

  // Merge analysis results from multiple text chunks
  Map<String, dynamic> _mergeAnalysisResults(List<Map<String, dynamic>> results) {
    List<dynamic> mergedHierarchy = [];
    List<dynamic> mergedCharacterRelationships = [];

    for (var result in results) {
      if (result.containsKey('hierarchy') && result['hierarchy'] is List) {
        mergedHierarchy.addAll(result['hierarchy']);
      }
      if (result.containsKey('character_relationships') && result['character_relationships'] is List) {
        mergedCharacterRelationships.addAll(result['character_relationships']);
      }
    }
    return {
      "hierarchy": mergedHierarchy,
      "character_relationships": mergedCharacterRelationships
    };
  }

  // Handle file selection and upload
  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true; // Set uploading status
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'], // Allow PDF and TXT files
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!); // Get selected file
        String fileName = result.files.single.name; // Get file name
        String fileExtension = fileName.split('.').last.toLowerCase(); // Get file extension
        String bookContent = ''; // Book content
        String bookTitle = fileName.replaceAll('.$fileExtension', ''); // Extract title from filename
        String bookDescription = 'description'; // Default description
        int pageNum = 0;

        if (fileExtension == 'pdf') {
          // Process PDF file
          try {
            // 使用 read_pdf_text 包提取PDF文本
            String pdfText = await ReadPdfText.getPDFtext(file.path);
            if (pdfText.isNotEmpty) {
              bookContent = pdfText;
            } else {
              _showMessage('Can not extract content from book,please check!');
              return;
            }

          } catch (pdfError) {
            _showMessage('Parsing PDF failed: $pdfError');
            return;
          }

            bookDescription = bookContent.length > 150
                ? '${bookContent.substring(0, 150)}...'
                : bookContent;
            return;

        } else if (fileExtension == 'txt') {
          // Process TXT file
          bookContent = await file.readAsString();
          pageNum = (bookContent.length / 1000).ceil(); // Estimate page count
          bookDescription = bookContent.length > 150
              ? '${bookContent.substring(0, 150)}...'
              : bookContent;
        } else {
          _showMessage('Unsupported file type. Only PDF and TXT are supported.');
          return;
        }

        // Save book content to local TXT file
        final String contentFileName = '${bookTitle.replaceAll(' ', '_')}.txt';
        final File localContentFile = File('$_localBookContentsDirPath/$contentFileName');
        await localContentFile.writeAsString(bookContent);

        // Create new Book object, mindMapData and roleMapData are initially empty
        final newBook = Book(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: bookTitle,
          author: 'Author', // Default author
          progress: 0.0, // New book progress is 0
          description: bookDescription,
          coverImage: 'https://placehold.co/100x150/e0e0e0/333333?text=Book', // Placeholder cover image
          contentFilePath: localContentFile.path, // Save local content file path
          pageNum: pageNum, // Set total pages (here, number of text chunks)
          mindMapData: '', // Initially empty
          roleMapData: '', // Initially empty
        );

        setState(() {
          _books.add(newBook); // Add new book to list
          _isUploading = false; // Stop uploading status
        });
        await _saveBooks(); // Save updated book list
        _showMessage('Book uploaded successfully! AI analysis is starting in the background.'); // Show success message

        // Start LLM analysis in the background
        _performLLMAnalysisInBackground(newBook.id, bookContent);

      } else {
        _showMessage('File selection cancelled.');
      }
    } catch (e) {
      _showMessage('File processing or upload failed: $e');
      print('File processing or upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Perform LLM analysis in the background
  Future<void> _performLLMAnalysisInBackground(String bookId, String bookContent) async {
    try {
      List<String> textChunks = _splitTextIntoChunks(bookContent, 1000);
      List<Map<String, dynamic>> analysisResults = [];

      for (int i = 0; i < textChunks.length; i++) {
        final result = await _analyzeTextChunk(textChunks[i]);
        analysisResults.add(result);
        // Can consider updating a global analysis progress here, but avoiding setState to not block UI
        print('Background analysis progress: ${(i + 1) / textChunks.length * 100}%');
      }

      final mergedResults = _mergeAnalysisResults(analysisResults);

      final String finalMindMapData = jsonEncode(mergedResults['hierarchy']);
      final String finalRoleMapData = jsonEncode(mergedResults['character_relationships']);

      // Find the corresponding book and update its data
      final int bookIndex = _books.indexWhere((book) => book.id == bookId);
      if (bookIndex != -1) {
        setState(() {
          _books[bookIndex].mindMapData = finalMindMapData;
          _books[bookIndex].roleMapData = finalRoleMapData;
        });
        await _saveBooks(); // Save updated book list
        _showMessage('gemma-3n analysis completed for "${_books[bookIndex].title}"!');
      }
    } catch (e) {
      print('Background gemma-3n analysis failed for book $bookId: $e');
      _showMessage('gemma-3n analysis failed for book $bookId: $e');
    }
  }

  // Show SnackBar message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // Make SnackBar float
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
        margin: const EdgeInsets.all(10), // Margin
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        centerTitle: true,
        backgroundColor: Colors.purple[100],
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Container(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.purple)) // Loading indicator
                    : _books.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 80, color: Colors.purple.withOpacity(0.7)),
                      const SizedBox(height: 16),
                      Text(
                        'You haven\'t added any books yet.',
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click the button below to upload your first book!',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    final book = _books[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Rounded card
                      ),
                      child: InkWell( // Wrap Card with InkWell to make it clickable
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          // Navigate to book detail screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailScreen(book: book, chatEngine: widget.chatEngine),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Book Cover
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox( // Use SizedBox instead of Container for fixed size
                                        width: 90,
                                        height: 135,
                                        child: Image.network(
                                          book.coverImage,
                                          width: 90,
                                          height: 135,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/book_cover.jpg', // Fallback to local asset
                                              width: 90,
                                              height: 135,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  width: 90,
                                                  height: 135,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.book, size: 50, color: Colors.grey),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Book Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            book.title,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'by ${book.author}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Reading Progress Bar
                                          Row(
                                            children: [
                                              Expanded(
                                                child: LinearProgressIndicator(
                                                  value: book.progress / 100,
                                                  backgroundColor: Colors.grey[300],
                                                  color: Colors.purple,
                                                  borderRadius: BorderRadius.circular(5),
                                                  minHeight: 8,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${book.progress.toInt()}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Brief Description
                                          Text(
                                            book.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          // Rating
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber[600], size: 16),
                                              const SizedBox(width: 4),
                                              // Assuming book.rating exists and is a double
                                              // Note: book.rating is not part of the Book model in the provided code.
                                              // If it's intended to be displayed, please add 'rating' to the Book class.
                                              // For now, I'll add a placeholder or remove if not needed.
                                              // Added a placeholder for rating to avoid error, assuming it's a double.
                                              Text(
                                                '${(Random().nextDouble() * (5 - 3) + 3).toStringAsFixed(1)}', // Placeholder rating
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          // LLM analysis status indicator
                                          if (book.mindMapData.isEmpty || book.roleMapData.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'AI analysis in progress...',
                                                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete button - positioned at bottom right
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => _showDeleteConfirmDialog(book),
                                    padding: const EdgeInsets.all(8),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom upload button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickFile, // Disable button during upload
        label: Text(_isUploading ? 'Uploading...' : '.pdf .txt'),
        icon: _isUploading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.cloud_upload),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), // Rounded button
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Centered floating button
    );
  }
}

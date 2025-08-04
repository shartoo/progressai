import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../model_chat.dart';
import 'book_detail.dart';

// 书籍数据模型
class Book {
  final String id; // 书籍唯一ID
  final String title; // 标题
  final String author; // 作者
  final double progress; // 阅读进度 (0-100)
  final String description; // 简单描述
  final String coverImage; // 封面图片URL或本地路径 (这里使用占位符URL)
  final String contentFilePath; // 本地保存的TXT文件路径
  final String mindMapData; // 思维导图JSON数据
  final String roleMapData; // 角色关系图
  final int pageNum;  // 页数

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.progress,
    required this.description,
    required this.coverImage,
    required this.contentFilePath,
    required this.mindMapData,
    required this.roleMapData,
    required this.pageNum
  });

  // 从JSON数据创建Book对象
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      pageNum: json['pageNum'] ?? 0, // 提供默认值
      progress: json['progress']?.toDouble() ?? 0.0, // 提供默认值
      description: json['description'] ?? '', // 提供默认值
      coverImage: json['coverImage'] ?? 'https://placehold.co/100x150/e0e0e0/333333?text=Book', // 提供默认值
      contentFilePath: json['contentFilePath'] ?? '', // 提供默认值
      mindMapData: json['mindMapData'] ?? '', // 提供默认值
      roleMapData: json['roleMapData'] ?? '', // 提供默认值
    );
  }

  // 将Book对象转换为JSON数据
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

  // 新增方法：读取书籍的完整内容
  Future<String> readContent() async {
    try {
      final file = File(contentFilePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return '文件不存在或无法读取。';
    } catch (e) {
      print('读取书籍内容失败: $e');
      return '读取书籍内容失败。';
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
  List<Book> _books = []; // 书籍列表
  bool _isLoading = true; // 加载状态
  bool _isUploading = false; // 上传状态
  bool _isAnalyzing = false; // LLM解析状态
  double _analysisProgress = 0.0; // LLM解析进度
  final ModelChat _modelChat = ModelChat();
  late String _localBooksMetadataPath; // 本地书籍元数据文件路径 (虽然现在用SharedPreferences，但保留以防未来文件存储)
  late String _localBookContentsDirPath; // 本地书籍内容文件夹路径

  @override
  void initState() {
    super.initState();
    _initializePathsAndLoadBooks(); // 初始化路径并加载书籍
  }

  // 初始化本地文件路径并加载书籍数据
  Future<void> _initializePathsAndLoadBooks() async {
    try {
      final directory = await getApplicationDocumentsDirectory(); // 获取应用文档目录
      // 定义书籍元数据文件路径 (现在主要通过SharedPreferences管理)
      _localBooksMetadataPath = '${directory.path}/books_metadata.json';
      // 定义书籍内容存储目录
      _localBookContentsDirPath = '${directory.path}/book_contents';
      // 确保书籍内容目录存在
      final contentDir = Directory(_localBookContentsDirPath);
      if (!await contentDir.exists()) {
        await contentDir.create(recursive: true);
      }

      await _loadBooks(); // 加载书籍
    } catch (e) {
      _showMessage('初始化失败: $e'); // 显示错误信息
      setState(() {
        _isLoading = false; // 停止加载
      });
    }
  }

  // 从本地文件加载书籍列表 (现在通过SharedPreferences)
  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true; // 开始加载
    });
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? booksJsonString = prefs.getString('books_data'); // 从SharedPreferences获取JSON字符串

      if (booksJsonString != null && booksJsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(booksJsonString); // 解析JSON字符串
        setState(() {
          _books = jsonList.map((json) => Book.fromJson(json)).toList(); // 转换为Book对象列表
        });
      } else {
        setState(() {
          _books = []; // 如果没有数据，则为空列表
        });
      }
    } catch (e) {
      _showMessage('加载书籍失败: $e'); // 显示错误信息
      _books = []; // 确保列表为空以避免UI错误
    } finally {
      setState(() {
        _isLoading = false; // 停止加载
      });
    }
  }

  // 将书籍列表保存到本地文件 (现在通过SharedPreferences)
  Future<void> _saveBooks() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_books.map((book) => book.toJson()).toList()); // 将书籍列表转换为JSON字符串
      await prefs.setString('books_data', jsonString); // 保存到SharedPreferences
    } catch (e) {
      _showMessage('保存书籍失败: $e'); // 显示错误信息
    }
  }

  // 删除书籍
  Future<void> _deleteBook(Book book) async {
    try {
      // 删除本地内容文件
      final contentFile = File(book.contentFilePath);
      if (await contentFile.exists()) {
        await contentFile.delete();
      }

      // 从列表中移除书籍
      setState(() {
        _books.removeWhere((b) => b.id == book.id);
      });

      // 保存更新后的书籍列表
      await _saveBooks();

      _showMessage('书籍删除成功！');
    } catch (e) {
      _showMessage('删除书籍失败: $e');
      print('删除书籍失败: $e');
    }
  }

  // 显示删除确认对话框
  Future<void> _showDeleteConfirmDialog(Book book) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除《${book.title}》吗？\n\n删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBook(book);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  // 将文本分割成更大的块，减少解析次数
  List<String> _splitTextIntoChunks(String text, int chunkSize) {
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      chunks.add(text.substring(i, end));

    }
    return chunks;
  }

  // 清理LLM返回的JSON响应文本
  String _cleanJsonResponse(String responseText) {
    String cleaned = responseText.trim();
    // 移除开头的Markdown代码块标记
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    // 移除结尾的Markdown代码块标记
    if (cleaned.endsWith('```--- END ---')) {
      cleaned = cleaned.substring(0, cleaned.length - 14);
    } else if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }

    // 移除可能的额外标记
    cleaned = cleaned.replaceAll('--- END ---', '');
    cleaned = cleaned.replaceAll('END', '');

    // 再次清理首尾空白
    cleaned = cleaned.trim();

    return cleaned;
  }

  // 使用LLM解析文本块，提取层次关系和人物关系
  Future<Map<String, dynamic>> _analyzeTextChunk(String textChunk, int chunkIndex, int totalChunks) async {
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
              "character1": "Name of Character A (string)",
              "character2": "Name of Character B (string)",
              "relationship_type": "Type of relationship (e.g., 'friend', 'enemy', 'family', 'mentor-mentee', 'colleague', etc., summarize based on text content)",
              "description": "Brief description of this relationship (string)"
            }
            // ... more character relationships
          ]
        }
         Important: Return only pure JSON format, do not include any Markdown tags, code block tags, or other text. Do not use ```json or ``` tags。
      ''';
      print("向LLM发送聊天信息!");
      // 使用ModelChat的chat方法
      final jsonResponse = await _modelChat.chat(
        chatEngine: widget.chatEngine,
        text: prompt,
      );
      print("等待模型返回聊天结果!");
      print(jsonResponse);
      print("------------JSON 直接结果----------- ");
      String cleanedText = _cleanJsonResponse(jsonResponse); // 使用ModelChat的静态方法
      // 尝试解析JSON响应
      try {
        final Map<String, dynamic> result = jsonDecode(cleanedText);
        return result;
      } catch (e) {
        print('JSON解析失败: $e');
        // print('原始响应: $responseText');
        print('清理后文本: $cleanedText');
        return {
          "hierarchy": [], // 确保返回空列表而不是null
          "character_relationships": [] // 确保返回空列表而不是null
        };
      }
    } catch (e) {
      print('LLM解析失败: $e');
      return {
        "hierarchy": [], // 确保返回空列表而不是null
        "character_relationships": [] // 确保返回空列表而不是null
      };
    }
  }

  // 合并多个文本块的解析结果
  Map<String, dynamic> _mergeAnalysisResults(List<Map<String, dynamic>> results) {
    List<dynamic> mergedHierarchy = [];
    List<dynamic> mergedCharacterRelationships = [];

    for (var result in results) {
      if (result.containsKey('hierarchy') && result['hierarchy'] is List) {
        mergedHierarchy.addAll(result['hierarchy']);
      }
      if (result.containsKey('character_relationships') && result['character_relationships'] is List) {
        // 合并人物关系时，考虑到可能有重复的人物或关系，可以进行去重或更复杂的合并逻辑
        // 这里为了简化，直接添加所有关系，如果需要去重，需要更复杂的逻辑
        mergedCharacterRelationships.addAll(result['character_relationships']);
      }
    }
    return {
      "hierarchy": mergedHierarchy,
      "character_relationships": mergedCharacterRelationships
    };
  }

  // 显示解析进度对话框
  Future<void> _showAnalysisProgressDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('正在解析文档'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Upload finished,parsing content using gemma-3n ...'),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: _analysisProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 10),
              Text('解析进度: ${(_analysisProgress * 100).toInt()}%'),
            ],
          ),
        );
      },
    );
  }

  // 处理文件选择和上传
  Future<void> _pickFile() async {
    setState(() {
      _isUploading = true; // 设置上传状态
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'], // 允许PDF和TXT文件
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!); // 获取选中的文件
        String fileName = result.files.single.name; // 获取文件名
        String fileExtension = fileName.split('.').last.toLowerCase(); // 获取文件扩展名
        String bookContent = ''; // 书籍内容
        String bookTitle = fileName.replaceAll('.$fileExtension', ''); // 从文件名提取标题
        String bookDescription = 'description'; // 默认描述

        if (fileExtension == 'pdf') {
          // 处理PDF文件
          try {
            // 使用 read_pdf_text 包提取PDF文本
            String pdfText = await ReadPdfText.getPDFtext(file.path);
            if (pdfText.isNotEmpty) {
              bookContent = pdfText;
            } else {
              _showMessage('无法从PDF文件中提取文本内容。请确保PDF文件包含可选择的文本。');
              return;
            }

          } catch (pdfError) {
            print('PDF文件处理失败: $pdfError');
            _showMessage('PDF文件处理失败: $pdfError');
            return;
          }

          bookDescription = bookContent.length > 150
              ? '${bookContent.substring(0, 150)}...'
              : bookContent; // 截取前150字符作为描述

        } else if (fileExtension == 'txt') {
          // 处理TXT文件
          bookContent = await file.readAsString(); // 读取TXT文件内容
          bookDescription = bookContent.length > 150
              ? '${bookContent.substring(0, 150)}...'
              : bookContent; // 截取前150字符作为描述
        } else {
          _showMessage('不支持的文件类型。只支持 PDF 和 TXT。'); // 不支持的文件类型
          return;
        }

        // 将书籍内容保存为本地TXT文件
        final String contentFileName = '${bookTitle.replaceAll(' ', '_')}.txt';
        final File localContentFile = File('$_localBookContentsDirPath/$contentFileName');
        await localContentFile.writeAsString(bookContent); // 写入内容

        // 开始LLM解析
        setState(() {
          _isAnalyzing = true;
          _analysisProgress = 0.0;
        });

        // 显示解析进度对话框
        _showAnalysisProgressDialog();

        try {
          // 将文本分割成1000字符的块
          List<String> textChunks = _splitTextIntoChunks(bookContent, 1000);
          List<Map<String, dynamic>> analysisResults = [];
          // 逐个解析文本块
          for (int i = 0; i < textChunks.length; i++) {
            final result = await _analyzeTextChunk(textChunks[i], i, textChunks.length);
            print('-------------------------Analyzing uploaded file content\n $result');
            analysisResults.add(result);
            // 更新进度
            setState(() {
              _analysisProgress = (i + 1) / textChunks.length;
            });
          }

          // 合并解析结果
          final mergedResults = _mergeAnalysisResults(analysisResults);

          // 将合并后的层次结构和人物关系数据转换为JSON字符串
          final String finalMindMapData = jsonEncode(mergedResults['hierarchy']);
          final String finalRoleMapData = jsonEncode(mergedResults['character_relationships']);

          // 创建新的Book对象
          final newBook = Book(
            id: DateTime.now().millisecondsSinceEpoch.toString(), // 使用时间戳作为唯一ID
            title: bookTitle,
            author: 'author', // 默认作者
            progress: 0.0, // 新书进度为0
            description: bookDescription,
            coverImage: 'https://placehold.co/100x150/e0e0e0/333333?text=Book', // 占位符封面图
            contentFilePath: localContentFile.path, // 保存本地内容文件路径
            pageNum: textChunks.length, // 设置总页数（这里是文本块的数量）
            mindMapData: finalMindMapData, // 保存思维导图数据
            roleMapData: finalRoleMapData, // 保存人物关系图数据
          );

          setState(() {
            _books.add(newBook); // 添加新书到列表
            _isAnalyzing = false;
          });
          // 关闭进度对话框
          Navigator.of(context).pop();
          await _saveBooks(); // 保存更新后的书籍列表
          _showMessage('Book uploaded and AI analysis completed!'); // 显示成功信息
        } catch (e) {
          setState(() {
            _isAnalyzing = false;
          });
          // 关闭进度对话框
          Navigator.of(context).pop();
          _showMessage('AI analysis failed, but file saved: $e');
          print('AI analysis failed: $e');
        }
      } else {
        // 用户取消了文件选择
        _showMessage('File selection cancelled.');
      }
    } catch (e) {
      _showMessage('File processing or upload failed: $e'); // 显示错误信息
      print('File processing or upload failed: $e'); // 打印详细错误到控制台
    } finally {
      setState(() {
        _isUploading = false; // 停止上传状态
      });
    }
  }

  // 显示SnackBar消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // 使SnackBar浮动
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 圆角
        ),
        margin: const EdgeInsets.all(10), // 边距
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
                    ? const Center(child: CircularProgressIndicator(color: Colors.purple)) // 加载指示器
                    : _books.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book, size: 80, color: Colors.purple.withOpacity(0.7)),
                                const SizedBox(height: 16),
                                Text(
                                  '您还没有添加任何书籍。',
                                  style: TextStyle(fontSize: 18, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '点击下方按钮上传您的第一本书！',
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
                                  borderRadius: BorderRadius.circular(16), // 圆角卡片
                                ),
                                child: InkWell( // 使用InkWell包裹Card，使其可点击
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () async {
                                    // 导航到书籍详情界面
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
                                              // 书籍封面
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
                                              // 书籍详情
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
                                                    // 阅读进度条
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
                                                    // 简单描述
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
                                                    // 评分
                                                    Row(
                                                      children: [
                                                        Icon(Icons.star, color: Colors.amber[600], size: 16),
                                                        const SizedBox(width: 4),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // 删除按钮 - 位于右下角
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
      // 底部上传按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickFile, // 上传中禁用按钮
        label: Text(_isUploading ? 'Upload File' : '.pdf .txt'),
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
          borderRadius: BorderRadius.circular(30), // 圆角按钮
        ),
        elevation: 4,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // 居中浮动按钮
    );
  }
}

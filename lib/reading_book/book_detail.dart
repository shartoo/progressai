import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:progressai/reading_book/role_map.dart';

import 'book_chat.dart';
import 'book_list.dart';
import 'mind_map.dart'; // 导入 chatEngine 所需的类型

class BookDetailScreen extends StatefulWidget {
  final Book book; // 接收传入的书籍对象
  final InferenceChat chatEngine; // 新增：接收 chatEngine

  const BookDetailScreen({Key? key, required this.book, required this.chatEngine}) : super(key: key);

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  String _bookContent = ''; // 用于存储书籍的完整内容

  @override
  void initState() {
    super.initState();
    _loadBookContent(); // 页面初始化时加载书籍内容
  }

  // 加载书籍的完整内容
  Future<void> _loadBookContent() async {
    final content = await widget.book.readContent();
    setState(() {
      _bookContent = content;
    });
  }

  // 导航到书籍聊天界面
  void _navigateToBookChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookChatScreen(
          bookTitle: widget.book.title,
          contentFilePath: widget.book.contentFilePath,
          chatEngine: widget.chatEngine, // 传递 chatEngine
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 计算阅读进度文本
    // 假设总页数为 book.pageNum，如果为0则默认为1
    final int totalPages = widget.book.pageNum > 0 ? widget.book.pageNum : 1;
    final int currentPage = (widget.book.progress / 100 * totalPages).toInt();
    final String progressText = 'Progress: $currentPage/$totalPages';


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), // 返回按钮
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.transparent, // 透明背景
        elevation: 0, // 无阴影
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.black), // 书签图标
            onPressed: () {
              // TODO: Implement bookmark functionality
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true, // 使内容延伸到AppBar后面
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.lightBlueAccent], // 浅蓝色渐变背景
          ),
        ),
        child: SingleChildScrollView( // 允许内容滚动
          child: Padding(
            padding: const EdgeInsets.only(top: kToolbarHeight + 20.0, left: 16.0, right: 16.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 书籍封面 (现在可点击)
                InkWell( // 使用 InkWell 使其可点击并提供视觉反馈
                  onTap: _navigateToBookChat, // 点击时跳转到聊天界面
                  borderRadius: BorderRadius.circular(12), // 保持圆角
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.book.coverImage,
                        width: 180,
                        height: 270,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 180,
                            height: 270,
                            color: Colors.grey[300],
                            child: const Icon(Icons.book, size: 80, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 书籍标题
                Text(
                  widget.book.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // 作者
                Text(
                  'by ${widget.book.author}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                // 阅读进度条
                SizedBox(
                  width: 200, // 固定进度条宽度
                  child: LinearProgressIndicator(
                    value: widget.book.progress / 100,
                    backgroundColor: Colors.grey[300],
                    color: Colors.green, // 进度条颜色
                    borderRadius: BorderRadius.circular(5),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                // 阅读进度文本
                Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16), // 增加间距
                // 新增：Read 按钮
                ElevatedButton.icon(
                  onPressed: _navigateToBookChat, // 点击时跳转到聊天界面
                  icon: const Icon(Icons.menu_book, color: Colors.white),
                  label: const Text(
                    'Read Book',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange, // 按钮颜色
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // 圆角按钮
                    ),
                    elevation: 5,
                  ),
                ),
                const SizedBox(height: 30),

                // Mind Map Card
                _buildFeatureCard(
                  context,
                  title: 'Mind Map',
                  icon: Icons.psychology_alt,
                  color: Colors.lightGreen, // Green tone
                  onTap: () {
                    // Navigate to MindMapScreen, passing mindMapData
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MindMapScreen(
                          jsonMindMapData: widget.book.mindMapData, // Pass the stored mind map data
                          bookTitle: widget.book.title,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Role Map Card
                _buildFeatureCard(
                  context,
                  title: 'Role Map',
                  icon: Icons.people_alt,
                  color: Colors.orangeAccent, // Orange tone
                  onTap: () {
                    // Navigate to RoleMapScreen, passing roleMapData
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoleMapScreen(
                          jsonRoleMapData: widget.book.roleMapData, // Pass the stored role map data
                          bookTitle: widget.book.title,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build feature card (Mind Map and Role Map)
  Widget _buildFeatureCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85, // 85% of screen width
        height: 180, // Fixed height
        decoration: BoxDecoration(
          color: color.withOpacity(0.8), // Card background color
          borderRadius: BorderRadius.circular(20), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.white.withOpacity(0.9), // Icon color
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.95), // Title color
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Click to view detailed $title',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

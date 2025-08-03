import 'package:flutter/material.dart';
import 'package:progressai/reading_book/role_map.dart';
import 'book_list.dart';
import 'mind_map.dart'; // 导入思维导图界面

class BookDetailScreen extends StatefulWidget {
  final Book book; // 接收传入的书籍对象
  const BookDetailScreen({Key? key, required this.book}) : super(key: key);
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

  @override
  Widget build(BuildContext context) {
    // 计算阅读进度文本
    final int currentPage = (widget.book.progress / 100 * 384).toInt(); // 假设总页数为384
    final int bookPageNum = widget.book.pageNum;
    final String progressText = 'progress: $currentPage/$bookPageNum';

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
              // TODO: 实现书签功能
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
                // 书籍封面
                Container(
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
                const SizedBox(height: 30),

                // 思维导图缩略图卡片
                _buildFeatureCard(
                  context,
                  title: 'Mind Map',
                  icon: Icons.psychology_alt,
                  color: Colors.lightGreen, // 绿色调
                  onTap: () {
                    // 或者从缓存中读取已生成的JSON
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MindMapScreen(
                          jsonMindMapData: widget.book.mindMapData.isEmpty ? '' : widget.book.mindMapData, // 传递书籍内容或空字符串
                          bookTitle: widget.book.title,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 人物关系图谱缩略图卡片
                _buildFeatureCard(
                  context,
                  title: 'Role Map',
                  icon: Icons.people_alt,
                  color: Colors.orangeAccent, // 橙色调
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoleMapScreen(
                          jsonRoleMapData: widget.book.roleMapData.isEmpty ? '' : widget.book.roleMapData,
                          bookTitle: widget.book.title,
                        ),
                      ),
                    );
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('人物关系图谱功能待开发')),
                    // );
                  },
                ),
                const SizedBox(height: 30), // 底部留白
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建特性卡片（思维导图和人物关系图谱）
  Widget _buildFeatureCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85, // 宽度占屏幕的85%
        height: 180, // 固定高度
        decoration: BoxDecoration(
          color: color.withOpacity(0.8), // 卡片背景色
          borderRadius: BorderRadius.circular(20), // 圆角
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
              color: Colors.white.withOpacity(0.9), // 图标颜色
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.95), // 标题颜色
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '点击查看详细${title}',
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

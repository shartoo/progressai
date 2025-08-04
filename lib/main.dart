import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:progressai/reading_book/book_list.dart';
import 'package:progressai/weight_manage/weight_chat.dart';
import 'package:provider/provider.dart';
import 'weight_manage/weight_home.dart';
import 'model_chat.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // 将 ChangeNotifierProvider 直接包裹住 MaterialApp
    ChangeNotifierProvider(
      create: (context) => EditingStateProvider(),
      child: const MyAppRoot(), // 新的根Widget，包含 MaterialApp
    ),
  );
}

class EditingStateProvider extends ChangeNotifier {
  bool _isEditing = false;
  bool get isEditing => _isEditing;
  set isEditing(bool value) {
    if (_isEditing != value) {
      _isEditing = value;
      notifyListeners();
    }
  }
}

// 创建一个新的根Widget来包含 MaterialApp
class MyAppRoot extends StatelessWidget {
  const MyAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProgressAI',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const MainScreen(), // MainScreen 是应用程序的入口
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  late final ModelChat _modelChat;
  late InferenceChat _chatEngine;
  bool _isModelLoading = true;
  String _loadingStatus = "Loading Model...";
  double _downloadProgress = 0.0; // 用于显示下载进度

  @override
  void initState() {
    super.initState();
    _modelChat = ModelChat();
    _initializeGemmaChat();
  }

  Future<void> _initializeGemmaChat() async {
    try {
      final chat = await _modelChat.initializeGemmaChat(
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
            // 更新下载状态，并显示百分比
            _loadingStatus = "Downloading model file... ${(progress * 100).toStringAsFixed(0)}%";
          });
        },
      );
      // 模型加载成功，更新状态
      setState(() {
        _chatEngine = chat!;
        _isModelLoading = false;
        _loadingStatus = "Model load success!";
      });
      // 显示成功提示 SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load Model Success'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 模型加载失败，更新状态
      setState(() {
        _isModelLoading = false;
        _loadingStatus = "Load Model Failed: $e";
      });

      // 显示错误提示 SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loading model failed: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            // TODO: 实现侧边栏菜单
            Scaffold.of(context).openDrawer();
          },
        ),
        title: const Text(
          'ProgressAI',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black87),
            onPressed: () {
              // TODO: 实现用户资料页面
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple[100],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.purple),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'ProgressAI',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Goal management assistant based on Gemma-3n',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Weight Manage'),
              onTap: () {
                Navigator.pop(context);
                if (!_isModelLoading) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeightHome(chatEngine: _chatEngine),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading Gemma-3n model...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Reading Books'),
              onTap: () {
                Navigator.pop(context);
                if (!_isModelLoading) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookListScreen(chatEngine: _chatEngine),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading Gemma-3n model...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现设置页面
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现帮助页面
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模型加载状态显示
            if (_isModelLoading)
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _loadingStatus,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            // Weight Management Card
            _buildFeatureCard(
              context: context,
              title: 'Weight Management',
              icon: Icons.fitness_center,
              items: [
                'Nutritionist',
                'Certified Personal Trainer',
                'Psychologist',
                'Physician',
              ],
              onTap: () {
                if (!_isModelLoading) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WeightChatPage(chatEngine: _chatEngine),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading gemma-3n model,waiting..'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            // Reading Books Card
            _buildFeatureCard(
              context: context,
              title: 'Reading Books',
              icon: Icons.book,
              items: [
                'Summarization',
                'Precise Association',
                'Questioning & Reflection',
                'Personalized Reading Path',
              ],
              onTap: () {
                if (!_isModelLoading) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookListScreen(chatEngine: _chatEngine),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loading Gemma-3n model...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            // More Target Card
            _buildFeatureCard(
              context: context,
              title: 'More Target',
              icon: Icons.add_circle_outline,
              items: [
                'More Goal manage is under developing',
                'Learning Singing..',
                'Learning Dancing...',
                'Learning Draw..',
              ],
              onTap: () {
                // TODO: 实现更多目标页面
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('More Task Management is under developing！'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<String> items,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}



import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'mind_map_node.dart'; // 确保这个导入存在且正确

class RoleMapScreen extends StatefulWidget {
  // 接收一个JSON格式的思维导图数据字符串
  final String jsonRoleMapData;
  final String bookTitle; // 用于AppBar显示，如果jsonMindMapData为空，则显示默认标题
  const RoleMapScreen({
    Key? key,
    required this.jsonRoleMapData,
    this.bookTitle = 'Book Title', // 提供一个默认的书籍标题
  }) : super(key: key);

  @override
  State<RoleMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<RoleMapScreen> {
  Graph graph = Graph(); // GraphView的图对象
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  BuchheimWalkerAlgorithm algorithm = BuchheimWalkerAlgorithm(BuchheimWalkerConfiguration(), TreeEdgeRenderer(BuchheimWalkerConfiguration())); // 初始化时需要传入一个配置

  bool _isLoading = true; // 加载状态
  MindMapNode? _rootNode; // 思维导图的根节点

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = (120) // 增加兄弟节点之间的间距
      ..levelSeparation = (180) // 增加不同层级之间的间距
      ..subtreeSeparation = (180) // 增加子树之间的间距
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM); // 布局方向

    // 重新初始化 algorithm，确保它使用配置好的 builder
    algorithm = BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder));

    _loadAndBuildMindMap(); // 初始化时加载并构建思维导图
  }

  // 加载并构建思维导图数据
  Future<void> _loadAndBuildMindMap() async {
    setState(() {
      _isLoading = true; // 开始加载
    });

    try {
      String dataToParse = widget.jsonRoleMapData;
      // 如果传入的JSON字符串为空，则使用默认数据
      if (dataToParse.isEmpty) {
        print("从数据中传入的json是空白的，载入默认数据!");
        dataToParse = _defaultMindMapJson();
      }
      print("从widget中获得的json数据是\n$dataToParse");
      // 解析JSON字符串为Map
      final Map<String, dynamic> data = jsonDecode(dataToParse);
      // 从Map构建MindMapNode对象
      _rootNode = MindMapNode.fromJson(data);
      // 从MindMapNode对象构建GraphView所需的Graph对象
      _buildGraphFromMindMapNode(_rootNode!);
    } catch (e) {
      print('加载或解析思维导图数据失败: $e');
      _rootNode = null; // 确保在出错时根节点为空
      // 延迟显示错误消息，避免在initState中调用
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMessage('加载或解析思维导图数据失败: $e');
        }
      });
    } finally {
      setState(() {
        _isLoading = false; // 停止加载
      });
    }
  }

  // 提供一个默认的思维导图JSON数据
  String _defaultMindMapJson() {
    return '''
    {
      "id": "default_root",
      "title": "默认思维导图 - 欢迎使用",
      "description": "这是一个示例思维导图，展示了如何组织信息。",
      "children": [
        {
          "id": "topic1",
          "title": "核心概念",
          "description": "应用程序的主要功能",
          "children": [
            {"id": "subtopic1_1", "title": "书籍上传", "description": "支持PDF和TXT格式"},
            {"id": "subtopic1_2", "title": "思维导图", "description": "可视化书籍核心信息"}
          ]
        },
        {
          "id": "topic2",
          "title": "技术栈",
          "description": "构建此应用所使用的技术",
          "children": [
            {"id": "subtopic2_1", "title": "Flutter Dart", "description": "跨平台UI框架"},
            {"id": "subtopic2_2", "title": "GraphView", "description": "用于图谱和树形结构展示"},
            {"id": "subtopic2_3", "title": "文件读写", "description": "本地存储和PDF解析"}
          ]
        },
        {
          "id": "topic3",
          "title": "未来展望",
          "description": "可能的改进和新功能",
          "children": [
            {"id": "subtopic3_1", "title": "LLM集成", "description": "自动提取更精准的思维导图"},
            {"id": "subtopic3_2", "title": "用户交互", "description": "编辑节点、自定义布局"}
          ]
        }
      ]
    }
    ''';
  }

  // 从MindMapNode数据结构构建GraphView所需的Graph对象
  void _buildGraphFromMindMapNode(MindMapNode node) {
    graph = Graph(); // 清空旧的图
    final Map<String, Node> nodeMap = {}; // 用于存储已创建的GraphView Node，避免重复创建

    // 递归函数，用于添加节点和边
    void addNodeAndChildren(MindMapNode currentNode, Node? parentGraphNode) {
      // 创建GraphView的Node
      final graphNode = Node.Id(currentNode.id);
      nodeMap[currentNode.id] = graphNode;
      graph.addNode(graphNode);

      // 如果有父节点，添加边
      if (parentGraphNode != null) {
        graph.addEdge(parentGraphNode, graphNode);
      }

      // 递归处理子节点
      for (var child in currentNode.children) {
        addNodeAndChildren(child, graphNode);
      }
    }

    addNodeAndChildren(node, null); // 从根节点开始构建

    // 打印调试信息
    print('思维导图构建完成，节点数量: ${graph.nodes.length}');
    print('思维导图边数量: ${graph.edges.length}');
  }

  // 构建自定义节点Widget
  Widget _buildNodeWidget(BuildContext context, Node node) {
    final MindMapNode? mindMapNode = _findMindMapNodeById(_rootNode, node.key!.value as String);

    if (mindMapNode == null) {
      return Container(); // 如果找不到对应数据，返回空容器
    }

    // 根据节点层级或类型进行美化
    Color backgroundColor;
    Color textColor;
    double padding;
    double fontSize;
    BorderRadius borderRadius;
    List<BoxShadow> boxShadow;

    // 简单的层级颜色区分和美化
    if (mindMapNode.id == _rootNode!.id) {
      // 根节点
      backgroundColor = Colors.deepPurple;
      textColor = Colors.white;
      padding = 16.0;
      fontSize = 18.0;
      borderRadius = BorderRadius.circular(25);
      boxShadow = [BoxShadow(color: Colors.deepPurple.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)];
    } else if (mindMapNode.children.isNotEmpty) {
      // 有子节点的中间节点
      backgroundColor = Colors.blueAccent;
      textColor = Colors.white;
      padding = 12.0;
      fontSize = 16.0;
      borderRadius = BorderRadius.circular(20);
      boxShadow = [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)];
    } else {
      // 叶子节点
      backgroundColor = Colors.white;
      textColor = Colors.black87;
      padding = 10.0;
      fontSize = 14.0;
      borderRadius = BorderRadius.circular(15);
      boxShadow = [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 0.5)];
    }

    return InkWell(
      onTap: () {
        // 点击节点可以显示更多信息或导航
        _showMessage('点击了节点: ${mindMapNode.title}\n描述: ${mindMapNode.description ?? '无'}');
      },
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mindMapNode.title,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (mindMapNode.description != null && mindMapNode.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  mindMapNode.description!,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: fontSize * 0.75,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 辅助函数：根据ID查找MindMapNode
  MindMapNode? _findMindMapNodeById(MindMapNode? current, String id) {
    if (current == null) return null;
    if (current.id == id) return current;

    for (var child in current.children) {
      final found = _findMindMapNodeById(child, id);
      if (found != null) return found;
    }
    return null;
  }

  // 显示SnackBar消息
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
    // 根据是否有根节点或图谱是否为空来决定AppBar标题
    final String appBarTitle = _rootNode != null && _rootNode!.title.isNotEmpty
        ? '${_rootNode!.title} - Role Map'
        : '${widget.bookTitle} - Role Map';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text(
              'loading role map...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      )
          : _rootNode == null || graph.nodes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_alt, size: 80, color: Colors.grey.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              '未能生成思维导图。',
              style: TextStyle(fontSize: 18, color: Colors.grey.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查传入的数据或书籍内容。',
              style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.7)),
            ),
          ],
        ),
      )
          : InteractiveViewer( // 允许缩放和平移图谱
        constrained: false, // 允许内容超出视口
        boundaryMargin: const EdgeInsets.all(50), // 增加边界边距
        minScale: 0.2, // 最小缩放比例
        maxScale: 4.0, // 最大缩放比例
        scaleEnabled: true, // 启用缩放
        panEnabled: true, // 启用平移
        child: Container(
          width: MediaQuery.of(context).size.width * 2, // 确保有足够的空间
          height: MediaQuery.of(context).size.height * 2,
          child: GraphView(
            graph: graph,
            algorithm: algorithm,
            builder: (Node node) {
              // 返回自定义的节点Widget
              return _buildNodeWidget(context, node);
            },
            paint: Paint()
              ..color = Colors.grey[700]! // 边的颜色
              ..strokeWidth = 1.5 // 边的粗细
              ..style = PaintingStyle.stroke,
          ),
        ),
      ),
    );
  }
}

// lib/models/mind_map_node.dart
class MindMapNode {
  final String id;
  final String title;
  final String? description; // 节点描述
  final List<MindMapNode> children; // 子节点

  MindMapNode({
    required this.id,
    required this.title,
    this.description,
    this.children = const [],
  });

  // 从JSON创建MindMapNode对象
  // 这个工厂构造函数负责将Map<String, dynamic>转换为MindMapNode实例
  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      // 递归地将子节点列表中的每个JSON对象转换为MindMapNode对象
      children: (json['children'] as List<dynamic>?)
          ?.map((childJson) => MindMapNode.fromJson(childJson))
          .toList() ??
          [], // 如果children为null，则默认为空列表
    );
  }

  // 将MindMapNode对象转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}

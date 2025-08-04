
class MindMapNode {
  final String id;
  final String title;
  final String? summary; // Node description
  final List<MindMapNode> children; // Child nodes

  MindMapNode({
    required this.id,
    required this.title,
    this.summary,
    this.children = const [],
  });

  // Factory constructor to create MindMapNode object from JSON
  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    return MindMapNode(
      id: json['id'] as String? ?? 'unknown_id', // Provide default for id
      title: json['title'] as String? ?? 'Untitled Node', // Provide default for title
      summary: json['summary'] as String?, // description can be null
      // Recursively map child JSON objects to MindMapNode objects
      children: (json['children'] as List<dynamic>?)
          ?.map((childJson) => MindMapNode.fromJson(childJson as Map<String, dynamic>))
          .toList() ??
          [], // Default to empty list if children is null
    );
  }

  // Convert MindMapNode object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}

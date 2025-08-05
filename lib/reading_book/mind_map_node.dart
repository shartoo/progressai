// lib/models/mind_map_node.dart
class MindMapNode {
  final String id;
  final String title;
  final String? summary; // Node summary
  final List<MindMapNode> children; // Child nodes

  MindMapNode({
    required this.id,
    required this.title,
    this.summary,
    this.children = const [],
  });

  // Factory constructor to create MindMapNode object from JSON
  factory MindMapNode.fromJson(Map<String, dynamic> json) {
    print("Call MindMapNode.fromJson for JSON: $json"); // Debug print
    return MindMapNode(
      id: json['id'] as String? ?? 'unknown_id', // Provide default for id
      title: json['title'] as String? ?? 'Untitled Node', // Provide default for title
      summary: json['summary'] as String?, // summary can be null
      // Recursively map child JSON objects to MindMapNode objects with robustness
      children: (json['children'] as List<dynamic>?)
          ?.map((childJson) {
        if (childJson is Map<String, dynamic>) {
          try {
            return MindMapNode.fromJson(childJson);
          } catch (e) {
            print('Warning: Error parsing nested child node: $e, data: $childJson');
            return null; // Return null for malformed children
          }
        } else {
          print('Warning: Skipping non-map child JSON: $childJson');
          return null; // Return null for non-map children
        }
      })
          .whereType<MindMapNode>() // Filter out any nulls resulting from parsing errors
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

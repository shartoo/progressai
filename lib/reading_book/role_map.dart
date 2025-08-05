import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class RoleMapScreen extends StatefulWidget {
  final String jsonRoleMapData; // JSON string containing nodes and edges
  final String bookTitle;

  const RoleMapScreen({
    Key? key,
    required this.jsonRoleMapData,
    this.bookTitle = 'Book Title',
  }) : super(key: key);

  @override
  State<RoleMapScreen> createState() => _RoleMapScreenState();
}

class _RoleMapScreenState extends State<RoleMapScreen> {
  Graph graph = Graph();
  FruchtermanReingoldAlgorithm algorithm = FruchtermanReingoldAlgorithm();

  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    // Configure the algorithm for better node dispersion and layout
    algorithm.repulsionPercentage = 60; // Increased repulsion to spread nodes further
    algorithm.attractionPercentage = 20; // Adjusted attraction
    algorithm.iterations = 100; // Increased iterations for a more stable layout

    _loadAndBuildRoleMap(); // Load and build the role map
  }

  // Load and build the role map data
  Future<void> _loadAndBuildRoleMap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String dataToParse = widget.jsonRoleMapData;
      if (dataToParse.isEmpty) {
        print("Incoming JSON data for role map is empty, loading default data!");
        dataToParse = _defaultRoleMapJson();
      }
      print("JSON data obtained for role map:\n$dataToParse");

      final Map<String, dynamic> data = jsonDecode(dataToParse);

      _buildGraphFromRoleMapData(data);
    } catch (e) {
      print('Failed to load or parse role map data: $e');
      // Delay displaying error message to avoid calling in initState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMessage('Failed to load or parse role map data: $e');
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Provides default character relationship JSON data for "The Running for Governor"
  String _defaultRoleMapJson() {
    return '''
    {
      "nodes": [
        {"id": "john_smith", "label": "John Smith"},
        {"id": "campaign_team", "label": "Campaign Team"},
        {"id": "public", "label": "Public"},
        {"id": "opponents", "label": "Opponents"},
        {"id": "family", "label": "Family"},
        {"id": "media", "label": "Media"},
        {"id": "local_communities", "label": "Local Communities"}
      ],
      "edges": [
        {"source": "john_smith", "target": "campaign_team", "label": "Leads"},
        {"source": "john_smith", "target": "public", "label": "Seeks Support From"},
        {"source": "john_smith", "target": "opponents", "label": "Contends With"},
        {"source": "john_smith", "target": "family", "label": "Affected By"},
        {"source": "john_smith", "target": "media", "label": "Under Scrutiny From"},
        {"source": "john_smith", "target": "local_communities", "label": "Supported By"},
        {"source": "campaign_team", "target": "john_smith", "label": "Supports"},
        {"source": "public", "target": "john_smith", "label": "Reacts To"},
        {"source": "opponents", "target": "john_smith", "label": "Debates"},
        {"source": "media", "target": "john_smith", "label": "Reports On"},
        {"source": "family", "target": "john_smith", "label": "Supports"}
      ]
    }
    ''';
  }

  // Build GraphView's Graph object from role map data
  void _buildGraphFromRoleMapData(Map<String, dynamic> data) {
    graph = Graph(); // Clear existing graph
    final Map<String, Node> nodeMap = {}; // To store created GraphView Nodes

    // Add nodes
    if (data.containsKey('nodes') && data['nodes'] is List) {
      for (var nodeJson in data['nodes']) {
        final nodeId = nodeJson['id'] as String;
        final nodeLabel = nodeJson['label'] as String;
        final graphNode = Node.Id(nodeId);
        nodeMap[nodeId] = graphNode;
        graph.addNode(graphNode);
      }
    }

    // Add edges
    if (data.containsKey('edges') && data['edges'] is List) {
      for (var edgeJson in data['edges']) {
        final sourceId = edgeJson['source'] as String;
        final targetId = edgeJson['target'] as String;
        final edgeLabel = edgeJson['label'] as String?;

        final sourceNode = nodeMap[sourceId];
        final targetNode = nodeMap[targetId];

        if (sourceNode != null && targetNode != null) {
          graph.addEdge(
            sourceNode,
            targetNode,
            paint: Paint()
              ..color = Colors.grey[700]!
              ..strokeWidth = 1.5
              ..style = PaintingStyle.stroke,
            // You can add a text label to the edge if needed, but it's not directly supported by GraphView's default edge rendering.
            // For text labels on edges, you'd need a custom edge painter or overlay.
          );
        }
      }
    }

    print('Role map built, number of nodes: ${graph.nodes.length}');
    print('Number of edges in role map: ${graph.edges.length}');
  }

  // Build custom node Widget for characters
  Widget _buildNodeWidget(BuildContext context, Node node) {
    // Get the label from the node's ID (which is the character ID)
    final String characterId = node.key!.value as String;
    // Find the original label from the default data or a passed map
    String characterLabel = characterId; // Default to ID if label not found
    final Map<String, dynamic> defaultData = jsonDecode(_defaultRoleMapJson());
    if (defaultData.containsKey('nodes') && defaultData['nodes'] is List) {
      for (var n in defaultData['nodes']) {
        if (n['id'] == characterId) {
          characterLabel = n['label'] as String;
          break;
        }
      }
    }

    // Basic styling for character nodes
    return InkWell(
      onTap: () {
        _showMessage('Clicked character: $characterLabel');
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal[100], // Light teal for character nodes
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 5, spreadRadius: 1),
          ],
          border: Border.all(color: Colors.teal[300]!, width: 1),
        ),
        child: Text(
          characterLabel,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Display SnackBar message
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookTitle} - Role Map'),
        centerTitle: true,
        backgroundColor: Colors.teal,
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
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Loading role map data...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      )
          : graph.nodes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt, size: 80, color: Colors.grey.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              'Failed to generate role map.',
              style: TextStyle(fontSize: 18, color: Colors.grey.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check the input data or book content.',
              style: TextStyle(fontSize: 16, color: Colors.grey.withOpacity(0.7)),
            ),
          ],
        ),
      )
          : InteractiveViewer( // Allows zooming and panning the graph
        constrained: false, // Allows content to exceed viewport
        boundaryMargin: const EdgeInsets.all(50), // Increase boundary margin
        minScale: 0.1, // Minimum zoom scale
        maxScale: 5.0, // Increased max zoom scale
        // initialScale: 0.7, // Added: Explicitly set initial scale for better visibility
        scaleEnabled: true, // Enable zooming
        panEnabled: true, // Enable panning
        child: GraphView(
          graph: graph,
          algorithm: algorithm,
          builder: (Node node) {
            // Return custom node Widget
            return _buildNodeWidget(context, node);
          },
          paint: Paint()
            ..color = Colors.grey[700]! // Edge color
            ..strokeWidth = 1.5 // Edge thickness
            ..style = PaintingStyle.stroke,
        ),
      ),
    );
  }
}

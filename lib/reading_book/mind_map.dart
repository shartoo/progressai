import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import 'mind_map_node.dart'; // Ensure this import exists and is correct

class MindMapScreen extends StatefulWidget {
  // Receives a JSON formatted string of mind map data
  final String jsonMindMapData;
  final String bookTitle; // Used for AppBar display, if jsonMindMapData is empty, default title is displayed

  const MindMapScreen({
    Key? key,
    required this.jsonMindMapData,
    this.bookTitle = 'Book Title', // Provide a default book title
  }) : super(key: key);

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  Graph graph = Graph(); // GraphView's graph object
  BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  BuchheimWalkerAlgorithm algorithm = BuchheimWalkerAlgorithm(BuchheimWalkerConfiguration(), TreeEdgeRenderer(BuchheimWalkerConfiguration())); // Initialize with a configuration

  bool _isLoading = true; // Loading status
  MindMapNode? _rootNode; // Mind map's root node

  @override
  void initState() {
    super.initState();
    builder
      ..siblingSeparation = (90) // Increase spacing between sibling nodes
      ..levelSeparation = (110) // Increase spacing between different levels
      ..subtreeSeparation = (110) // Increase spacing between subtrees
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_LEFT_RIGHT); // Layout direction

    // Reinitialize algorithm to ensure it uses the configured builder
    algorithm = BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder));

    _loadAndBuildMindMap(); // Load and build mind map on initialization
  }

  // Load and build mind map data
  Future<void> _loadAndBuildMindMap() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      String dataToParse = widget.jsonMindMapData;
      // If the incoming JSON string is empty, use default data
      if (dataToParse.isEmpty) {
        print("Incoming JSON data is empty, loading default data!");
        dataToParse = _defaultMindMapJson();
      }
      print("JSON data obtained from widget:\n$dataToParse");

      final dynamic decodedData = jsonDecode(dataToParse);

      // The MindMapNode expects a single root, but LLM might return a list of top-level nodes.
      // We need to create a virtual root if the decoded data is a list.
      if (decodedData is List) {
        // Robustly parse top-level children
        List<MindMapNode> topLevelChildren = [];
        for (var item in decodedData) {
          if (item is Map<String, dynamic>) {
            try {
              topLevelChildren.add(MindMapNode.fromJson(item));
            } catch (e) {
              print('Warning: Failed to parse a top-level node in list: $e, data: $item');
              // Continue processing other items, but log the error
            }
          } else {
            print('Warning: Skipping non-map item in top-level list: $item');
          }
        }

        _rootNode = MindMapNode(
          id: 'virtual_root_${DateTime.now().millisecondsSinceEpoch}',
          title: widget.bookTitle, // Use book title as virtual root title
          summary: '', // Use summary field
          children: topLevelChildren,
        );
      } else if (decodedData is Map<String, dynamic>) {
        // If the decoded data is already a single root node (Map)
        _rootNode = MindMapNode.fromJson(decodedData);
      } else {
        throw Exception('Invalid JSON data format for mind map. Expected List or Map, got ${decodedData.runtimeType}');
      }

      // Build GraphView's Graph object from MindMapNode object
      if (_rootNode != null) {
        _buildGraphFromMindMapNode(_rootNode!);
      } else {
        throw Exception('Root node could not be created from JSON data.');
      }

    } catch (e) {
      print('Failed to load or parse mind map data: $e');
      _rootNode = null; // Ensure root node is null on error
      // Delay displaying error message to avoid calling in initState
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMessage('Failed to load or parse mind map data: $e');
        }
      });
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  // Provide a default mind map JSON data
  String _defaultMindMapJson() {
    // This default JSON now directly represents the "hierarchy" part (a list of top-level nodes)
    return '''
    [
      {
        "id": "book_root",
        "title": "The Running for Governor",
        "summary": "A story about a political campaign and its challenges.",
        "children": [
          {
            "id": "chapter_1_introduction",
            "title": "Chapter 1: The Announcement",
            "summary": "Introduction of the protagonist, John Smith, and his decision to run for governor.",
            "children": [
              {"id": "john_smith_profile", "title": "John Smith", "summary": "A seasoned politician with a strong vision."},
              {"id": "initial_reactions", "title": "Public Reaction", "summary": "Mixed reactions to his unexpected candidacy."}
            ]
          },
          {
            "id": "chapter_2_campaign_kickoff",
            "title": "Chapter 2: Campaign Kick-off",
            "summary": "The initial phase of the campaign, setting up the team and strategy.",
            "children": [
              {"id": "campaign_team", "title": "Building the Team", "summary": "Recruiting key advisors and volunteers."},
              {"id": "strategy_development", "title": "Crafting the Message", "summary": "Focusing on education and economic growth."}
            ]
          },
          {
            "id": "chapter_3_early_challenges",
            "title": "Chapter 3: Early Challenges",
            "summary": "Facing initial hurdles, including funding and media scrutiny.",
            "children": [
              {"id": "fundraising_struggles", "title": "Funding Issues", "summary": "Difficulty in securing sufficient campaign funds."},
              {"id": "media_scrutiny", "title": "Media Scrutiny", "summary": "Past controversies resurface."}
            ]
          },
          {
            "id": "chapter_4_public_debates",
            "title": "Chapter 4: Public Debates",
            "summary": "John Smith participates in crucial debates against his opponents.",
            "children": [
              {"id": "opponent_analysis", "title": "Analyzing Opponents", "summary": "Understanding their strengths and weaknesses."},
              {"id": "debate_performance", "title": "Debate Performance", "summary": "John's strong showing in key debates."}
            ]
          },
          {
            "id": "chapter_5_personal_sacrifices",
            "title": "Chapter 5: Personal Sacrifices",
            "summary": "The toll the campaign takes on John's personal life and family.",
            "children": [
              {"id": "family_strain", "title": "Family Strain", "summary": "Challenges in balancing campaign and family life."},
              {"id": "personal_reflection", "title": "Self-Reflection", "summary": "Questioning the true cost of power."}
            ]
          },
          {
            "id": "chapter_6_final_stretch",
            "title": "Chapter 6: The Final Stretch",
            "summary": "The intense last weeks leading up to election day.",
            "children": [
              {"id": "grassroots_efforts", "title": "Grassroots Mobilization", "summary": "Rallying support from local communities."},
              {"id": "last_minute_attacks", "title": "Negative Campaigning", "summary": "Dealing with smear campaigns from rivals."}
            ]
          },
          {
            "id": "chapter_7_election_day",
            "title": "Chapter 7: Election Day",
            "summary": "The climactic day of voting and awaiting the results.",
            "children": [
              {"id": "voter_turnout", "title": "Voter Turnout", "summary": "High or low participation impacting the outcome."},
              {"id": "results_waiting", "title": "Anxious Waiting", "summary": "The tension as votes are counted."}
            ]
          },
          {
            "id": "chapter_8_the_outcome",
            "title": "Chapter 8: The Outcome",
            "summary": "The announcement of the election results and its aftermath.",
            "children": [
              {"id": "victory_defeat", "title": "Victory or Defeat", "summary": "The ultimate fate of John Smith's campaign."},
              {"id": "future_implications", "title": "Future Implications", "summary": "What the results mean for his career and the state."}
            ]
          }
        ]
      }
    ]
    ''';
  }

  // Build GraphView's Graph object from MindMapNode data structure
  void _buildGraphFromMindMapNode(MindMapNode node) {
    graph = Graph(); // Clear existing graph
    final Map<String, Node> nodeMap = {}; // Used to store created GraphView Nodes to avoid duplicates

    // Recursive function to add nodes and edges
    void addNodeAndChildren(MindMapNode currentNode, Node? parentGraphNode) {
      // Create GraphView's Node
      final graphNode = Node.Id(currentNode.id);
      nodeMap[currentNode.id] = graphNode;
      graph.addNode(graphNode);

      // If there's a parent node, add an edge
      if (parentGraphNode != null) {
        graph.addEdge(parentGraphNode, graphNode);
      }

      // Recursively process child nodes
      for (var child in currentNode.children) {
        addNodeAndChildren(child, graphNode);
      }
    }

    addNodeAndChildren(node, null); // Start building from the root node

    // Print debug information
    print('Mind map built, number of nodes: ${graph.nodes.length}');
    print('Number of edges in mind map: ${graph.edges.length}');
  }

  // Build custom node Widget
  Widget _buildNodeWidget(BuildContext context, Node node) {
    final MindMapNode? mindMapNode = _findMindMapNodeById(_rootNode, node.key!.value as String);

    if (mindMapNode == null) {
      return Container(); // Return empty container if no corresponding data is found
    }

    // Beautify based on node level or type
    Color backgroundColor;
    Color textColor;
    double padding;
    double fontSize;
    BorderRadius borderRadius;
    List<BoxShadow> boxShadow;

    // Simple level-based color differentiation and beautification
    if (mindMapNode.id == _rootNode!.id) {
      // Root node
      backgroundColor = Colors.deepPurple;
      textColor = Colors.white;
      padding = 16.0;
      fontSize = 18.0; // Increased font size
      borderRadius = BorderRadius.circular(25);
      boxShadow = [BoxShadow(color: Colors.deepPurple.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)];
    } else if (mindMapNode.children.isNotEmpty) {
      // Intermediate node with children
      backgroundColor = Colors.blueAccent;
      textColor = Colors.white;
      padding = 12.0;
      fontSize = 16.0; // Increased font size
      borderRadius = BorderRadius.circular(20);
      boxShadow = [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)];
    } else {
      // Leaf node
      backgroundColor = Colors.white;
      textColor = Colors.black87;
      padding = 10.0;
      fontSize = 14.0; // Increased font size
      borderRadius = BorderRadius.circular(15);
      boxShadow = [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, spreadRadius: 0.5)];
    }

    return InkWell(
      onTap: () {
        // Tapping on a node can display more information or navigate
        _showMessage('Clicked node: ${mindMapNode.title}\nSummary: ${mindMapNode.summary ?? 'None'}');
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
            if (mindMapNode.summary != null && mindMapNode.summary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  mindMapNode.summary!,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: fontSize * 0.75,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4, // Increased maxLines
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper function: Find MindMapNode by ID
  MindMapNode? _findMindMapNodeById(MindMapNode? current, String id) {
    if (current == null) return null;
    if (current.id == id) return current;

    for (var child in current.children) {
      final found = _findMindMapNodeById(child, id);
      if (found != null) return found;
    }
    return null;
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
    // Determine AppBar title based on whether root node exists or graph is empty
    final String appBarTitle = _rootNode != null && _rootNode!.title.isNotEmpty
        ? '${_rootNode!.title} - Mind Map'
        : '${widget.bookTitle} - Mind Map';

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
              'Loading mind map data...',
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
              'Failed to generate mind map.',
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
        minScale: 0.2, // Minimum zoom scale
        maxScale: 4.0, // Maximum zoom scale
        scaleEnabled: true, // Enable zooming
        panEnabled: true, // Enable panning
        // Removed the wrapping Container with fixed width/height
        child: GraphView( // Directly use GraphView as child
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

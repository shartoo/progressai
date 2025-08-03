import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:progressai/weight_manage/tabbars/doctor_screen.dart';
import 'package:progressai/weight_manage/tabbars/fitness_screen.dart';
import 'package:progressai/weight_manage/tabbars/nutritionist_screen.dart';
import 'package:progressai/weight_manage/tabbars/psychology_screen.dart';
import 'package:progressai/weight_manage/tabbars/user_profile_screen.dart';
import 'package:progressai/weight_manage/user_data.dart';
import 'package:progressai/weight_manage/weight_home.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart'; // For file picking
import 'dart:io'; // For File operations
import 'package:path_provider/path_provider.dart'; // For getting app document directory

class WeightChatPage extends StatefulWidget {
  final InferenceChat chatEngine; // chatEngine is now a required parameter
  const WeightChatPage({
    super.key,
    required this.chatEngine, // Make chatEngine required
  });

  @override
  State<WeightChatPage> createState() => _WeightChatPageState();
}

class _WeightChatPageState extends State<WeightChatPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = []; // Store chat messages

  // Notification counters for each category
  Map<String, int> _notificationCounts = {
    'Basic': 0,
    'Doctor': 0,
    'Nutritionist': 0,
    'Fitness': 0,
    'Psychology': 0,
  };

  File? _attachedImage; // To store the attached image file
  bool _isUploadingImage = false; // To track image upload status
  double _uploadProgress = 0.0; // To track image upload progress

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 tabs for Basic, Doctor, Nutritionist, Fitness, Psychology
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // Placeholder method for LLM analysis and data update
  // This method will be responsible for:
  // 1. Sending the user's message to the LLM.
  // 2. Receiving the LLM's response.
  // 3. Analyzing the LLM's response to identify data updates for UserProfile, Doctor, Nutritionist, Fitness, Psychology.
  // 4. Updating the respective data models in AppModelsManager.
  // 5. Updating notification counts based on the number of updated items in each category.
  // 6. Saving the updated data to local JSON.
  Future<void> _analyzeAndCategorizeLLMResponse(String message, {String? imagePath}) async {
    setState(() {
      _messages.add({
        'role': 'user',
        'text': message,
        'time': DateFormat('hh:mma').format(DateTime.now()),
        if (imagePath != null) 'imagePath': imagePath,
      });
    });

    // --- Accessing chatEngine via widget.chatEngine ---
    // Here's how you would use widget.chatEngine to send a message to your LLM
    String llmRawResponse = "";
    // In a real scenario, you would parse llmRawResponse to extract structured data
    // and identify which categories (UserProfile, Doctor, etc.) need updating.

    String llmResponse = "Thank you for your message! I'm processing the information.";
    int updatedCountBasic = 1;
    int updatedCountDoctor = 2;
    int updatedCountNutritionist = 3;
    int updatedCountFitness = 2;
    int updatedCountPsychology = 3;

    // For demonstration, let's simulate some updates and notifications
    // based on a simple keyword check and the simulated LLM response.
    if (message.toLowerCase().contains('weight')) {
      // Simulate updating UserProfile (e.g., currentWeightKg)
      // AppModelsManager.userProfile?.currentWeightKg = newWeight;
      updatedCountBasic = 1; // Simulate 1 update
      llmResponse += "\nI've noted your weight update.";
    }
    if (message.toLowerCase().contains('blood pressure')) {
      // Simulate updating Doctor data
      // AppModelsManager.doctor?.dailyDataHistory.add(newDoctorDailyData);
      updatedCountDoctor = 2; // Simulate 2 updates
      llmResponse += "\nYour blood pressure data has been recorded.";
    }
    if (message.toLowerCase().contains('food')) {
      // Simulate updating Nutritionist data
      // AppModelsManager.nutritionist?.dailyDataHistory.add(newNutritionistDailyData);
      updatedCountNutritionist = 3; // Simulate 3 updates
      llmResponse += "\nYour food intake details are being analyzed.";
    }
    if (message.toLowerCase().contains('exercise')) {
      // Simulate updating Fitness data
      // AppModelsManager.fitness?.dailyDataHistory.add(newFitnessDailyData);
      updatedCountFitness = 1; // Simulate 1 update
      llmResponse += "\nGreat workout! Data updated.";
    }
    if (message.toLowerCase().contains('mood')) {
      // Simulate updating Psychology data
      // AppModelsManager.psychology?.dailyDataHistory.add(newPsychologyDailyData);
      updatedCountPsychology = 2; // Simulate 2 updates
      llmResponse += "\nI've logged your mood.";
    }

    // Update notification counts
    setState(() {
      _notificationCounts['Basic'] = updatedCountBasic;
      _notificationCounts['Doctor'] = updatedCountDoctor;
      _notificationCounts['Nutritionist'] = updatedCountNutritionist;
      _notificationCounts['Fitness'] = updatedCountFitness;
      _notificationCounts['Psychology'] = updatedCountPsychology;
    });

    // Simulate saving data
    await AppModelsManager.saveData();

    setState(() {
      _messages.add({'role': 'llm', 'text': llmResponse, 'time': DateFormat('hh:mma').format(DateTime.now())});
    });
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedImage = File(result.files.single.path!);
        _isUploadingImage = true;
        _uploadProgress = 0.0;
      });

      // Simulate image upload to local storage
      await _uploadImageToLocal(_attachedImage!);

      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection cancelled.')),
      );
    }
  }

  Future<void> _uploadImageToLocal(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final String localPath = '${imagesDir.path}/$fileName';
      await imageFile.copy(localPath);

      // Simulate progress
      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _uploadProgress = i / 10.0;
        });
      }
      _attachedImage = File(localPath); // Update to the locally saved file
    } catch (e) {
      print("Error uploading image to local storage: $e");
      // Handle error, maybe show a message to the user
      setState(() {
        _isUploadingImage = false;
        _attachedImage = null; // Clear attached image on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    }
  }

  void _removeAttachedImage() {
    setState(() {
      _attachedImage = null;
      _isUploadingImage = false;
      _uploadProgress = 0.0;
    });
  }

  void _sendMessage() {
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the image to finish uploading.')),
      );
      return;
    }

    if (_messageController.text.isNotEmpty || _attachedImage != null) {
      _analyzeAndCategorizeLLMResponse(
        _messageController.text,
        imagePath: _attachedImage?.path,
      );
      _messageController.clear();
      _removeAttachedImage(); // Clear attached image after sending
    }
  }

  // Helper to build a tab with an optional notification badge
  Widget _buildTab(String text, IconData icon, int notificationCount) {
    return Tab(
      child: SizedBox( // Explicitly constrain the height of the tab content
        height: 55, // A reasonable height for icon + text + badge
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22), // Slightly smaller icon
                Text(text, style: const TextStyle(fontSize: 10)), // Slightly smaller text
              ],
            ),
            if (notificationCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Management'),
        centerTitle: true,
        backgroundColor: Colors.orange[100],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.deepOrange,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: Colors.grey,
          onTap: (index) {
            Widget destinationScreen;
            switch (index) {
              case 0: // Basic
                destinationScreen = const UserProfileScreen();
                break;
              case 1: // Doctor
                destinationScreen = const DoctorScreen();
                break;
              case 2: // Nutritionist
                destinationScreen = const NutritionistScreen();
                break;
              case 3: // Fitness
                destinationScreen = const FitnessScreen();
                break;
              case 4: // Psychology
                destinationScreen = const PsychologyScreen();
                break;
              default:
                destinationScreen = WeightHome(chatEngine: widget.chatEngine,); // Fallback to WeightHome
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => destinationScreen),
            );
          },
          tabs: [
            _buildTab('Basic', Icons.person, _notificationCounts['Basic']!),
            _buildTab('Doctor', Icons.medical_services, _notificationCounts['Doctor']!),
            _buildTab('Nutritionist', Icons.restaurant, _notificationCounts['Nutritionist']!),
            _buildTab('Fitness', Icons.fitness_center, _notificationCounts['Fitness']!),
            _buildTab('Psychology', Icons.psychology, _notificationCounts['Psychology']!),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded( // Ensure chat messages take up available space
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final imagePath = message['imagePath'];

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.pink[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (imagePath != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                File(imagePath),
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          ),
                        Text(
                          message['text']!,
                          style: const TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          message['time']!,
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 8.0 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column( // Use Column to stack attached image preview and input row
              children: [
                if (_attachedImage != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isUploadingImage)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  value: _uploadProgress,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(
                                  _attachedImage!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachedImage!.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: _removeAttachedImage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined), // Upload image icon
                      onPressed: _pickImage,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    FloatingActionButton(
                      onPressed: _sendMessage,
                      mini: true,
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0), // Add a small bottom padding for visual spacing
              ],
            ),
          ),
        ],
      ),
    );
  }
}

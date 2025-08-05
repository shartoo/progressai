import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progressai/weight_manage/user_data.dart';
import 'package:progressai/weight_manage/weight_home.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../model_chat.dart';

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
  final ModelChat _modelChat = ModelChat();
  final ScrollController _scrollController = ScrollController(); // Add ScrollController
  bool _isLLMThinking = false;

  // Notification counters for each category
  Map<String, int> _notificationCounts = {
    'Basic': 0,
    'Doctor': 0,
    'Nutritionist': 0,
    'Fitness': 0,
    'Psychology': 0,
  };

  final ImagePicker _imagePicker = ImagePicker();
  File? _attachedImage; // To store the attached image file
  Uint8List? _selectedImage; // To store the attached image bytes
  bool _isUploadingImage = false; // To track image upload status (if needed for UI)
  double _uploadProgress = 0.0; // To track image upload progress (if needed for UI)

  // The JSON metadata for LLM prompt
  final String _llmMetadata = """
{
  "UserProfile": {
    "description": "Basic user information, capturing fundamental personal details and overall weight management goals.",
    "Fixed_Attributes": {
      "age": "User's age.",
      "gender": "User's gender.",
      "heightCm": "User's height in centimeters.",
      "initialWeightKg": "User's weight at the start of the program in kilograms.",
      "currentWeightKg": "User's current weight in kilograms.",
      "targetWeightKg": "User's target weight in kilograms.",
      "targetDate": "The target date to achieve the weight goal.",
      "weeklyWeightLossTargetKg": "User's weekly target weight loss in kilograms.",
      "progressPercentage": "Calculated percentage of progress towards the target weight.",
      "weightLossPhase": "Current phase of the weight management journey (e.g., 'Initial Phase').",
      "occupation": "User's occupation, which may influence activity levels and stress.",
      "activityLevel": "User's general activity level (e.g., 'Sedentary', 'Lightly Active').",
      "healthConditions": "List of known health conditions.",
      "medicalAllergies": "History of drug allergies.",
      "dietaryPreferencesRestrictions": "User's dietary preferences or restrictions (e.g., 'Vegetarian', 'Gluten-Free').",
      "sleepPatternDescription": "A description of the user's sleep habits.",
      "stressLevelDescription": "A description of the user's stress levels.",
      "longTermGoalsDescription": "A description of the user's long-term health and fitness goals.",
      "startDate": "The date the user started using the app.",
      "bodyShape": "User's body shape (e.g., 'Rectangle')."
    },
    "Daily_Data": {
      "weightHistory": {
        "description": "List of daily weight entries.",
        "fields": {
          "date": "The date of the weight recording.",
          "weightKg": "The recorded weight in kilograms."
        }
      }
    }
  },
  "Doctor": {
    "description": "Medical information, focusing on the user's medical history and daily health metrics relevant to a doctor.",
    "Fixed_Attributes": {
      "allergyMedications": "List of medications the user is allergic to.",
      "currentMedications": "List of medications the user is currently taking.",
      "existingMedicalConditions": "List of pre-existing medical conditions (e.g., 'Hypertension', 'Diabetes').",
      "bloodLipidProfile": "Map of blood lipid levels (e.g., Total Cholesterol, LDL, HDL, Triglycerides).",
      "thyroidFunction": "Overview of thyroid function (e.g., 'Normal').",
      "liverKidneyFunction": "Overview of liver and kidney function."
    },
    "Daily_Data": {
      "dailyDataHistory": {
        "description": "List of daily medical data entries.",
        "fields": {
          "date": "The date of the daily record.",
          "bloodGlucose": "Daily blood glucose level.",
          "bloodPressure": "Daily blood pressure reading.",
          "bodyStatus": "Description of daily body status (e.g., 'Feeling good').",
          "sleepQuality": "Daily sleep quality (e.g., 'Good', 'Average').",
          "waterIntakeMl": "Daily water intake in milliliters.",
          "bowelMovementStatus": "Daily bowel movement status.",
          "medicationAdherence": "Status of medication adherence.",
          "symptoms": "List of any recorded symptoms."
        }
      }
    }
  },
  "Nutritionist": {
    "description": "Nutritional information, covering the user's dietary habits, preferences, and daily food intake.",
    "Fixed_Attributes": {
      "dailyEatingPattern": "Description of the user's typical daily eating pattern.",
      "cookingPreference": "User's preferred cooking methods.",
      "dislikedFoods": "List of foods the user dislikes.",
      "foodAllergies": "List of food allergies.",
      "eatingOutFrequency": "How often the user eats out.",
      "alcoholConsumption": "User's alcohol consumption habits.",
      "caffeineIntake": "User's caffeine intake habits."sibleNutrientDeficiencies": "List of potential nutrient deficiencies.",
      "recommendedSupplements": "List of recommended supplements.",
      "digestiveHealthOverview": "Overview of the user's digestive health."
    },
    "Daily_Data": {
      "dailyDataHistory": {
        "description": "List of daily diet record entries.",
        "fields": {
          "date": "The date of the meal record.",
          "mealCategory": "Type of meal (e.g., 'Breakfast', 'Lunch').",
          "imageUrl": "URL or local path of the food image.",
          "foodNutritionSummary": "A text description of the meal's nutrition.",
          "foodMetricsData": "Map of food metrics (e.g., Protein, Fat, Energy, Carbs, Other)."
        }
      }
    }
  },
  "Fitness": {
    "description": "Fitness information, recording the user's fitness preferences, limitations, goals, and daily workout details.",
    "Fixed_Attributes": {
      "bodyMeasurements": "Map of body circumference measurements (e.g., Waist, Hip, Chest).",
      "likedExercises": "List of exercises the user enjoys.",
      "dislikedExercises": "List of exercises the user dislikes.",
      "preferredWorkoutStyle": "User's preferred workout style.",
      "physicalLimitations": "List of any physical limitations or old injuries.",
      "fitnessGoals": "List of the user's fitness goals."
    },
    "Daily_Data": {
      "dailyDataHistory": {
        "description": "List of daily fitness data entries.",
        "fields": {
          "date": "The date of the workout record.",
          "exerciseItem": "Description of the exercise performed.",
          "estimatedCalorieBurn": "Estimated calories burned during the workout.",
          "fatLossArea": "Specific area targeted for fat loss (if any).",
          "workoutDurationMinutes": "Duration of the workout in minutes.",
          "intensityLevel": "Workout intensity (e.g., 'Low', 'Medium').",
          "exerciseSummary": "A summary of the exercise session.",
          "averageHeartRate": "Average heart rate during the workout.",
          "peakHeartRate": "Peak heart rate during the workout.",
          "strengthTrainingDetails": "Details of strength training (sets, reps, weight).",
          "cardioDetails": "Details of cardio training (e.g., distance, pace).",
          "userBodyStatus": "User's body status after the workout.",
          "feelingAfterWorkout": "How the user felt after the workout.",
          "recoveryStatus": "User's recovery status."
        }
      }
    }
  },
  "Psychology": {
    "description": "Psychological information, focusing on the user's psychological state, motivations, and daily emotional well-being related to their health journey.",
    "Fixed_Attributes": {
      "weightLossMotivation": "The user's underlying motivation for weight loss (e.g., 'For health and confidence', 'Perfectionism').",
      "pastDietExperience": "A summary of past weight loss and fitness experiences and their psychological impact.",
      "selfConfidenceIndex": "A numerical index (1-10) representing the user's confidence in achieving their goals.",
      "selfPerception": "How the user views and evaluates their own physical appearance."
    },
    "Daily_Data": {
      "dailyDataHistory": {
        "description": "List of daily psychological data entries.",
        "fields": {
          "date": "The date of the daily record.",
          "moodStatus": "User's daily mood status (e.g., 'Happy', 'Anxious', 'Frustrated').",
          "stressLevel": "User's daily stress level (e.g., 'Low', 'Medium', 'High').",
          "psychologicalChallenges": "List of psychological challenges encountered on that day (e.g., 'Cravings', 'Lack of motivation')."
        }
      }
    }
  }
}
""";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 tabs for Basic, Doctor, Nutritionist, Fitness, Psychology
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  // Placeholder method for LLM analysis and data update
  Future<void> _analyzeAndCategorizeLLMResponse(String message, {String? imagePath}) async {
    // Add user message to chat history
    setState(() {
      _messages.add({
        'role': 'user',
        'text': message,
        'time': DateFormat('hh:mma').format(DateTime.now()),
        if (imagePath != null) 'imagePath': imagePath,
      });
      _isLLMThinking = true; // Set thinking status to true
      // Add a placeholder for LLM response that will be updated by stream
      _messages.add({
        'role': 'llm',
        'text': '', // Start with an empty text
        'time': DateFormat('hh:mma').format(DateTime.now()),
      });
    });

    // Scroll to the bottom after adding user message
    _scrollToBottom();

    final jsonResponse = await _modelChat.chat(
        chatEngine: widget.chatEngine,
        text: message,
        imageBytes:_selectedImage,
    );

    // final response = ModelChat.parseResponse(jsonResponse);
    // final responseText = ModelChat.getMessage(response) ?? '';
    final responseText = ModelChat.cleanJsonResponse(jsonResponse);
    String llmResponse = "Gemma-3n response : $responseText";
    int updatedCountBasic = 1;
    int updatedCountDoctor = 2;
    int updatedCountNutritionist = 3;
    int updatedCountFitness = 2;
    int updatedCountPsychology = 3;

    // Update notification counts
    setState(() {
      _notificationCounts['Basic'] = updatedCountBasic;
      _notificationCounts['Doctor'] = updatedCountDoctor;
      _notificationCounts['Nutritionist'] = updatedCountNutritionist;
      _notificationCounts['Fitness'] = updatedCountFitness;
      _notificationCounts['Psychology'] = updatedCountPsychology;
      _isLLMThinking = false;
    });

    await AppModelsManager.saveData();

    setState(() {
      _messages.add({'role': 'llm', 'text': llmResponse, 'time': DateFormat('hh:mma').format(DateTime.now())});
    });

    // Scroll to the bottom after adding LLM response
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = bytes;
        _attachedImage = File(pickedFile.path);
      });
      setState(() {
        _isUploadingImage = false;
        _uploadProgress = 1.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );

    } else {
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

      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _uploadProgress = i / 10.0;
        });
      }
      _attachedImage = File(localPath);
    } catch (e) {
      print("Error uploading image to local storage: $e");
      setState(() {
        _isUploadingImage = false;
        _attachedImage = null;
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
      _removeAttachedImage();
    }
  }

  Widget _buildTab(String text, IconData icon, int notificationCount) {
    return Tab(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              Text(text, style: const TextStyle(fontSize: 9)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight Management Chat'),
        centerTitle: true,
        backgroundColor: Colors.orange[100],
        bottom: PreferredSize( // Wrap TabBar in PreferredSize
          preferredSize: const Size.fromHeight(kToolbarHeight + 12.0), // Give it more height
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.deepOrange,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            onTap: (index) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WeightHome(
                    chatEngine: widget.chatEngine,
                    initialTabIndex: index,
                  ),
                ),
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
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
          // LLM Thinking Indicator
          if (_isLLMThinking)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 10),
                  Text('Gemma-3n is thinking...', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              bottom: 8.0 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
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
                      icon: const Icon(Icons.image_outlined),
                      onPressed: _pickImage,
                      color: Colors.deepOrange,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: null, // Allow multiple lines for input
                        keyboardType: TextInputType.multiline, // Set keyboard type for multiline
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
                const SizedBox(height: 8.0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

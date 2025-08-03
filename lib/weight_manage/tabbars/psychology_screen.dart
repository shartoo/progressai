import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../user_data.dart';

class PsychologyScreen extends StatefulWidget {
  const PsychologyScreen({super.key});

  @override
  State<PsychologyScreen> createState() => _PsychologyScreenState();
}

class _PsychologyScreenState extends State<PsychologyScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for fixed psychological data
  late TextEditingController _weightLossMotivationController;
  late TextEditingController _pastDietExperienceController;
  late TextEditingController _selfConfidenceIndexController;
  late TextEditingController _selfPerceptionController;

  // Controllers for adding daily data
  late TextEditingController _moodStatusController;
  late TextEditingController _stressLevelController;
  late TextEditingController _psychologicalChallengesController;

  Psychology? _initialPsychologyData; // To track changes for fixed info
  Future<Psychology?>? _psychologyFuture; // Future to hold the psychology data

  @override
  void initState() {
    super.initState();
    _loadPsychologyData();
  }

  void _loadPsychologyData() {
    // Set the future that FutureBuilder will listen to
    _psychologyFuture = AppModelsManager.loadData().then((_) {
      final psychologyData = AppModelsManager.psychology ?? Psychology.defaultPsychology();
      _initialPsychologyData = psychologyData; // Save initial state

      _weightLossMotivationController = TextEditingController(text: psychologyData.weightLossMotivation);
      _pastDietExperienceController = TextEditingController(text: psychologyData.pastDietExperience);
      _selfConfidenceIndexController = TextEditingController(text: psychologyData.selfConfidenceIndex.toString());
      _selfPerceptionController = TextEditingController(text: psychologyData.selfPerception);

      // Add listeners for fixed psychological info fields
      _weightLossMotivationController.addListener(_onFixedFieldChanged);
      _pastDietExperienceController.addListener(_onFixedFieldChanged);
      _selfConfidenceIndexController.addListener(_onFixedFieldChanged);
      _selfPerceptionController.addListener(_onFixedFieldChanged);

      // Initialize daily data controllers (will be reset for each new entry)
      _moodStatusController = TextEditingController();
      _stressLevelController = TextEditingController();
      _psychologicalChallengesController = TextEditingController();

      return psychologyData; // Return the loaded data
    });
  }

  @override
  void dispose() {
    _weightLossMotivationController.dispose();
    _pastDietExperienceController.dispose();
    _selfConfidenceIndexController.dispose();
    _selfPerceptionController.dispose();

    _moodStatusController.dispose();
    _stressLevelController.dispose();
    _psychologicalChallengesController.dispose();
    super.dispose();
  }

  // Check if fixed psychological info has changed
  void _onFixedFieldChanged() {
    final currentData = _getCurrentFixedPsychologyDataFromControllers();
    final isChanged = _isPsychologyFixedDataChanged(_initialPsychologyData, currentData);
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = isChanged;
  }

  Psychology _getCurrentFixedPsychologyDataFromControllers() {
    return Psychology(
      weightLossMotivation: _weightLossMotivationController.text,
      pastDietExperience: _pastDietExperienceController.text,
      selfConfidenceIndex: int.tryParse(_selfConfidenceIndexController.text) ?? 0,
      selfPerception: _selfPerceptionController.text,
      dailyDataHistory: AppModelsManager.psychology?.dailyDataHistory ?? [], // Preserve daily history
    );
  }

  bool _isPsychologyFixedDataChanged(Psychology? oldData, Psychology newData) {
    if (oldData == null) return true;

    return oldData.weightLossMotivation != newData.weightLossMotivation ||
        oldData.pastDietExperience != newData.pastDietExperience ||
        oldData.selfConfidenceIndex != newData.selfConfidenceIndex ||
        oldData.selfPerception != newData.selfPerception;
  }

  // Save changes to AppModelsManager and local storage for fixed psychological info
  void _saveFixedChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedPsychology = _getCurrentFixedPsychologyDataFromControllers();
      AppModelsManager.psychology = updatedPsychology;
      await AppModelsManager.saveData();
      _initialPsychologyData = updatedPsychology; // Update initial state
      Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Psychological information saved!')),
      );
      // Reload data to ensure FutureBuilder rebuilds
      setState(() {
        _loadPsychologyData();
      });
    }
  }

  // Cancel changes and revert to initial data for fixed psychological info
  void _cancelFixedChanges() {
    _loadPsychologyData(); // Revert all controllers to initial state
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes cancelled.')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadPsychologyData();
    });
  }

  // Show dialog to add new daily data
  void _showAddDailyDataDialog() {
    // Reset controllers for new entry
    _moodStatusController.clear();
    _stressLevelController.clear();
    _psychologicalChallengesController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Daily Psychological Data'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Reusing form key for dialog
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(controller: _moodStatusController, labelText: 'Mood Status (e.g., Happy, Anxious)'),
                  _buildTextField(controller: _stressLevelController, labelText: 'Stress Level (Low, Medium, High)'),
                  _buildTextField(controller: _psychologicalChallengesController, labelText: 'Psychological Challenges (comma-separated)', maxLines: 2),
                ].map((widget) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: widget,
                )).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newDailyData = PsychologyDailyData(
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    moodStatus: _moodStatusController.text.isNotEmpty ? _moodStatusController.text : "Neutral",
                    stressLevel: _stressLevelController.text.isNotEmpty ? _stressLevelController.text : "Medium",
                    psychologicalChallenges: _psychologicalChallengesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  );

                  setState(() {
                    AppModelsManager.psychology?.dailyDataHistory.add(newDailyData);
                    // Sort history by date in descending order
                    AppModelsManager.psychology?.dailyDataHistory.sort((a, b) => b.date.compareTo(a.date));
                  });
                  await AppModelsManager.saveData();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Daily psychological data added!')),
                  );
                  // Reload data to ensure FutureBuilder rebuilds
                  setState(() {
                    _loadPsychologyData();
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a daily data entry
  void _deleteDailyData(int index) async {
    setState(() {
      AppModelsManager.psychology?.dailyDataHistory.removeAt(index);
    });
    await AppModelsManager.saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily psychological record deleted!')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadPsychologyData();
    });
  }

  // Helper to get emoji for mood
  String _getMoodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'calm':
        return '😌';
      case 'anxious':
        return '😟';
      case 'frustrated':
        return '😤';
      case 'sad':
        return '😔';
      case 'energetic':
        return '⚡';
      case 'tired':
        return '😴';
      case 'motivated':
        return '💪';
      case 'discouraged':
        return '😞';
      default:
        return '😐'; // Neutral
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = Provider.of<EditingStateProvider>(context).isEditing;

    return FutureBuilder<Psychology?>(
      future: _psychologyFuture, // Use the state variable future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading psychological data: ${snapshot.error}'));
        } else {
          final psychology = snapshot.data!; // Use snapshot.data directly

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fixed Psychological Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        context,
                        title: 'Motivation & Past Experiences',
                        children: [
                          _buildTextField(controller: _weightLossMotivationController, labelText: 'Weight Loss Motivation', maxLines: 3),
                          _buildTextField(controller: _pastDietExperienceController, labelText: 'Past Diet Experience & Impact', maxLines: 3),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSectionCard(
                        context,
                        title: 'Self-Perception & Confidence',
                        children: [
                          _buildTextField(controller: _selfConfidenceIndexController, labelText: 'Self-Confidence Index (1-10)', keyboardType: TextInputType.number),
                          _buildTextField(controller: _selfPerceptionController, labelText: 'Self-Perception (Appearance)', maxLines: 3),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Daily Psychological Records',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showAddDailyDataDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Daily Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (psychology.dailyDataHistory.isEmpty)
                        const Center(child: Text('No daily psychological data recorded yet.'))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: psychology.dailyDataHistory.length,
                          itemBuilder: (context, index) {
                            final data = psychology.dailyDataHistory[index];
                            return _buildDailyDataCard(context, data, index); // Pass index for deletion
                          },
                        ),
                      const SizedBox(height: 80), // Space for buttons
                    ],
                  ),
                ),
              ),
              // Confirm/Cancel buttons for fixed psychological info
              if (isEditing)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.white.withOpacity(0.9),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cancelFixedChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveFixedChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Confirm', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }
      },
    );
  }

  // Reusable section card widget
  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            ...children.map((widget) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: widget,
            )).toList(),
          ],
        ),
      ),
    );
  }

  // Reusable text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) => _onFixedFieldChanged(), // Trigger change detection for fixed fields
      maxLines: maxLines,
    );
  }

  // Widget to display a single daily data entry
  Widget _buildDailyDataCard(BuildContext context, PsychologyDailyData data, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: ${data.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteDailyData(index),
                ),
              ],
            ),
            const Divider(height: 10, thickness: 0.5),
            Row(
              children: [
                Text('Mood Status: ${data.moodStatus} ', style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(_getMoodEmoji(data.moodStatus), style: const TextStyle(fontSize: 24)),
              ],
            ),
            _buildDataRow('Stress Level:', data.stressLevel),
            if (data.psychologicalChallenges.isNotEmpty)
              _buildDataRow('Challenges:', data.psychologicalChallenges.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150, // Fixed width for labels
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

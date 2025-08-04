import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../main.dart'; // Ensure main.dart is imported to access EditingStateProvider
import '../user_data.dart';

class FitnessScreen extends StatefulWidget {
  const FitnessScreen({super.key});

  @override
  State<FitnessScreen> createState() => _FitnessScreenState();
}

class _FitnessScreenState extends State<FitnessScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for fixed fitness data
  late TextEditingController _likedExercisesController;
  late TextEditingController _dislikedExercisesController;
  late TextEditingController _preferredWorkoutStyleController;
  late TextEditingController _physicalLimitationsController;
  late TextEditingController _fitnessGoalsController;
  late TextEditingController _waistCircumferenceController;
  late TextEditingController _hipCircumferenceController;
  late TextEditingController _chestCircumferenceController;

  // Controllers for adding daily data
  late TextEditingController _exerciseItemController;
  late TextEditingController _estimatedCalorieBurnController;
  late TextEditingController _fatLossAreaController;
  late TextEditingController _workoutDurationMinutesController;
  late TextEditingController _intensityLevelController;
  late TextEditingController _exerciseSummaryController;
  late TextEditingController _averageHeartRateController;
  late TextEditingController _peakHeartRateController;
  late TextEditingController _strengthTrainingDetailsController; // Simplified as String
  late TextEditingController _cardioDetailsController; // Simplified as String
  late TextEditingController _userBodyStatusController;
  late TextEditingController _feelingAfterWorkoutController;
  late TextEditingController _recoveryStatusController;

  Fitness? _initialFitnessData; // To track changes for fixed fitness info
  Future<Fitness?>? _fitnessFuture; // Future to hold the fitness data

  @override
  void initState() {
    super.initState();
    _loadFitnessData();
  }

  void _loadFitnessData() {
    // Set the future that FutureBuilder will listen to
    _fitnessFuture = AppModelsManager.loadData().then((_) {
      final fitnessData = AppModelsManager.fitness ?? Fitness.defaultFitness();
      _initialFitnessData = fitnessData; // Save initial state

      _likedExercisesController = TextEditingController(text: fitnessData.likedExercises.join(', '));
      _dislikedExercisesController = TextEditingController(text: fitnessData.dislikedExercises.join(', '));
      _preferredWorkoutStyleController = TextEditingController(text: fitnessData.preferredWorkoutStyle);
      _physicalLimitationsController = TextEditingController(text: fitnessData.physicalLimitations.join(', '));
      _fitnessGoalsController = TextEditingController(text: fitnessData.fitnessGoals.join(', '));
      // Accessing bodyMeasurements with English keys based on user_data.dart structure
      _waistCircumferenceController = TextEditingController(text: fitnessData.bodyMeasurements?['Waist']?.toString() ?? '');
      _hipCircumferenceController = TextEditingController(text: fitnessData.bodyMeasurements?['Hip']?.toString() ?? '');
      _chestCircumferenceController = TextEditingController(text: fitnessData.bodyMeasurements?['Chest']?.toString() ?? '');

      // Add listeners for fixed fitness info fields
      _likedExercisesController.addListener(_onFixedFieldChanged);
      _dislikedExercisesController.addListener(_onFixedFieldChanged);
      _preferredWorkoutStyleController.addListener(_onFixedFieldChanged);
      _physicalLimitationsController.addListener(_onFixedFieldChanged);
      _fitnessGoalsController.addListener(_onFixedFieldChanged);
      _waistCircumferenceController.addListener(_onFixedFieldChanged);
      _hipCircumferenceController.addListener(_onFixedFieldChanged);
      _chestCircumferenceController.addListener(_onFixedFieldChanged);

      // Initialize daily data controllers (will be reset for each new entry)
      _exerciseItemController = TextEditingController();
      _estimatedCalorieBurnController = TextEditingController();
      _fatLossAreaController = TextEditingController();
      _workoutDurationMinutesController = TextEditingController();
      _intensityLevelController = TextEditingController();
      _exerciseSummaryController = TextEditingController();
      _averageHeartRateController = TextEditingController();
      _peakHeartRateController = TextEditingController();
      _strengthTrainingDetailsController = TextEditingController();
      _cardioDetailsController = TextEditingController();
      _userBodyStatusController = TextEditingController();
      _feelingAfterWorkoutController = TextEditingController();
      _recoveryStatusController = TextEditingController();

      return fitnessData; // Return the loaded data
    });
  }

  @override
  void dispose() {
    _likedExercisesController.dispose();
    _dislikedExercisesController.dispose();
    _preferredWorkoutStyleController.dispose();
    _physicalLimitationsController.dispose();
    _fitnessGoalsController.dispose();
    _waistCircumferenceController.dispose();
    _hipCircumferenceController.dispose();
    _chestCircumferenceController.dispose();

    _exerciseItemController.dispose();
    _estimatedCalorieBurnController.dispose();
    _fatLossAreaController.dispose();
    _workoutDurationMinutesController.dispose();
    _intensityLevelController.dispose();
    _exerciseSummaryController.dispose();
    _averageHeartRateController.dispose();
    _peakHeartRateController.dispose();
    _strengthTrainingDetailsController.dispose();
    _cardioDetailsController.dispose();
    _userBodyStatusController.dispose();
    _feelingAfterWorkoutController.dispose();
    _recoveryStatusController.dispose();
    super.dispose();
  }

  // Check if fixed fitness info has changed
  void _onFixedFieldChanged() {
    final currentData = _getCurrentFixedFitnessDataFromControllers();
    final isChanged = _isFitnessFixedDataChanged(_initialFitnessData, currentData);
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = isChanged;
  }

  Fitness _getCurrentFixedFitnessDataFromControllers() {
    return Fitness(
      likedExercises: _likedExercisesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      dislikedExercises: _dislikedExercisesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      preferredWorkoutStyle: _preferredWorkoutStyleController.text,
      physicalLimitations: _physicalLimitationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      fitnessGoals: _fitnessGoalsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      bodyMeasurements: {
        "Waist": double.tryParse(_waistCircumferenceController.text) ?? 0.0,
        "Hip": double.tryParse(_hipCircumferenceController.text) ?? 0.0,
        "Chest": double.tryParse(_chestCircumferenceController.text) ?? 0.0,
      },
      dailyDataHistory: AppModelsManager.fitness?.dailyDataHistory ?? [], // Preserve daily history
    );
  }

  bool _isFitnessFixedDataChanged(Fitness? oldData, Fitness newData) {
    if (oldData == null) return true;

    return !_listEquals(oldData.likedExercises, newData.likedExercises) ||
        !_listEquals(oldData.dislikedExercises, newData.dislikedExercises) ||
        oldData.preferredWorkoutStyle != newData.preferredWorkoutStyle ||
        !_listEquals(oldData.physicalLimitations, newData.physicalLimitations) ||
        !_listEquals(oldData.fitnessGoals, newData.fitnessGoals) ||
        !_mapEquals(oldData.bodyMeasurements, newData.bodyMeasurements);
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map<String, double>? a, Map<String, double>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }


  // Save changes to AppModelsManager and local storage for fixed fitness info
  void _saveFixedChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedFitness = _getCurrentFixedFitnessDataFromControllers();
      AppModelsManager.fitness = updatedFitness;
      await AppModelsManager.saveData();
      _initialFitnessData = updatedFitness; // Update initial state
      Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('健身信息已保存！')),
      );
      // Reload data to ensure FutureBuilder rebuilds
      setState(() {
        _loadFitnessData();
      });
    }
  }

  // Cancel changes and revert to initial data for fixed fitness info
  void _cancelFixedChanges() {
    _loadFitnessData(); // Revert all controllers to initial state
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消更改。')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadFitnessData();
    });
  }

  // Show dialog to add new daily data
  void _showAddDailyDataDialog() {
    // Reset controllers for new entry
    _exerciseItemController.clear();
    _estimatedCalorieBurnController.clear();
    _fatLossAreaController.clear();
    _workoutDurationMinutesController.clear();
    _intensityLevelController.clear();
    _exerciseSummaryController.clear();
    _averageHeartRateController.clear();
    _peakHeartRateController.clear();
    _strengthTrainingDetailsController.clear();
    _cardioDetailsController.clear();
    _userBodyStatusController.clear();
    _feelingAfterWorkoutController.clear();
    _recoveryStatusController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use dialogContext for the dialog's context
        return AlertDialog(
          title: const Text('Add Daily Fitness Data'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Reusing form key for dialog
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(controller: _exerciseItemController, labelText: 'Exercise Item'),
                  _buildTextField(controller: _estimatedCalorieBurnController, labelText: 'Estimated Calorie Burn', keyboardType: TextInputType.number),
                  _buildTextField(controller: _fatLossAreaController, labelText: 'Fat Loss Area (Optional)'),
                  _buildTextField(controller: _workoutDurationMinutesController, labelText: 'Workout Duration (minutes)', keyboardType: TextInputType.number),
                  _buildTextField(controller: _intensityLevelController, labelText: 'Intensity Level (Low, Medium, High)'),
                  _buildTextField(controller: _exerciseSummaryController, labelText: 'Exercise Summary', maxLines: 2),
                  _buildTextField(controller: _averageHeartRateController, labelText: 'Average Heart Rate', keyboardType: TextInputType.number),
                  _buildTextField(controller: _peakHeartRateController, labelText: 'Peak Heart Rate', keyboardType: TextInputType.number),
                  _buildTextField(controller: _strengthTrainingDetailsController, labelText: 'Strength Training Details (e.g., Squats:3x8x60kg)', maxLines: 3),
                  _buildTextField(controller: _cardioDetailsController, labelText: 'Cardio Details (e.g., 5km in 30min)', maxLines: 2),
                  _buildTextField(controller: _userBodyStatusController, labelText: 'User Body Status'),
                  _buildTextField(controller: _feelingAfterWorkoutController, labelText: 'Feeling After Workout'),
                  _buildTextField(controller: _recoveryStatusController, labelText: 'Recovery Status'),
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
                Navigator.of(dialogContext).pop(); // Use dialogContext to pop the dialog
                setState(() { // <--- Add setState and reload data here to refresh the screen
                  _loadFitnessData();
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Parse strength training details from string
                  List<Map<String, dynamic>>? strengthDetails;
                  if (_strengthTrainingDetailsController.text.isNotEmpty) {
                    strengthDetails = [];
                    _strengthTrainingDetailsController.text.split(';').forEach((detail) {
                      final parts = detail.split(':');
                      if (parts.length == 2) {
                        final exercise = parts[0].trim();
                        final stats = parts[1].trim().split('x');
                        if (stats.length == 3) {
                          strengthDetails!.add({
                            "exercise": exercise,
                            "sets": int.tryParse(stats[0]),
                            "reps": int.tryParse(stats[1]),
                            "weight": double.tryParse(stats[2].replaceAll('kg', '')),
                          });
                        }
                      }
                    });
                  }

                  // Parse cardio details from string (simplified)
                  Map<String, dynamic>? cardioDetails;
                  if (_cardioDetailsController.text.isNotEmpty) {
                    cardioDetails = {"description": _cardioDetailsController.text};
                  }

                  final newDailyData = FitnessDailyData(
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    exerciseItem: _exerciseItemController.text,
                    estimatedCalorieBurn: double.tryParse(_estimatedCalorieBurnController.text) ?? 0.0,
                    fatLossArea: _fatLossAreaController.text.isNotEmpty ? _fatLossAreaController.text : null,
                    workoutDurationMinutes: int.tryParse(_workoutDurationMinutesController.text),
                    intensityLevel: _intensityLevelController.text.isNotEmpty ? _intensityLevelController.text : null,
                    exerciseSummary: _exerciseSummaryController.text.isNotEmpty ? _exerciseSummaryController.text : null,
                    averageHeartRate: double.tryParse(_averageHeartRateController.text),
                    peakHeartRate: double.tryParse(_peakHeartRateController.text),
                    strengthTrainingDetails: strengthDetails,
                    cardioDetails: cardioDetails,
                    userBodyStatus: _userBodyStatusController.text.isNotEmpty ? _userBodyStatusController.text : null,
                    feelingAfterWorkout: _feelingAfterWorkoutController.text.isNotEmpty ? _feelingAfterWorkoutController.text : null,
                    recoveryStatus: _recoveryStatusController.text.isNotEmpty ? _recoveryStatusController.text : null,
                  );

                  setState(() {
                    AppModelsManager.fitness?.dailyDataHistory.add(newDailyData);
                    // Sort history by date in descending order
                    AppModelsManager.fitness?.dailyDataHistory.sort((a, b) => b.date.compareTo(a.date));
                  });
                  await AppModelsManager.saveData();
                  Navigator.of(dialogContext).pop(); // Use dialogContext to pop the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('每日健身数据已添加！')),
                  );
                  // Reload data to ensure FutureBuilder rebuilds after adding data
                  setState(() {
                    _loadFitnessData();
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
      AppModelsManager.fitness?.dailyDataHistory.removeAt(index);
    });
    await AppModelsManager.saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('每日健身记录已删除！')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadFitnessData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = Provider.of<EditingStateProvider>(context).isEditing;

    return  FutureBuilder<Fitness?>(
        future: _fitnessFuture, // Use the state variable future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading fitness data: ${snapshot.error}'));
          } else {
            final fitness = snapshot.data!; // Guaranteed to be not null here

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
                          'Baseline Fitness Information',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: 'Preferences & Goals',
                          children: [
                            _buildTextField(controller: _likedExercisesController, labelText: 'Liked Exercises (comma-separated)'),
                            _buildTextField(controller: _dislikedExercisesController, labelText: 'Disliked Exercises (comma-separated)'),
                            _buildTextField(controller: _preferredWorkoutStyleController, labelText: 'Preferred Workout Style'),
                            _buildTextField(controller: _physicalLimitationsController, labelText: 'Physical Limitations (comma-separated)'),
                            _buildTextField(controller: _fitnessGoalsController, labelText: 'Fitness Goals (comma-separated)'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: 'Body Measurements (cm)',
                          children: [
                            _buildTextField(controller: _waistCircumferenceController, labelText: 'Waist Circumference', keyboardType: TextInputType.number),
                            _buildTextField(controller: _hipCircumferenceController, labelText: 'Hip Circumference', keyboardType: TextInputType.number),
                            _buildTextField(controller: _chestCircumferenceController, labelText: 'Chest Circumference', keyboardType: TextInputType.number),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded( // Wrap Text with Expanded
                              child: Text(
                                'Daily Fitness Records',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const SizedBox(width: 8), // Add some spacing
                            Expanded( // Wrap ElevatedButton with Expanded
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
                        if (fitness.dailyDataHistory.isEmpty)
                          const Center(child: Text('No daily fitness data recorded yet.'))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(), // Prevents nested scrolling issues
                            itemCount: fitness.dailyDataHistory.length,
                            itemBuilder: (context, index) {
                              final data = fitness.dailyDataHistory[index];
                              return _buildDailyDataCard(context, data); // Pass data directly
                            },
                          ),
                        const SizedBox(height: 80), // Space for buttons
                      ],
                    ),
                  ),
                ),
                // Confirm/Cancel buttons for fixed fitness info
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
  Widget _buildDailyDataCard(BuildContext context, FitnessDailyData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.lightGreen[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${data.date}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 10, thickness: 0.5),
            _buildDataRow('Exercise:', data.exerciseItem),
            _buildDataRow('Estimated Burn:', '${data.estimatedCalorieBurn?.toStringAsFixed(1) ?? 'N/A'} kcal'), // Handle null
            if (data.fatLossArea != null && data.fatLossArea!.isNotEmpty)
              _buildDataRow('Fat Loss Area:', data.fatLossArea!),
            if (data.workoutDurationMinutes != null)
              _buildDataRow('Duration:', '${data.workoutDurationMinutes} mins'),
            if (data.intensityLevel != null && data.intensityLevel!.isNotEmpty)
              _buildDataRow('Intensity:', data.intensityLevel!),
            if (data.averageHeartRate != null)
              _buildDataRow('Avg Heart Rate:', '${data.averageHeartRate!.toStringAsFixed(0)} bpm'),
            if (data.peakHeartRate != null)
              _buildDataRow('Peak Heart Rate:', '${data.peakHeartRate!.toStringAsFixed(0)} bpm'),
            if (data.strengthTrainingDetails != null && data.strengthTrainingDetails!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Strength Details:', style: TextStyle(fontWeight: FontWeight.w500)),
                  // Correctly iterate and display strength training details
                  ...data.strengthTrainingDetails!.map((detail) => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text('${detail['exercise']}: ${detail['sets']}x${detail['reps']} @ ${detail['weight']}kg'),
                  )).toList(),
                ],
              ),
            if (data.cardioDetails != null && data.cardioDetails!.isNotEmpty)
              _buildDataRow('Cardio Details:', data.cardioDetails!['description'] ?? 'N/A'), // Access 'description' key
            if (data.userBodyStatus != null && data.userBodyStatus!.isNotEmpty)
              _buildDataRow('Body Status:', data.userBodyStatus!),
            if (data.feelingAfterWorkout != null && data.feelingAfterWorkout!.isNotEmpty)
              _buildDataRow('Feeling After Workout:', data.feelingAfterWorkout!),
            if (data.recoveryStatus != null && data.recoveryStatus!.isNotEmpty)
              _buildDataRow('Recovery Status:', data.recoveryStatus!),
            if (data.exerciseSummary != null && data.exerciseSummary!.isNotEmpty)
              _buildDataRow('Summary:', data.exerciseSummary!),
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

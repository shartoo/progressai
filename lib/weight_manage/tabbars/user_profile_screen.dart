import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../user_data.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _ageController;
  late String _selectedGender;
  late TextEditingController _heightController;
  late TextEditingController _initialWeightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _targetWeightController;
  late TextEditingController _targetDateController;
  late TextEditingController _weeklyWeightLossTargetController;
  late String _selectedWeightLossPhase;
  late TextEditingController _occupationController;
  late String _selectedActivityLevel;
  late TextEditingController _healthConditionsController;
  late TextEditingController _medicalAllergiesController;
  late TextEditingController _dietaryPreferencesRestrictionsController;
  late TextEditingController _sleepPatternDescriptionController;
  late TextEditingController _stressLevelDescriptionController;
  late TextEditingController _longTermGoalsDescriptionController;
  late String _selectedBodyShape;

  final List<String> _genderOptions = ["Male", "Female", "Other"];
  final List<String> _activityLevelOptions = [
    "Sedentary",
    "Lightly Active",
    "Moderately Active",
    "Very Active",
    "Extremely Active"
  ];
  final List<String> _bodyShapeOptions = [
    "Apple",
    "Pear",
    "Hourglass",
    "Rectangle",
    "Inverted Triangle",
    "Other"
  ];
  final List<String> _weightLossPhaseOptions = [
    "Initial Phase",
    "Rapid Weight Loss",
    "Plateau",
    "Maintenance",
    "Other"
  ];

  // Store initial data to check for changes
  UserProfile? _initialUserProfile;

  @override
  void initState() {
    super.initState();
    _loadUserProfileData();
  }

  // Load user profile data and initialize controllers
  void _loadUserProfileData() {
    // Ensure AppModelsManager.userProfile is not null, otherwise use default
    final data = AppModelsManager.userProfile ?? UserProfile.defaultProfile();
    _initialUserProfile = data; // Save initial state

    _ageController = TextEditingController(text: data.age.toString());
    _selectedGender = data.gender;
    _heightController = TextEditingController(text: data.heightCm.toString());
    _initialWeightController = TextEditingController(text: data.initialWeightKg.toString());
    _currentWeightController = TextEditingController(text: data.currentWeightKg.toString());
    _targetWeightController = TextEditingController(text: data.targetWeightKg.toString());
    _targetDateController = TextEditingController(text: data.targetDate);
    _weeklyWeightLossTargetController = TextEditingController(text: data.weeklyWeightLossTargetKg.toString());
    _selectedWeightLossPhase = data.weightLossPhase;
    _occupationController = TextEditingController(text: data.occupation);
    _selectedActivityLevel = data.activityLevel;
    _healthConditionsController = TextEditingController(text: data.healthConditions.join(', '));
    _medicalAllergiesController = TextEditingController(text: data.medicalAllergies.join(', '));
    _dietaryPreferencesRestrictionsController = TextEditingController(text: data.dietaryPreferencesRestrictions.join(', '));
    _sleepPatternDescriptionController = TextEditingController(text: data.sleepPatternDescription);
    _stressLevelDescriptionController = TextEditingController(text: data.stressLevelDescription);
    _longTermGoalsDescriptionController = TextEditingController(text: data.longTermGoalsDescription);
    _selectedBodyShape = data.bodyShape;

    // Add listeners to text controllers to detect changes
    _ageController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _initialWeightController.addListener(_onFieldChanged);
    _currentWeightController.addListener(_onFieldChanged);
    _targetWeightController.addListener(_onFieldChanged);
    _targetDateController.addListener(_onFieldChanged);
    _weeklyWeightLossTargetController.addListener(_onFieldChanged);
    _occupationController.addListener(_onFieldChanged);
    _healthConditionsController.addListener(_onFieldChanged);
    _medicalAllergiesController.addListener(_onFieldChanged);
    _dietaryPreferencesRestrictionsController.addListener(_onFieldChanged);
    _sleepPatternDescriptionController.addListener(_onFieldChanged);
    _stressLevelDescriptionController.addListener(_onFieldChanged);
    _longTermGoalsDescriptionController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _targetDateController.dispose();
    _weeklyWeightLossTargetController.dispose();
    _occupationController.dispose();
    _healthConditionsController.dispose();
    _medicalAllergiesController.dispose();
    _dietaryPreferencesRestrictionsController.dispose();
    _sleepPatternDescriptionController.dispose();
    _stressLevelDescriptionController.dispose();
    _longTermGoalsDescriptionController.dispose();
    super.dispose();
  }

  // Generic method to set editing state when any field changes
  void _onFieldChanged() {
    // Only set editing state if there's an actual change from initial data
    final currentData = _getCurrentUserProfileFromControllers();
    final isChanged = _isUserProfileChanged(_initialUserProfile, currentData);
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = isChanged;
  }


  // Helper to get current UserProfile from controllers
  UserProfile _getCurrentUserProfileFromControllers() {
    return UserProfile(
      age: int.tryParse(_ageController.text) ?? 0,
      gender: _selectedGender,
      heightCm: double.tryParse(_heightController.text) ?? 0.0,
      initialWeightKg: double.tryParse(_initialWeightController.text) ?? 0.0,
      currentWeightKg: double.tryParse(_currentWeightController.text) ?? 0.0,
      targetWeightKg: double.tryParse(_targetWeightController.text) ?? 0.0,
      targetDate: _targetDateController.text,
      weeklyWeightLossTargetKg: double.tryParse(_weeklyWeightLossTargetController.text) ?? 0.0,
      weightLossPhase: _selectedWeightLossPhase,
      occupation: _occupationController.text,
      activityLevel: _selectedActivityLevel,
      healthConditions: _healthConditionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      medicalAllergies: _medicalAllergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      dietaryPreferencesRestrictions: _dietaryPreferencesRestrictionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      sleepPatternDescription: _sleepPatternDescriptionController.text,
      stressLevelDescription: _stressLevelDescriptionController.text,
      longTermGoalsDescription: _longTermGoalsDescriptionController.text,
      startDate: AppModelsManager.userProfile?.startDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()), // Keep original start date or default
      bodyShape: _selectedBodyShape,
      weightHistory: AppModelsManager.userProfile?.weightHistory ?? [], // Keep original history
    );
  }

  // Helper to compare UserProfile objects for changes
  bool _isUserProfileChanged(UserProfile? oldProfile, UserProfile newProfile) {
    if (oldProfile == null) return true; // If no old profile, any new one is a change

    // Compare all relevant fields
    return oldProfile.age != newProfile.age ||
        oldProfile.gender != newProfile.gender ||
        oldProfile.heightCm != newProfile.heightCm ||
        oldProfile.initialWeightKg != newProfile.initialWeightKg ||
        oldProfile.currentWeightKg != newProfile.currentWeightKg ||
        oldProfile.targetWeightKg != newProfile.targetWeightKg ||
        oldProfile.targetDate != newProfile.targetDate ||
        oldProfile.weeklyWeightLossTargetKg != newProfile.weeklyWeightLossTargetKg ||
        oldProfile.weightLossPhase != newProfile.weightLossPhase ||
        oldProfile.occupation != newProfile.occupation ||
        oldProfile.activityLevel != newProfile.activityLevel ||
        !_listEquals(oldProfile.healthConditions, newProfile.healthConditions) ||
        !_listEquals(oldProfile.medicalAllergies, newProfile.medicalAllergies) ||
        !_listEquals(oldProfile.dietaryPreferencesRestrictions, newProfile.dietaryPreferencesRestrictions) ||
        oldProfile.sleepPatternDescription != newProfile.sleepPatternDescription ||
        oldProfile.stressLevelDescription != newProfile.stressLevelDescription ||
        oldProfile.longTermGoalsDescription != newProfile.longTermGoalsDescription ||
        oldProfile.bodyShape != newProfile.bodyShape;
  }

  // Helper for list comparison
  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _targetDateController.text = DateFormat('yyyy-MM-dd').format(picked);
        _onFieldChanged(); // Manually trigger change detection for date picker
      });
    }
  }

  // Save changes to AppModelsManager and local storage
  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = UserProfile(
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        heightCm: double.parse(_heightController.text),
        initialWeightKg: double.parse(_initialWeightController.text),
        currentWeightKg: double.parse(_currentWeightController.text),
        targetWeightKg: double.parse(_targetWeightController.text),
        targetDate: _targetDateController.text,
        weeklyWeightLossTargetKg: double.parse(_weeklyWeightLossTargetController.text),
        weightLossPhase: _selectedWeightLossPhase,
        occupation: _occupationController.text,
        activityLevel: _selectedActivityLevel,
        healthConditions: _healthConditionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        medicalAllergies: _medicalAllergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        dietaryPreferencesRestrictions: _dietaryPreferencesRestrictionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        sleepPatternDescription: _sleepPatternDescriptionController.text,
        stressLevelDescription: _stressLevelDescriptionController.text,
        longTermGoalsDescription: _longTermGoalsDescriptionController.text,
        startDate: AppModelsManager.userProfile?.startDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        bodyShape: _selectedBodyShape,
        weightHistory: AppModelsManager.userProfile?.weightHistory ?? [], // Keep existing history
      );

      // Add current weight to history if it's a new day or different from last entry
      if (updatedProfile.weightHistory.isEmpty ||
          updatedProfile.weightHistory.last.date != DateFormat('yyyy-MM-dd').format(DateTime.now()) ||
          updatedProfile.weightHistory.last.weightKg != updatedProfile.currentWeightKg) {
        updatedProfile.weightHistory.add(WeightEntry(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          weightKg: updatedProfile.currentWeightKg,
        ));
      }

      AppModelsManager.userProfile = updatedProfile;
      await AppModelsManager.saveData();
      _initialUserProfile = updatedProfile; // Update initial state
      Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('个人资料已保存！')),
      );
    }
  }

  // Cancel changes and revert to initial data
  void _cancelChanges() {
    // Reload initial data to revert changes
    _loadUserProfileData();
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消更改。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the editing state from the provider
    final isEditing = Provider.of<EditingStateProvider>(context).isEditing;

    // Use a FutureBuilder to ensure data is loaded before building the UI
    return FutureBuilder(
      future: AppModelsManager.userProfile != null ? Future.value(AppModelsManager.userProfile) : AppModelsManager.loadData().then((_) => AppModelsManager.userProfile),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading user data: ${snapshot.error}'));
        } else {
          // Data is loaded, ensure controllers are up-to-date if not already
          if (_ageController.text.isEmpty && AppModelsManager.userProfile != null) {
            _loadUserProfileData(); // Re-initialize if data was null initially
          }

          final userProfile = AppModelsManager.userProfile!; // Guaranteed to be not null here

          // Calculate progress percentage
          double progress = 0.0;
          if (userProfile.initialWeightKg != userProfile.targetWeightKg) {
            progress = (userProfile.initialWeightKg - userProfile.currentWeightKg) /
                (userProfile.initialWeightKg - userProfile.targetWeightKg);
            progress = progress.clamp(0.0, 1.0); // Clamp between 0 and 1
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Age, Gender, Profession (Occupation)
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: _ageController, labelText: 'Age', keyboardType: TextInputType.number)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDropdownField(value: _selectedGender, options: _genderOptions, labelText: 'Gender', onChanged: (value) { setState(() => _selectedGender = value!); _onFieldChanged(); })),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(controller: _occupationController, labelText: 'Profession')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Height, Current Weight, Target Weight
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: _heightController, labelText: 'Height (cm)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(controller: _currentWeightController, labelText: 'Weight (kg)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(controller: _targetWeightController, labelText: 'Target (kg)', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progress Bar
                      Text('Progress', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      const SizedBox(height: 8),
                      Text('${(progress * 100).toInt()}%', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),

                      // Target Date
                      Text('Target Date', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _targetDateController,
                            labelText: 'Select Date',
                            validator: (value) => value == null || value.isEmpty ? 'Please select target date' : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Weight History Line Graph
                      Text('Weight History', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < userProfile.weightHistory.length) {
                                      final date = DateTime.parse(userProfile.weightHistory[value.toInt()].date);
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5, // Adjust interval as needed
                                  getTitlesWidget: (value, meta) {
                                    return Text('${value.toInt()}kg', style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: const Color(0xff37434d), width: 1),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: userProfile.weightHistory.asMap().entries.map((entry) {
                                  return FlSpot(entry.key.toDouble(), entry.value.weightKg);
                                }).toList(),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(show: false),
                              ),
                            ],
                            minX: 0,
                            maxX: (userProfile.weightHistory.length - 1).toDouble().clamp(0, double.infinity),
                            minY: userProfile.weightHistory.isNotEmpty
                                ? userProfile.weightHistory.map((e) => e.weightKg).reduce(min) - 5
                                : 0,
                            maxY: userProfile.weightHistory.isNotEmpty
                                ? userProfile.weightHistory.map((e) => e.weightKg).reduce(max) + 5
                                : 100,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Space for buttons
                    ],
                  ),
                ),
              ),
              // Confirm/Cancel buttons
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
                            onPressed: _cancelChanges,
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
                            onPressed: _saveChanges,
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

  // Reusable text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: (value) => _onFieldChanged(), // Trigger change detection
    );
  }

  // Reusable dropdown field widget
  Widget _buildDropdownField<T>({
    required T value,
    required List<T> options,
    required String labelText,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: (newValue) {
        onChanged(newValue);
        _onFieldChanged(); // Trigger change detection
      },
      validator: (value) => value == null ? 'Please select an option' : null,
    );
  }
}

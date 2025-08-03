
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progressai/weight_manage/user_data.dart';

class UserProfileForm extends StatefulWidget {
  final UserProfile? initialData; // Optional: for editing existing profile

  const UserProfileForm({super.key, this.initialData});

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _ageController;
  late String _selectedGender;
  late TextEditingController _heightController;
  late TextEditingController _initialWeightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _targetWeightController; // New controller
  late TextEditingController _targetDateController; // New controller
  late TextEditingController _weeklyWeightLossTargetController; // New controller
  late String _selectedWeightLossPhase; // New controller
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
  final List<String> _weightLossPhaseOptions = [ // New options
    "Initial Phase",
    "Rapid Weight Loss",
    "Plateau",
    "Maintenance",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    _ageController = TextEditingController(text: data?.age.toString() ?? '');
    _selectedGender = data?.gender ?? _genderOptions.first;
    _heightController = TextEditingController(text: data?.heightCm.toString() ?? '');
    _initialWeightController = TextEditingController(text: data?.initialWeightKg.toString() ?? '');
    _currentWeightController = TextEditingController(text: data?.currentWeightKg.toString() ?? '');
    _targetWeightController = TextEditingController(text: data?.targetWeightKg.toString() ?? ''); // Init new field
    _targetDateController = TextEditingController(text: data?.targetDate ?? ''); // Init new field
    _weeklyWeightLossTargetController = TextEditingController(text: data?.weeklyWeightLossTargetKg.toString() ?? ''); // Init new field
    _selectedWeightLossPhase = data?.weightLossPhase ?? _weightLossPhaseOptions.first; // Init new field
    _occupationController = TextEditingController(text: data?.occupation ?? '');
    _selectedActivityLevel = data?.activityLevel ?? _activityLevelOptions.first;
    _healthConditionsController = TextEditingController(text: data?.healthConditions.join(', ') ?? '');
    _medicalAllergiesController = TextEditingController(text: data?.medicalAllergies.join(', ') ?? '');
    _dietaryPreferencesRestrictionsController = TextEditingController(text: data?.dietaryPreferencesRestrictions.join(', ') ?? '');
    _sleepPatternDescriptionController = TextEditingController(text: data?.sleepPatternDescription ?? '');
    _stressLevelDescriptionController = TextEditingController(text: data?.stressLevelDescription ?? '');
    _longTermGoalsDescriptionController = TextEditingController(text: data?.longTermGoalsDescription ?? '');
    _selectedBodyShape = data?.bodyShape ?? _bodyShapeOptions.first;
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _initialWeightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose(); // Dispose new controller
    _targetDateController.dispose(); // Dispose new controller
    _weeklyWeightLossTargetController.dispose(); // Dispose new controller
    _occupationController.dispose();
    _healthConditionsController.dispose();
    _medicalAllergiesController.dispose();
    _dietaryPreferencesRestrictionsController.dispose();
    _sleepPatternDescriptionController.dispose();
    _stressLevelDescriptionController.dispose();
    _longTermGoalsDescriptionController.dispose();
    super.dispose();
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('基本信息', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildTextField(
                controller: _ageController,
                labelText: '年龄',
                keyboardType: TextInputType.number,
                validator: (value) => value == null || int.tryParse(value) == null ? '请输入有效年龄' : null,
              ),
              _buildDropdownField(
                value: _selectedGender,
                options: _genderOptions,
                labelText: '性别',
                onChanged: (value) => setState(() => _selectedGender = value!),
              ),
              _buildTextField(
                controller: _heightController,
                labelText: '身高 (厘米)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || double.tryParse(value) == null ? '请输入有效身高' : null,
              ),
              _buildTextField(
                controller: _initialWeightController,
                labelText: '初始体重 (公斤)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || double.tryParse(value) == null ? '请输入有效初始体重' : null,
              ),
              _buildTextField(
                controller: _currentWeightController,
                labelText: '当前体重 (公斤)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || double.tryParse(value) == null ? '请输入有效当前体重' : null,
              ),
              // New fields start here
              _buildTextField(
                controller: _targetWeightController,
                labelText: '目标体重 (公斤)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || double.tryParse(value) == null ? '请输入有效目标体重' : null,
              ),
              GestureDetector( // For date picker
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _targetDateController,
                    labelText: '目标达成日期',
                    validator: (value) => value == null || value.isEmpty ? '请选择目标达成日期' : null,
                  ),
                ),
              ),
              _buildTextField(
                controller: _weeklyWeightLossTargetController,
                labelText: '每周目标减重 (公斤)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) => value == null || double.tryParse(value) == null ? '请输入有效减重目标' : null,
              ),
              _buildDropdownField(
                value: _selectedWeightLossPhase,
                options: _weightLossPhaseOptions,
                labelText: '减肥阶段',
                onChanged: (value) => setState(() => _selectedWeightLossPhase = value!),
              ),
              // New fields end here
              _buildTextField(
                controller: _occupationController,
                labelText: '职业',
                validator: (value) => value == null || value.isEmpty ? '请输入职业' : null,
              ),
              _buildDropdownField(
                value: _selectedActivityLevel,
                options: _activityLevelOptions,
                labelText: '活动水平',
                onChanged: (value) => setState(() => _selectedActivityLevel = value!),
              ),
              _buildTextField(
                controller: _healthConditionsController,
                labelText: '健康状况 (逗号分隔)',
              ),
              _buildTextField(
                controller: _medicalAllergiesController,
                labelText: '药物过敏史 (逗号分隔)',
              ),
              _buildTextField(
                controller: _dietaryPreferencesRestrictionsController,
                labelText: '饮食偏好/限制 (逗号分隔)',
              ),
              _buildTextField(
                controller: _sleepPatternDescriptionController,
                labelText: '睡眠习惯描述',
                maxLines: 3,
              ),
              _buildTextField(
                controller: _stressLevelDescriptionController,
                labelText: '压力水平描述',
                maxLines: 3,
              ),
              _buildTextField(
                controller: _longTermGoalsDescriptionController,
                labelText: '长期目标描述',
                maxLines: 3,
              ),
              _buildDropdownField(
                value: _selectedBodyShape,
                options: _bodyShapeOptions,
                labelText: '体型',
                onChanged: (value) => setState(() => _selectedBodyShape = value!),
              ),
            ].map((widget) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: widget,
            )).toList(),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog without saving
          },
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final userProfile = UserProfile(
                age: int.parse(_ageController.text),
                gender: _selectedGender,
                heightCm: double.parse(_heightController.text),
                initialWeightKg: double.parse(_initialWeightController.text),
                currentWeightKg: double.parse(_currentWeightController.text),
                targetWeightKg: double.parse(_targetWeightController.text), // New field
                targetDate: _targetDateController.text, // New field
                weeklyWeightLossTargetKg: double.parse(_weeklyWeightLossTargetController.text), // New field
                weightLossPhase: _selectedWeightLossPhase, // New field
                occupation: _occupationController.text,
                activityLevel: _selectedActivityLevel,
                healthConditions: _healthConditionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                // medicalAllergies: _medicalAlliesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  medicalAllergies: [],
                dietaryPreferencesRestrictions: _dietaryPreferencesRestrictionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                sleepPatternDescription: _sleepPatternDescriptionController.text,
                stressLevelDescription: _stressLevelDescriptionController.text,
                longTermGoalsDescription: _longTermGoalsDescriptionController.text,
                startDate: DateFormat('yyyy-MM-dd').format(DateTime.now()), // Auto-fill current date
                bodyShape: _selectedBodyShape,
                // For demonstration, adding a sample weight entry. In a real app, this would come from user input.
                weightHistory: [
                  WeightEntry(date: DateFormat('yyyy-MM-dd').format(DateTime.now()), weightKg: double.parse(_currentWeightController.text)),
                ],
              );
              Navigator.of(context).pop(userProfile); // Return data
            }
          },
          child: const Text('确认'),
        ),
      ],
    );
  }

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
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

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
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: options.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? '请选择一个选项' : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // For state management
import 'package:fl_chart/fl_chart.dart';

import '../../main.dart'; // 确保导入了 main.dart 以访问 EditingStateProvider
import '../user_data.dart';

class NutritionistScreen extends StatefulWidget {
  const NutritionistScreen({super.key});

  @override
  State<NutritionistScreen> createState() => _NutritionistScreenState();
}

class _NutritionistScreenState extends State<NutritionistScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for fixed nutritional data
  late TextEditingController _dailyEatingPatternController;
  late TextEditingController _cookingPreferenceController;
  late TextEditingController _dislikedFoodsController;
  late TextEditingController _foodAllergiesController;
  late TextEditingController _eatingOutFrequencyController;
  late TextEditingController _alcoholConsumptionController;
  late TextEditingController _caffeineIntakeController;
  late TextEditingController _possibleNutrientDeficienciesController;
  late TextEditingController _recommendedSupplementsController;
  late TextEditingController _digestiveHealthOverviewController;

  // Controllers for adding daily data
  late TextEditingController _mealCategoryController;
  late TextEditingController _imageUrlController;
  late TextEditingController _foodNutritionSummaryController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _energyController;
  late TextEditingController _carbController;
  late TextEditingController _otherMetricsController;

  Nutritionist? _initialNutritionistData; // To track changes for fixed info
  Future<Nutritionist?>? _nutritionistFuture; // Future to hold the nutritionist data

  @override
  void initState() {
    super.initState();
    _loadNutritionistData();
  }

  void _loadNutritionistData() {
    // Set the future that FutureBuilder will listen to
    _nutritionistFuture = AppModelsManager.loadData().then((_) {
      final nutritionistData = AppModelsManager.nutritionist ?? Nutritionist.defaultNutritionist();
      _initialNutritionistData = nutritionistData; // Save initial state

      _dailyEatingPatternController = TextEditingController(text: nutritionistData.dailyEatingPattern);
      _cookingPreferenceController = TextEditingController(text: nutritionistData.cookingPreference);
      _dislikedFoodsController = TextEditingController(text: nutritionistData.dislikedFoods.join(', '));
      _foodAllergiesController = TextEditingController(text: nutritionistData.foodAllergies.join(', '));
      _eatingOutFrequencyController = TextEditingController(text: nutritionistData.eatingOutFrequency);
      _alcoholConsumptionController = TextEditingController(text: nutritionistData.alcoholConsumption);
      _caffeineIntakeController = TextEditingController(text: nutritionistData.caffeineIntake);
      _possibleNutrientDeficienciesController = TextEditingController(text: nutritionistData.possibleNutrientDeficiencies.join(', '));
      _recommendedSupplementsController = TextEditingController(text: nutritionistData.recommendedSupplements.join(', '));
      _digestiveHealthOverviewController = TextEditingController(text: nutritionistData.digestiveHealthOverview);

      // Add listeners for fixed nutritional info fields
      _dailyEatingPatternController.addListener(_onFixedFieldChanged);
      _cookingPreferenceController.addListener(_onFixedFieldChanged);
      _dislikedFoodsController.addListener(_onFixedFieldChanged);
      _foodAllergiesController.addListener(_onFixedFieldChanged);
      _eatingOutFrequencyController.addListener(_onFixedFieldChanged);
      _alcoholConsumptionController.addListener(_onFixedFieldChanged);
      _caffeineIntakeController.addListener(_onFixedFieldChanged);
      _possibleNutrientDeficienciesController.addListener(_onFixedFieldChanged);
      _recommendedSupplementsController.addListener(_onFixedFieldChanged);
      _digestiveHealthOverviewController.addListener(_onFixedFieldChanged);

      // Initialize daily data controllers (will be reset for each new entry)
      _mealCategoryController = TextEditingController();
      _imageUrlController = TextEditingController();
      _foodNutritionSummaryController = TextEditingController();
      _proteinController = TextEditingController();
      _fatController = TextEditingController();
      _energyController = TextEditingController();
      _carbController = TextEditingController();
      _otherMetricsController = TextEditingController();

      return nutritionistData; // Return the loaded data
    });
  }

  @override
  void dispose() {
    _dailyEatingPatternController.dispose();
    _cookingPreferenceController.dispose();
    _dislikedFoodsController.dispose();
    _foodAllergiesController.dispose();
    _eatingOutFrequencyController.dispose();
    _alcoholConsumptionController.dispose();
    _caffeineIntakeController.dispose();
    _possibleNutrientDeficienciesController.dispose();
    _recommendedSupplementsController.dispose();
    _digestiveHealthOverviewController.dispose();

    _mealCategoryController.dispose();
    _imageUrlController.dispose();
    _foodNutritionSummaryController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _energyController.dispose();
    _carbController.dispose();
    _otherMetricsController.dispose();
    super.dispose();
  }

  // Check if fixed nutritional info has changed
  void _onFixedFieldChanged() {
    final currentData = _getCurrentFixedNutritionistDataFromControllers();
    final isChanged = _isNutritionistFixedDataChanged(_initialNutritionistData, currentData);
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = isChanged;
  }

  Nutritionist _getCurrentFixedNutritionistDataFromControllers() {
    return Nutritionist(
      dailyEatingPattern: _dailyEatingPatternController.text,
      cookingPreference: _cookingPreferenceController.text,
      dislikedFoods: _dislikedFoodsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      foodAllergies: _foodAllergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      eatingOutFrequency: _eatingOutFrequencyController.text,
      alcoholConsumption: _alcoholConsumptionController.text,
      caffeineIntake: _caffeineIntakeController.text,
      possibleNutrientDeficiencies: _possibleNutrientDeficienciesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      recommendedSupplements: _recommendedSupplementsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      digestiveHealthOverview: _digestiveHealthOverviewController.text,
      dailyDataHistory: AppModelsManager.nutritionist?.dailyDataHistory ?? [], // Preserve daily history
    );
  }

  bool _isNutritionistFixedDataChanged(Nutritionist? oldData, Nutritionist newData) {
    if (oldData == null) return true;

    return oldData.dailyEatingPattern != newData.dailyEatingPattern ||
        oldData.cookingPreference != newData.cookingPreference ||
        !_listEquals(oldData.dislikedFoods, newData.dislikedFoods) ||
        !_listEquals(oldData.foodAllergies, newData.foodAllergies) ||
        oldData.eatingOutFrequency != newData.eatingOutFrequency ||
        oldData.alcoholConsumption != newData.alcoholConsumption ||
        oldData.caffeineIntake != newData.caffeineIntake ||
        !_listEquals(oldData.possibleNutrientDeficiencies, newData.possibleNutrientDeficiencies) ||
        !_listEquals(oldData.recommendedSupplements, newData.recommendedSupplements) ||
        oldData.digestiveHealthOverview != newData.digestiveHealthOverview;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Save changes to AppModelsManager and local storage for fixed nutritional info
  void _saveFixedChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedNutritionist = _getCurrentFixedNutritionistDataFromControllers();
      AppModelsManager.nutritionist = updatedNutritionist;
      await AppModelsManager.saveData();
      _initialNutritionistData = updatedNutritionist; // Update initial state
      Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('营养信息已保存！')),
      );
      // Reload data to ensure FutureBuilder rebuilds
      setState(() {
        _loadNutritionistData();
      });
    }
  }

  // Cancel changes and revert to initial data for fixed nutritional info
  void _cancelFixedChanges() {
    _loadNutritionistData(); // Revert all controllers to initial state
    Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消更改。')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadNutritionistData();
    });
  }

  // Show dialog to add new daily data
  void _showAddDailyDataDialog() {
    // Reset controllers for new entry
    _mealCategoryController.clear();
    _imageUrlController.clear();
    _foodNutritionSummaryController.clear();
    _proteinController.clear();
    _fatController.clear();
    _energyController.clear();
    _carbController.clear();
    _otherMetricsController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Daily Diet Record'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Reusing form key for dialog
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(controller: _mealCategoryController, labelText: 'Meal Category (e.g., Breakfast, Lunch)'),
                  _buildTextField(controller: _imageUrlController, labelText: 'Food Image URL (Optional)'),
                  _buildTextField(controller: _foodNutritionSummaryController, labelText: 'Nutrition Summary', maxLines: 2),
                  const SizedBox(height: 16),
                  Text('Food Metrics (grams/kcal)', style: Theme.of(context).textTheme.titleSmall),
                  _buildTextField(controller: _proteinController, labelText: 'Protein', keyboardType: TextInputType.number),
                  _buildTextField(controller: _fatController, labelText: 'Fat', keyboardType: TextInputType.number),
                  _buildTextField(controller: _energyController, labelText: 'Energy (kcal)', keyboardType: TextInputType.number),
                  _buildTextField(controller: _carbController, labelText: 'Carbohydrates', keyboardType: TextInputType.number),
                  _buildTextField(controller: _otherMetricsController, labelText: 'Other Metrics (Optional)', keyboardType: TextInputType.number),
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
                setState(() { // <--- Add setState and reload data here
                  _loadNutritionistData();
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newDailyData = NutritionistDailyData(
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    mealCategory: _mealCategoryController.text,
                    imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : '',
                    foodNutritionSummary: _foodNutritionSummaryController.text.isNotEmpty ? _foodNutritionSummaryController.text : null,
                    foodMetricsData: {
                      "蛋白质": double.tryParse(_proteinController.text) ?? 0.0,
                      "脂肪": double.tryParse(_fatController.text) ?? 0.0,
                      "能量": double.tryParse(_energyController.text) ?? 0.0,
                      "碳水": double.tryParse(_carbController.text) ?? 0.0,
                      "其他": double.tryParse(_otherMetricsController.text) ?? 0.0,
                    },
                  );

                  setState(() {
                    AppModelsManager.nutritionist?.dailyDataHistory.add(newDailyData);
                    // Sort history by date in descending order
                    AppModelsManager.nutritionist?.dailyDataHistory.sort((a, b) => b.date.compareTo(a.date));
                  });
                  await AppModelsManager.saveData();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('每日饮食记录已添加！')),
                  );
                  // Reload data to ensure FutureBuilder rebuilds
                  setState(() {
                    _loadNutritionistData();
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
      AppModelsManager.nutritionist?.dailyDataHistory.removeAt(index);
    });
    await AppModelsManager.saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('每日饮食记录已删除！')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadNutritionistData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = Provider.of<EditingStateProvider>(context).isEditing;

    return  FutureBuilder<Nutritionist?>(
        future: _nutritionistFuture, // Use the state variable future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading nutritionist data: ${snapshot.error}'));
          } else {
            final nutritionist = snapshot.data!; // Use snapshot.data directly

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
                          'Fixed Nutritional Information',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: 'Dietary Habits & Preferences',
                          children: [
                            _buildTextField(controller: _dailyEatingPatternController, labelText: 'Daily Eating Pattern'),
                            _buildTextField(controller: _cookingPreferenceController, labelText: 'Cooking Preference'),
                            _buildTextField(controller: _dislikedFoodsController, labelText: 'Disliked Foods (comma-separated)'),
                            _buildTextField(controller: _foodAllergiesController, labelText: 'Food Allergies (comma-separated)'),
                            _buildTextField(controller: _eatingOutFrequencyController, labelText: 'Eating Out Frequency'),
                            _buildTextField(controller: _alcoholConsumptionController, labelText: 'Alcohol Consumption'),
                            _buildTextField(controller: _caffeineIntakeController, labelText: 'Caffeine Intake'),
                            _buildTextField(controller: _possibleNutrientDeficienciesController, labelText: 'Possible Nutrient Deficiencies (comma-separated)'),
                            _buildTextField(controller: _recommendedSupplementsController, labelText: 'Recommended Supplements (comma-separated)'),
                            _buildTextField(controller: _digestiveHealthOverviewController, labelText: 'Digestive Health Overview'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Daily Diet Records',
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
                        if (nutritionist.dailyDataHistory.isEmpty)
                          const Center(child: Text('No daily diet data recorded yet.'))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: nutritionist.dailyDataHistory.length,
                            itemBuilder: (context, index) {
                              final data = nutritionist.dailyDataHistory[index];
                              return _buildDailyDataCard(context, data, index); // Pass index for deletion
                            },
                          ),
                        const SizedBox(height: 80), // Space for buttons
                      ],
                    ),
                  ),
                ),
                // Confirm/Cancel buttons for fixed nutritional info
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
  Widget _buildDailyDataCard(BuildContext context, NutritionistDailyData data, int index) {
    // Colors for the pie chart sections
    final List<Color> pieColors = [
      Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.grey
    ];

    // Prepare PieChartSectionData
    List<PieChartSectionData> showingSections(Map<String, double> metrics) {
      double total = metrics.values.fold(0.0, (sum, item) => sum + item);
      int colorIndex = 0;

      return metrics.entries.map((entry) {
        final double percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
        final color = pieColors[colorIndex % pieColors.length];
        colorIndex++; // Increment for next color

        return PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
          radius: 50, // Fixed radius for sections
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xffffffff),
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
          badgeWidget: null,
        );
      }).toList();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.orange[50],
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
            Text('Meal Category: ${data.mealCategory}', style: const TextStyle(fontSize: 14)),
            if (data.foodNutritionSummary != null && data.foodNutritionSummary!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Summary: ${data.foodNutritionSummary}'),
              ),
            const Divider(height: 10, thickness: 0.5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Card: Food Image
                Expanded(
                  flex: 1,
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text('Food Image', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          data.imageUrl != null && data.imageUrl!.isNotEmpty
                              ? Image.network(
                            data.imageUrl!,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          )
                              : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Right Card: Food Metrics Pie Chart
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text('Food Metrics', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150, // Adjust height as needed for the pie chart
                            child: PieChart(
                              PieChartData(
                                sections: showingSections(data.foodMetricsData),
                                // centerSliceRadius: 40,
                                sectionsSpace: 2,
                                pieTouchData: PieTouchData(enabled: false), // Disable touch for simplicity
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: data.foodMetricsData.entries.map((entry) {
                              final int colorIndex = data.foodMetricsData.keys.toList().indexOf(entry.key);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    color: pieColors[colorIndex % pieColors.length],
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${entry.key}: ${entry.value.toStringAsFixed(1)}'),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

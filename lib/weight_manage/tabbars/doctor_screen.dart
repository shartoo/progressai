import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // For state management
import '../../main.dart';
import '../user_data.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for adding/editing daily data
  late TextEditingController _bloodGlucoseController;
  late TextEditingController _bloodPressureController;
  late TextEditingController _bodyStatusController;
  late TextEditingController _sleepQualityController;
  late TextEditingController _waterIntakeMlController;
  late TextEditingController _bowelMovementStatusController;
  late TextEditingController _medicationAdherenceController;
  late TextEditingController _symptomsController;

  // For fixed medical conditions
  late TextEditingController _allergyMedicationsController;
  late TextEditingController _currentMedicationsController;
  late TextEditingController _existingMedicalConditionsController;
  late TextEditingController _bloodLipidTotalCholesterolController;
  late TextEditingController _bloodLipidLDLController;
  late TextEditingController _bloodLipidHDLController;
  late TextEditingController _bloodLipidTriglyceridesController;
  late TextEditingController _thyroidFunctionController;
  late TextEditingController _liverKidneyFunctionController;

  Doctor? _initialDoctorData; // To track changes for fixed medical info
  Future<Doctor?>? _doctorFuture; // Future to hold the doctor data

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  void _loadDoctorData() {
    // Set the future that FutureBuilder will listen to
    _doctorFuture = AppModelsManager.loadData().then((_) {
      final doctorData = AppModelsManager.doctor ?? Doctor.defaultDoctor();
      _initialDoctorData = doctorData; // Save initial state

      _allergyMedicationsController = TextEditingController(text: doctorData.allergyMedications.join(', '));
      _currentMedicationsController = TextEditingController(text: doctorData.currentMedications.join(', '));
      _existingMedicalConditionsController = TextEditingController(text: doctorData.existingMedicalConditions.join(', '));
      _bloodLipidTotalCholesterolController = TextEditingController(text: doctorData.bloodLipidProfile?['总胆固醇']?.toString() ?? '');
      _bloodLipidLDLController = TextEditingController(text: doctorData.bloodLipidProfile?['低密度脂蛋白']?.toString() ?? '');
      _bloodLipidHDLController = TextEditingController(text: doctorData.bloodLipidProfile?['高密度脂蛋白']?.toString() ?? '');
      _bloodLipidTriglyceridesController = TextEditingController(text: doctorData.bloodLipidProfile?['甘油三酯']?.toString() ?? '');
      _thyroidFunctionController = TextEditingController(text: doctorData.thyroidFunction ?? '');
      _liverKidneyFunctionController = TextEditingController(text: doctorData.liverKidneyFunction ?? '');

      // Add listeners for fixed medical info fields
      _allergyMedicationsController.addListener(_onFixedFieldChanged);
      _currentMedicationsController.addListener(_onFixedFieldChanged);
      _existingMedicalConditionsController.addListener(_onFixedFieldChanged);
      _bloodLipidTotalCholesterolController.addListener(_onFixedFieldChanged);
      _bloodLipidLDLController.addListener(_onFixedFieldChanged);
      _bloodLipidHDLController.addListener(_onFixedFieldChanged);
      _bloodLipidTriglyceridesController.addListener(_onFixedFieldChanged);
      _thyroidFunctionController.addListener(_onFixedFieldChanged);
      _liverKidneyFunctionController.addListener(_onFixedFieldChanged);

      // Initialize daily data controllers (will be reset for each new entry)
      _bloodGlucoseController = TextEditingController();
      _bloodPressureController = TextEditingController();
      _bodyStatusController = TextEditingController();
      _sleepQualityController = TextEditingController();
      _waterIntakeMlController = TextEditingController();
      _bowelMovementStatusController = TextEditingController();
      _medicationAdherenceController = TextEditingController();
      _symptomsController = TextEditingController();

      return doctorData; // Return the loaded data
    });
  }

  @override
  void dispose() {
    _bloodGlucoseController.dispose();
    _bloodPressureController.dispose();
    _bodyStatusController.dispose();
    _sleepQualityController.dispose();
    _waterIntakeMlController.dispose();
    _bowelMovementStatusController.dispose();
    _medicationAdherenceController.dispose();
    _symptomsController.dispose();

    _allergyMedicationsController.dispose();
    _currentMedicationsController.dispose();
    _existingMedicalConditionsController.dispose();
    _bloodLipidTotalCholesterolController.dispose();
    _bloodLipidLDLController.dispose();
    _bloodLipidHDLController.dispose();
    _bloodLipidTriglyceridesController.dispose();
    _thyroidFunctionController.dispose();
    _liverKidneyFunctionController.dispose();
    super.dispose();
  }

  // Check if fixed medical info has changed
  void _onFixedFieldChanged() {
    final currentData = _getCurrentFixedDoctorDataFromControllers();
    final isChanged = _isDoctorFixedDataChanged(_initialDoctorData, currentData);
    // 使用 try-catch 块来捕获 Provider 查找错误
    try {
      Provider.of<EditingStateProvider>(context, listen: false).isEditing = isChanged;
      print('EditingStateProvider accessed successfully in _onFixedFieldChanged. isEditing: $isChanged');
    } catch (e) {
      print('Error accessing EditingStateProvider in _onFixedFieldChanged: $e');
    }
  }

  Doctor _getCurrentFixedDoctorDataFromControllers() {
    return Doctor(
      allergyMedications: _allergyMedicationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      currentMedications: _currentMedicationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      existingMedicalConditions: _existingMedicalConditionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      bloodLipidProfile: {
        "总胆固醇": double.tryParse(_bloodLipidTotalCholesterolController.text) ?? 0.0,
        "低密度脂蛋白": double.tryParse(_bloodLipidLDLController.text) ?? 0.0,
        "高密度脂蛋白": double.tryParse(_bloodLipidHDLController.text) ?? 0.0,
        "甘油三酯": double.tryParse(_bloodLipidTriglyceridesController.text) ?? 0.0,
      },
      thyroidFunction: _thyroidFunctionController.text,
      liverKidneyFunction: _liverKidneyFunctionController.text,
      dailyDataHistory: AppModelsManager.doctor?.dailyDataHistory ?? [], // Preserve daily history
    );
  }

  bool _isDoctorFixedDataChanged(Doctor? oldData, Doctor newData) {
    if (oldData == null) return true;

    return !_listEquals(oldData.allergyMedications, newData.allergyMedications) ||
        !_listEquals(oldData.currentMedications, newData.currentMedications) ||
        !_listEquals(oldData.existingMedicalConditions, newData.existingMedicalConditions) ||
        !_mapEquals(oldData.bloodLipidProfile, newData.bloodLipidProfile) ||
        oldData.thyroidFunction != newData.thyroidFunction ||
        oldData.liverKidneyFunction != newData.liverKidneyFunction;
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

  // Save changes to AppModelsManager and local storage for fixed medical info
  void _saveFixedChanges() async {
    if (_formKey.currentState!.validate()) {
      final updatedDoctor = _getCurrentFixedDoctorDataFromControllers();
      AppModelsManager.doctor = updatedDoctor;
      await AppModelsManager.saveData();
      _initialDoctorData = updatedDoctor; // Update initial state
      // 使用 try-catch 块来捕获 Provider 查找错误
      try {
        Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
        print('EditingStateProvider accessed successfully in _saveFixedChanges.');
      } catch (e) {
        print('Error accessing EditingStateProvider in _saveFixedChanges: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('医疗信息已保存！')),
      );
      // Reload data to ensure FutureBuilder rebuilds
      setState(() {
        _loadDoctorData();
      });
    }
  }

  // Cancel changes and revert to initial data for fixed medical info
  void _cancelFixedChanges() {
    _loadDoctorData(); // Revert all controllers to initial state
    // 使用 try-catch 块来捕获 Provider 查找错误
    try {
      Provider.of<EditingStateProvider>(context, listen: false).isEditing = false; // Hide buttons
      print('EditingStateProvider accessed successfully in _cancelFixedChanges.');
    } catch (e) {
      print('Error accessing EditingStateProvider in _cancelFixedChanges: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已取消更改。')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadDoctorData();
    });
  }

  // Show dialog to add new daily data
  void _showAddDailyDataDialog() {
    // Reset controllers for new entry
    _bloodGlucoseController.clear();
    _bloodPressureController.clear();
    _bodyStatusController.clear();
    _sleepQualityController.clear();
    _waterIntakeMlController.clear();
    _bowelMovementStatusController.clear();
    _medicationAdherenceController.clear();
    _symptomsController.clear();

    try { // Add try-catch around showDialog
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) { // 使用 dialogContext
          return AlertDialog(
            title: const Text('Add Daily Medical Data'),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey, // Reusing form key for dialog
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(controller: _bloodGlucoseController, labelText: 'Blood Glucose (mg/dL)', keyboardType: TextInputType.number),
                    _buildTextField(controller: _bloodPressureController, labelText: 'Blood Pressure (e.g., 120/80)'),
                    _buildTextField(controller: _bodyStatusController, labelText: 'Body Status'),
                    _buildTextField(controller: _sleepQualityController, labelText: 'Sleep Quality'),
                    _buildTextField(controller: _waterIntakeMlController, labelText: 'Water Intake (ml)', keyboardType: TextInputType.number),
                    _buildTextField(controller: _bowelMovementStatusController, labelText: 'Bowel Movement Status'),
                    _buildTextField(controller: _medicationAdherenceController, labelText: 'Medication Adherence'),
                    _buildTextField(controller: _symptomsController, labelText: 'Symptoms (comma-separated)'),
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
                  Navigator.of(dialogContext).pop(); // 使用 dialogContext
                  setState(() { // <--- Add setState and reload data here
                    _loadDoctorData();
                  });
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final newDailyData = DoctorDailyData(
                      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      bloodGlucose: double.tryParse(_bloodGlucoseController.text),
                      bloodPressure: _bloodPressureController.text.isNotEmpty ? _bloodPressureController.text : null,
                      bodyStatus: _bodyStatusController.text.isNotEmpty ? _bodyStatusController.text : null,
                      sleepQuality: _sleepQualityController.text.isNotEmpty ? _sleepQualityController.text : null,
                      waterIntakeMl: double.tryParse(_waterIntakeMlController.text),
                      bowelMovementStatus: _bowelMovementStatusController.text.isNotEmpty ? _bowelMovementStatusController.text : null,
                      medicationAdherence: _medicationAdherenceController.text.isNotEmpty ? _medicationAdherenceController.text : null,
                      symptoms: _symptomsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                    );

                    setState(() {
                      AppModelsManager.doctor?.dailyDataHistory.add(newDailyData);
                      // Sort history by date in descending order
                      AppModelsManager.doctor?.dailyDataHistory.sort((a, b) => b.date.compareTo(a.date));
                    });
                    await AppModelsManager.saveData();
                    Navigator.of(dialogContext).pop(); // 使用 dialogContext
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('每日数据已添加！')),
                    );
                    // Reload data to ensure FutureBuilder rebuilds
                    setState(() {
                      _loadDoctorData();
                    });
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error showing or interacting with Add Daily Data dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in dialog: $e')),
      );
    }
  }

  // Function to delete a daily data entry
  void _deleteDailyData(int index) async {
    setState(() {
      AppModelsManager.doctor?.dailyDataHistory.removeAt(index);
    });
    await AppModelsManager.saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('每日医疗记录已删除！')),
    );
    // Reload data to ensure FutureBuilder rebuilds
    setState(() {
      _loadDoctorData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = Provider.of<EditingStateProvider>(context).isEditing;

    return  FutureBuilder<Doctor?>(
        future: _doctorFuture, // Use the state variable future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading doctor data: ${snapshot.error}'));
          } else {
            final doctor = snapshot.data!; // Use snapshot.data directly

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
                          'Baseline Medical Information',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: 'General Medical History',
                          children: [
                            _buildTextField(controller: _allergyMedicationsController, labelText: 'Allergy Medications (comma-separated)'),
                            _buildTextField(controller: _currentMedicationsController, labelText: 'Current Medications (comma-separated)'),
                            _buildTextField(controller: _existingMedicalConditionsController, labelText: 'Existing Medical Conditions (comma-separated)'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: 'Blood Lipid Profile',
                          children: [
                            _buildTextField(controller: _bloodLipidTotalCholesterolController, labelText: 'Total Cholesterol', keyboardType: TextInputType.number),
                            _buildTextField(controller: _bloodLipidLDLController, labelText: 'LDL Cholesterol', keyboardType: TextInputType.number),
                            _buildTextField(controller: _bloodLipidHDLController, labelText: 'HDL Cholesterol', keyboardType: TextInputType.number),
                            _buildTextField(controller: _bloodLipidTriglyceridesController, labelText: 'Triglycerides', keyboardType: TextInputType.number),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSectionCard(
                          context,
                          title: 'Organ Function & Other',
                          children: [
                            _buildTextField(controller: _thyroidFunctionController, labelText: 'Thyroid Function'),
                            _buildTextField(controller: _liverKidneyFunctionController, labelText: 'Liver/Kidney Function'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded( // Wrap Text with Expanded
                              child: Text(
                                'Daily Medical Records',
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
                        if (doctor.dailyDataHistory.isEmpty)
                          const Center(child: Text('No daily medical data recorded yet.'))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: doctor.dailyDataHistory.length,
                            itemBuilder: (context, index) {
                              final data = doctor.dailyDataHistory[index];
                              return _buildDailyDataCard(context, data, index); // Pass index for deletion
                            },
                          ),
                        const SizedBox(height: 80), // Space for buttons
                      ],
                    ),
                  ),
                ),
                // Confirm/Cancel buttons for fixed medical info
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
  Widget _buildDailyDataCard(BuildContext context, DoctorDailyData data, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.blueGrey[50],
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
            _buildDataRow('Blood Glucose:', data.bloodGlucose != null ? '${data.bloodGlucose} mg/dL' : 'N/A'),
            _buildDataRow('Blood Pressure:', data.bloodPressure ?? 'N/A'),
            _buildDataRow('Body Status:', data.bodyStatus ?? 'N/A'),
            _buildDataRow('Sleep Quality:', data.sleepQuality ?? 'N/A'),
            _buildDataRow('Water Intake:', data.waterIntakeMl != null ? '${data.waterIntakeMl} ml' : 'N/A'),
            _buildDataRow('Bowel Movement:', data.bowelMovementStatus ?? 'N/A'),
            _buildDataRow('Medication Adherence:', data.medicationAdherence ?? 'N/A'),
            if (data.symptoms.isNotEmpty)
              _buildDataRow('Symptoms:', data.symptoms.join(', ')),
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
            width: 120, // Fixed width for labels
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

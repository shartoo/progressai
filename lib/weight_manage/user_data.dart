import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle; // For loading assets
import 'package:path_provider/path_provider.dart'; // For getting application documents directory
import 'package:intl/intl.dart'; // For date formatting

// Define the structure for user profile data
class UserProfile {
  int age;
  String gender;
  double heightCm;
  double initialWeightKg;
  double currentWeightKg;
  double targetWeightKg;
  String targetDate;
  double weeklyWeightLossTargetKg;
  double progressPercentage;
  String weightLossPhase;
  String occupation;
  String activityLevel;
  List<String> healthConditions;
  List<String> medicalAllergies;
  List<String> dietaryPreferencesRestrictions;
  String sleepPatternDescription;
  String stressLevelDescription;
  String longTermGoalsDescription;
  String startDate;
  String bodyShape;
  List<WeightEntry> weightHistory; // Added: Weight history list

  UserProfile({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.initialWeightKg,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.targetDate,
    required this.weeklyWeightLossTargetKg,
    this.progressPercentage = 0.0,
    required this.weightLossPhase,
    required this.occupation,
    required this.activityLevel,
    required this.healthConditions,
    required this.medicalAllergies,
    required this.dietaryPreferencesRestrictions,
    required this.sleepPatternDescription,
    required this.stressLevelDescription,
    required this.longTermGoalsDescription,
    required this.startDate,
    required this.bodyShape,
    this.weightHistory = const [], // Initialize as empty list
  });

  // Convert UserProfile object to a JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      "age": age,
      "gender": gender,
      "height_cm": heightCm,
      "initial_weight_kg": initialWeightKg,
      "current_weight_kg": currentWeightKg,
      "target_weight_kg": targetWeightKg,
      "target_date": targetDate,
      "weekly_weight_loss_target_kg": weeklyWeightLossTargetKg,
      "progress_percentage": progressPercentage,
      "weight_loss_phase": weightLossPhase,
      "occupation": occupation,
      "activity_level": activityLevel,
      "health_conditions": healthConditions,
      "medical_allergies": medicalAllergies,
      "dietary_preferences_restrictions": dietaryPreferencesRestrictions,
      "sleep_pattern_description": sleepPatternDescription,
      "stress_level_description": stressLevelDescription,
      "long_term_goals_description": longTermGoalsDescription,
      "start_date": startDate,
      "body_shape": bodyShape,
      "weight_history": weightHistory.map((e) => e.toJson()).toList(), // Include weight history
    };
  }

  // Create UserProfile object from a JSON Map
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json["age"] as int,
      gender: json["gender"] as String,
      heightCm: (json["height_cm"] as num).toDouble(),
      initialWeightKg: (json["initial_weight_kg"] as num).toDouble(),
      currentWeightKg: (json["current_weight_kg"] as num).toDouble(),
      targetWeightKg: (json["target_weight_kg"] as num).toDouble(),
      targetDate: json["target_date"] as String,
      weeklyWeightLossTargetKg: (json["weekly_weight_loss_target_kg"] as num).toDouble(),
      progressPercentage: (json["progress_percentage"] as num).toDouble(),
      weightLossPhase: json["weight_loss_phase"] as String,
      occupation: json["occupation"] as String,
      activityLevel: json["activity_level"] as String,
      healthConditions: List<String>.from(json["health_conditions"] as List),
      medicalAllergies: List<String>.from(json["medical_allergies"] as List),
      dietaryPreferencesRestrictions: List<String>.from(json["dietary_preferences_restrictions"] as List),
      sleepPatternDescription: json["sleep_pattern_description"] as String,
      stressLevelDescription: json["stress_level_description"] as String,
      longTermGoalsDescription: json["long_term_goals_description"] as String,
      startDate: json["start_date"] as String,
      bodyShape: json["body_shape"] as String,
      weightHistory: (json["weight_history"] as List<dynamic>?)
          ?.map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [], // Parse weight history
    );
  }

  // Default user profile for initialization
  static UserProfile defaultProfile() {
    return UserProfile(
      age: 30,
      gender: "Female",
      heightCm: 165.0,
      initialWeightKg: 65.0,
      currentWeightKg: 65.0,
      targetWeightKg: 55.0,
      targetDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 90))),
      weeklyWeightLossTargetKg: 0.5,
      weightLossPhase: "Initial Phase",
      occupation: "Office Worker",
      activityLevel: "Lightly Active",
      healthConditions: [],
      medicalAllergies: [],
      dietaryPreferencesRestrictions: [],
      sleepPatternDescription: "Usually 7-8 hours, sometimes interrupted.",
      stressLevelDescription: "Moderate stress level due to work.",
      longTermGoalsDescription: "Achieve healthy weight and maintain active lifestyle.",
      startDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      bodyShape: "Rectangle",
      weightHistory: [
        WeightEntry(date: DateFormat('yyyy-MM-dd').format(DateTime.now()), weightKg: 65.0),
      ],
    );
  }
}

// DataClass for a single weight entry in UserProfile's history
class WeightEntry {
  final String date; // Format: 'yyyy-MM-dd'
  late final double weightKg;

  WeightEntry({
    required this.date,
    required this.weightKg,
  });

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "weight_kg": weightKg,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      date: json['date'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
    );
  }
}

// --- Expert DataClass Definitions ---

// Doctor DataClass
class Doctor {
  final List<String> allergyMedications; // Allergic medications
  final List<String> currentMedications; // Current medications
  final List<String> existingMedicalConditions; // Existing medical conditions (e.g., "Hypertension", "Diabetes")
  final Map<String, double>? bloodLipidProfile; // Blood lipid profile (e.g., {"Total Cholesterol": 200.0, "LDL": 100.0, "HDL": 45.0, "Triglycerides": 150.0})
  final String? thyroidFunction; // Thyroid function (e.g., "Normal", "Hypothyroidism", "Hyperthyroidism")
  final String? liverKidneyFunction; // Liver and kidney function overview (e.g., "Normal", "ALT high")
  final List<DoctorDailyData> dailyDataHistory; // Daily data history

  Doctor({
    this.allergyMedications = const [],
    this.currentMedications = const [],
    this.existingMedicalConditions = const [],
    this.bloodLipidProfile,
    this.thyroidFunction,
    this.liverKidneyFunction,
    this.dailyDataHistory = const [],
  });

  // Convert Doctor object to a JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      "allergy_medications": allergyMedications,
      "current_medications": currentMedications,
      "existing_medical_conditions": existingMedicalConditions,
      "blood_lipid_profile": bloodLipidProfile,
      "thyroid_function": thyroidFunction,
      "liver_kidney_function": liverKidneyFunction,
      "daily_data_history": dailyDataHistory.map((e) => e.toJson()).toList(),
    };
  }

  // Create Doctor object from a JSON Map
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      allergyMedications: List<String>.from(json['allergy_medications'] as List? ?? []),
      currentMedications: List<String>.from(json['current_medications'] as List? ?? []),
      existingMedicalConditions: List<String>.from(json['existing_medical_conditions'] as List? ?? []),
      bloodLipidProfile: (json['blood_lipid_profile'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())),
      thyroidFunction: json['thyroid_function'] as String?,
      liverKidneyFunction: json['liver_kidney_function'] as String?,
      dailyDataHistory: (json['daily_data_history'] as List<dynamic>?)
          ?.map((e) => DoctorDailyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // Default doctor profile for initialization (now the user's default medical info)
  static Doctor defaultDoctor() {
    return Doctor(
      allergyMedications: ["None"],
      currentMedications: ["None"],
      existingMedicalConditions: ["None"],
      bloodLipidProfile: {"Total Cholesterol": 180.0, "LDL": 90.0, "HDL": 50.0, "Triglycerides": 100.0},
      thyroidFunction: "Normal",
      liverKidneyFunction: "Normal",
      dailyDataHistory: [
        DoctorDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          bloodGlucose: 90.0,
          bloodPressure: "110/70",
          bodyStatus: "Feeling good, energetic.",
          sleepQuality: "Good",
          waterIntakeMl: 2000.0,
          bowelMovementStatus: "Normal",
          medicationAdherence: "Medication taken",
          symptoms: [],
        ),
      ],
    );
  }
}

// Doctor's daily data entry data class
class DoctorDailyData {
  final String date; // Format: 'yyyy-MM-dd'
  final double? bloodGlucose; // Daily blood glucose
  final String? bloodPressure; // Daily blood pressure (e.g., "120/80")
  final String? bodyStatus; // Body status description (e.g., "Feeling good", "Slightly tired")
  final String? sleepQuality; // Sleep quality (e.g., "Good", "Fair", "Poor")
  final double? waterIntakeMl; // Water intake (ml)
  final String? bowelMovementStatus; // Bowel movement status (e.g., "Normal", "Constipation", "Diarrhea")
  final String? medicationAdherence; // Medication adherence (e.g., "Medication taken", "Missed a dose", "No medication taken")
  final List<String> symptoms; // Recorded symptoms (e.g., ["Headache", "Slight nausea"])

  DoctorDailyData({
    required this.date,
    this.bloodGlucose,
    this.bloodPressure,
    this.bodyStatus,
    this.sleepQuality,
    this.waterIntakeMl,
    this.bowelMovementStatus,
    this.medicationAdherence,
    this.symptoms = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "blood_glucose": bloodGlucose,
      "blood_pressure": bloodPressure,
      "body_status": bodyStatus,
      "sleep_quality": sleepQuality,
      "water_intake_ml": waterIntakeMl,
      "bowel_movement_status": bowelMovementStatus,
      "medication_adherence": medicationAdherence,
      "symptoms": symptoms,
    };
  }

  factory DoctorDailyData.fromJson(Map<String, dynamic> json) {
    return DoctorDailyData(
      date: json['date'] as String,
      bloodGlucose: (json['blood_glucose'] as num?)?.toDouble(),
      bloodPressure: json['blood_pressure'] as String?,
      bodyStatus: json['body_status'] as String?,
      sleepQuality: json['sleep_quality'] as String?,
      waterIntakeMl: (json['water_intake_ml'] as num?)?.toDouble(),
      bowelMovementStatus: json['bowel_movement_status'] as String?,
      medicationAdherence: json['medication_adherence'] as String?,
      symptoms: List<String>.from(json['symptoms'] as List? ?? []),
    );
  }
}
// Nutritionist DataClass
class Nutritionist {
  // Fixed attributes
  final String dailyEatingPattern; // Daily eating pattern
  final String cookingPreference; // Cooking preference
  final List<String> dislikedFoods; // Disliked foods
  final List<String> foodAllergies; // Food allergies
  final String eatingOutFrequency; // Eating out frequency
  final String alcoholConsumption; // Alcohol consumption
  final String caffeineIntake; // Caffeine intake
  final List<String> possibleNutrientDeficiencies; // Possible nutrient deficiencies
  final List<String> recommendedSupplements; // Recommended supplements
  final String digestiveHealthOverview; // Digestive health overview

  // Daily data history
  final List<NutritionistDailyData> dailyDataHistory;

  Nutritionist({
    this.dailyEatingPattern = "Three regular meals a day",
    this.cookingPreference = "Steaming and boiling",
    this.dislikedFoods = const [],
    this.foodAllergies = const [],
    this.eatingOutFrequency = "1-2 times a week",
    this.alcoholConsumption = "None",
    this.caffeineIntake = "1 cup of coffee daily",
    this.possibleNutrientDeficiencies = const [],
    this.recommendedSupplements = const [],
    this.digestiveHealthOverview = "Normal",
    this.dailyDataHistory = const [],
  });

  // Convert Nutritionist object to a JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      "daily_eating_pattern": dailyEatingPattern,
      "cooking_preference": cookingPreference,
      "disliked_foods": dislikedFoods,
      "food_allergies": foodAllergies,
      "eating_out_frequency": eatingOutFrequency,
      "alcohol_consumption": alcoholConsumption,
      "caffeine_intake": caffeineIntake,
      "possible_nutrient_deficiencies": possibleNutrientDeficiencies,
      "recommended_supplements": recommendedSupplements,
      "digestive_health_overview": digestiveHealthOverview,
      "daily_data_history": dailyDataHistory.map((e) => e.toJson()).toList(),
    };
  }

  // Create Nutritionist object from a JSON Map
  factory Nutritionist.fromJson(Map<String, dynamic> json) {
    return Nutritionist(
      dailyEatingPattern: json['daily_eating_pattern'] as String? ?? "Three regular meals a day",
      cookingPreference: json['cooking_preference'] as String? ?? "Steaming and boiling",
      dislikedFoods: List<String>.from(json['disliked_foods'] as List? ?? []),
      foodAllergies: List<String>.from(json['food_allergies'] as List? ?? []),
      eatingOutFrequency: json['eating_out_frequency'] as String? ?? "1-2 times a week",
      alcoholConsumption: json['alcohol_consumption'] as String? ?? "None",
      caffeineIntake: json['caffeine_intake'] as String? ?? "1 cup of coffee daily",
      possibleNutrientDeficiencies: List<String>.from(json['possible_nutrient_deficiencies'] as List? ?? []),
      recommendedSupplements: List<String>.from(json['recommended_supplements'] as List? ?? []),
      digestiveHealthOverview: json['digestive_health_overview'] as String? ?? "Normal",
      dailyDataHistory: (json['daily_data_history'] as List<dynamic>?)
          ?.map((e) => NutritionistDailyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // Default nutritionist profile for initialization (user's default nutrition info)
  static Nutritionist defaultNutritionist() {
    return Nutritionist(
      dailyEatingPattern: "Three regular meals a day, with small snacks.",
      cookingPreference: "Primarily steaming and boiling, occasionally baking.",
      dislikedFoods: ["Cilantro", "Fatty meat"],
      foodAllergies: ["None"],
      eatingOutFrequency: "Once a week",
      alcoholConsumption: "Occasional light drinking",
      caffeineIntake: "1 cup of coffee daily",
      possibleNutrientDeficiencies: ["Vitamin D", "Calcium"],
      recommendedSupplements: ["Vitamin D3", "Calcium tablets"],
      digestiveHealthOverview: "Normal, occasional mild bloating",
      dailyDataHistory: [
        NutritionistDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          mealCategory: "Breakfast",
          imageUrl: "",
          foodNutritionSummary: "Oatmeal with fruit, nutritionally balanced.",
          foodMetricsData: {"Protein": 15.0, "Fat": 10.0, "Energy": 350.0, "Carbs": 50.0, "Other": 5.0},
        ),
        NutritionistDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          mealCategory: "Lunch",
          imageUrl: "",
          foodNutritionSummary: "Chicken breast salad, high protein, low fat.",
          foodMetricsData: {"Protein": 30.0, "Fat": 15.0, "Energy": 450.0, "Carbs": 20.0, "Other": 10.0},
        ),
      ],
    );
  }
}

// Nutritionist daily data entry data class
class NutritionistDailyData {
  final String date;
  final String mealCategory;
  final String? imageUrl;
  final String? foodNutritionSummary;
  final Map<String, double> foodMetricsData;

  NutritionistDailyData({
    required this.date,
    required this.mealCategory,
    this.imageUrl = "",
    this.foodNutritionSummary,
    required this.foodMetricsData,
  });

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "meal_category": mealCategory,
      "image_url": imageUrl,
      "food_nutrition_summary": foodNutritionSummary,
      "food_metrics_data": foodMetricsData,
    };
  }

  factory NutritionistDailyData.fromJson(Map<String, dynamic> json) {
    return NutritionistDailyData(
      date: json['date'] as String,
      mealCategory: json['meal_category'] as String,
      imageUrl: json['image_url'] as String?,
      foodNutritionSummary: json['food_nutrition_summary'] as String?,
      foodMetricsData: Map<String, double>.from(json['food_metrics_data'] as Map),
    );
  }
}
// Fitness DataClass

// Fitness Data Class (records the user's fitness information)
class Fitness {
  // Fixed attributes
  final Map<String, double> bodyMeasurements; // Body measurements (e.g., {"Waist": 75.0, "Hips": 90.0, "Chest": 85.0})
  final List<String> likedExercises;
  final List<String> dislikedExercises;
  final String preferredWorkoutStyle;
  final List<String> physicalLimitations;
  final List<String> fitnessGoals;

  // Daily data history
  final List<FitnessDailyData> dailyDataHistory;

  Fitness({
    this.bodyMeasurements = const {},
    this.likedExercises = const [],
    this.dislikedExercises = const [],
    this.preferredWorkoutStyle = "mix training",
    this.physicalLimitations = const [],
    this.fitnessGoals = const [],
    this.dailyDataHistory = const [],
  });

  // Convert Fitness object to a JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      "body_measurements": bodyMeasurements,
      "liked_exercises": likedExercises,
      "disliked_exercises": dislikedExercises,
      "preferred_workout_style": preferredWorkoutStyle,
      "physical_limitations": physicalLimitations,
      "fitness_goals": fitnessGoals,
      "daily_data_history": dailyDataHistory.map((e) => e.toJson()).toList(),
    };
  }

  // Create Fitness object from a JSON Map
  factory Fitness.fromJson(Map<String, dynamic> json) {
    return Fitness(
      bodyMeasurements: Map<String, double>.from(json['body_measurements'] as Map? ?? {}),
      likedExercises: List<String>.from(json['liked_exercises'] as List? ?? []),
      dislikedExercises: List<String>.from(json['disliked_exercises'] as List? ?? []),
      preferredWorkoutStyle: json['preferred_workout_style'] as String? ?? "Hybrid training",
      physicalLimitations: List<String>.from(json['physical_limitations'] as List? ?? []),
      fitnessGoals: List<String>.from(json['fitness_goals'] as List? ?? []),
      dailyDataHistory: (json['daily_data_history'] as List<dynamic>?)
          ?.map((e) => FitnessDailyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // Default fitness profile for initialization (user's default fitness info)
  static Fitness defaultFitness() {
    return Fitness(
      bodyMeasurements: {"Waist": 75.0, "Hips": 90.0, "Chest": 85.0},
      likedExercises: ["Strength training", "Swimming", "Yoga", "Pilates"],
      dislikedExercises: ["Long-distance running"],
      preferredWorkoutStyle: "High-intensity interval training",
      physicalLimitations: ["Knee pain"],
      fitnessGoals: ["Weight loss", "Build arm muscles"],
      dailyDataHistory: [
        FitnessDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          exerciseItem: "Strength Training (Full Body)",
          estimatedCalorieBurn: 400.0,
          fatLossArea: "Full body",
          workoutDurationMinutes: 60,
          intensityLevel: "Medium-high",
          exerciseSummary: "Completed all sets and reps as planned, feeling good.",
          averageHeartRate: 140.0,
          peakHeartRate: 165.0,
          strengthTrainingDetails: [
            {"exercise": "Squats", "sets": 3, "reps": 8, "weight": 60.0},
            {"exercise": "Bench Press", "sets": 3, "reps": 8, "weight": 40.0},
          ],
          cardioDetails: null, // No cardio training
          userBodyStatus: "Feeling good, muscles are pumped.",
          feelingAfterWorkout: "Energetic",
          recoveryStatus: "Slight muscle soreness",
        ),
      ],
    );
  }
}

// Fitness daily data entry data class
class FitnessDailyData {
  final String date; // Format: 'yyyy-MM-dd'
  final String exerciseItem; // Exercise item
  final double estimatedCalorieBurn; // Estimated calorie burn
  final String? fatLossArea; // Fat loss area
  final int? workoutDurationMinutes; // Workout duration (minutes)
  final String? intensityLevel; // Workout intensity (e.g., Low, Medium, High)
  final String? exerciseSummary; // Workout summary
  final double? averageHeartRate; // Average heart rate during exercise
  final double? peakHeartRate; // Peak heart rate during exercise
  final List<Map<String, dynamic>>? strengthTrainingDetails; // Strength training details (e.g., [{"exercise": "Squats", "sets": 3, "reps": 8, "weight": 60.0}])
  final Map<String, dynamic>? cardioDetails; // Cardio training details (e.g., {"distanceKm": 5.0, "paceMinPerKm": 6.0})
  final String? userBodyStatus; // User body status (e.g., "Feeling strong, energetic.")
  final String? feelingAfterWorkout; // Feeling after workout (e.g., "Energetic", "Tired", "Sore")
  final String? recoveryStatus; // Recovery status (e.g., "Muscle soreness", "Sleep quality affected")

  FitnessDailyData({
    required this.date,
    required this.exerciseItem,
    required this.estimatedCalorieBurn,
    this.fatLossArea,
    this.workoutDurationMinutes,
    this.intensityLevel,
    this.exerciseSummary,
    this.averageHeartRate,
    this.peakHeartRate,
    this.strengthTrainingDetails,
    this.cardioDetails,
    this.userBodyStatus,
    this.feelingAfterWorkout,
    this.recoveryStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "exercise_item": exerciseItem,
      "estimated_calorie_burn": estimatedCalorieBurn,
      "fat_loss_area": fatLossArea,
      "workout_duration_minutes": workoutDurationMinutes,
      "intensity_level": intensityLevel,
      "exercise_summary": exerciseSummary,
      "average_heart_rate": averageHeartRate,
      "peak_heart_rate": peakHeartRate,
      "strength_training_details": strengthTrainingDetails,
      "cardio_details": cardioDetails,
      "user_body_status": userBodyStatus,
      "feeling_after_workout": feelingAfterWorkout,
      "recovery_status": recoveryStatus,
    };
  }

  factory FitnessDailyData.fromJson(Map<String, dynamic> json) {
    return FitnessDailyData(
      date: json['date'] as String,
      exerciseItem: json['exercise_item'] as String,
      estimatedCalorieBurn: (json['estimated_calorie_burn'] as num).toDouble(),
      fatLossArea: json['fat_loss_area'] as String?,
      workoutDurationMinutes: json['workout_duration_minutes'] as int?,
      intensityLevel: json['intensity_level'] as String?,
      exerciseSummary: json['exercise_summary'] as String?,
      averageHeartRate: (json['average_heart_rate'] as num?)?.toDouble(),
      peakHeartRate: (json['peak_heart_rate'] as num?)?.toDouble(),
      strengthTrainingDetails: (json['strength_training_details'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      cardioDetails: (json['cardio_details'] as Map<String, dynamic>?),
      userBodyStatus: json['user_body_status'] as String?,
      feelingAfterWorkout: json['feeling_after_workout'] as String?,
      recoveryStatus: json['recovery_status'] as String?,
    );
  }
}

// Psychology DataClass

// Psychology Data Class (records user's psychological information)
class Psychology {
  // Fixed attributes
  final String weightLossMotivation; // Motivation for weight loss: for health? confidence or perfectionism?
  final String pastDietExperience; // Past weight loss and fitness experiences and their impact
  final int selfConfidenceIndex; // Confidence index in achieving goals (1-10)
  final String selfPerception; // How to view oneself: satisfied with appearance, how to evaluate appearance

  // Daily data history
  final List<PsychologyDailyData> dailyDataHistory;

  Psychology({
    this.weightLossMotivation = "For health and confidence",
    this.pastDietExperience = "Successful in the past with diet control, but struggled with consistency.",
    this.selfConfidenceIndex = 7,
    this.selfPerception = "Generally satisfied, but want to improve body shape.",
    this.dailyDataHistory = const [],
  });

  // Convert Psychology object to JSON-compatible Map
  Map<String, dynamic> toJson() {
    return {
      "weight_loss_motivation": weightLossMotivation,
      "past_diet_experience": pastDietExperience,
      "self_confidence_index": selfConfidenceIndex,
      "self_perception": selfPerception,
      "daily_data_history": dailyDataHistory.map((e) => e.toJson()).toList(),
    };
  }

  // Create Psychology object from JSON Map
  factory Psychology.fromJson(Map<String, dynamic> json) {
    return Psychology(
      weightLossMotivation: json['weight_loss_motivation'] as String? ?? "For health and confidence",
      pastDietExperience: json['past_diet_experience'] as String? ?? "Successful in the past with diet control, but struggled with consistency.",
      selfConfidenceIndex: json['self_confidence_index'] as int? ?? 7,
      selfPerception: json['self_perception'] as String? ?? "Generally satisfied, but want to improve body shape.",
      dailyDataHistory: (json['daily_data_history'] as List<dynamic>?)
          ?.map((e) => PsychologyDailyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // Default psychology profile for initialization (user's default psychological info)
  static Psychology defaultPsychology() {
    return Psychology(
      weightLossMotivation: "For better health, increased self-confidence, and improved energy levels.",
      pastDietExperience: "Successfully lost weight before through calorie counting, but regained due to stress eating. Learned the importance of sustainable habits.",
      selfConfidenceIndex: 7, // On a scale of 1-10
      selfPerception: "I generally feel good about myself, but sometimes compare my body to others and feel self-conscious.",
      dailyDataHistory: [
        PsychologyDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          moodStatus: "Happy",
          stressLevel: "Low",
          psychologicalChallenges: [],
        ),
      ],
    );
  }
}

// Psychology Daily Data Entry Class
class PsychologyDailyData {
  final String date; // Format: 'yyyy-MM-dd'
  final String moodStatus; // Daily mood status (e.g., "Happy", "Calm", "Anxious", "Frustrated")
  final String stressLevel; // Daily stress level (e.g., "Low", "Medium", "High")
  final List<String> psychologicalChallenges; // Psychological challenges encountered (e.g., ["Cravings", "Lack of motivation"])

  PsychologyDailyData({
    required this.date,
    required this.moodStatus,
    required this.stressLevel,
    this.psychologicalChallenges = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      "date": date,
      "mood_status": moodStatus,
      "stress_level": stressLevel,
      "psychological_challenges": psychologicalChallenges,
    };
  }

  factory PsychologyDailyData.fromJson(Map<String, dynamic> json) {
    return PsychologyDailyData(
      date: json['date'] as String,
      moodStatus: json['mood_status'] as String,
      stressLevel: json['stress_level'] as String,
      psychologicalChallenges: List<String>.from(json['psychological_challenges'] as List? ?? []),
    );
  }
}

// --- Manager Class for All App Models ---
class AppModelsManager {
  static UserProfile? userProfile;
  static Doctor? doctor;
  static Nutritionist? nutritionist;
  static Fitness? fitness;
  static Psychology? psychology;

  // Path to the local JSON file
  static Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/progressai'; // Create an 'assets' folder in the app's documents directory
    await Directory(path).create(recursive: true); // Ensure the directory exists
    return File('$path/weight.json');
  }

  // Load all data from the local JSON file
  static Future<void> loadData() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> json = jsonDecode(contents);

        userProfile = json.containsKey('user_profile') && json['user_profile'] != null
            ? UserProfile.fromJson(json['user_profile'])
            : UserProfile.defaultProfile();

        doctor = json.containsKey('doctor') && json['doctor'] != null
            ? Doctor.fromJson(json['doctor'])
            : Doctor.defaultDoctor();

        nutritionist = json.containsKey('nutritionist') && json['nutritionist'] != null
            ? Nutritionist.fromJson(json['nutritionist'])
            : Nutritionist.defaultNutritionist();

        fitness = json.containsKey('fitness') && json['fitness'] != null
            ? Fitness.fromJson(json['fitness'])
            : Fitness.defaultFitness();

        psychology = json.containsKey('psychology') && json['psychology'] != null
            ? Psychology.fromJson(json['psychology'])
            : Psychology.defaultPsychology();

      } else {
        // If file doesn't exist, initialize with default data and save it
        userProfile = UserProfile.defaultProfile();
        doctor = Doctor.defaultDoctor();
        nutritionist = Nutritionist.defaultNutritionist();
        fitness = Fitness.defaultFitness();
        psychology = Psychology.defaultPsychology();
        await saveData(); // Save default data to file
      }
    } catch (e) {
      print("Error loading data: $e");
      // Fallback to default data in case of any loading error
      userProfile = UserProfile.defaultProfile();
      doctor = Doctor.defaultDoctor();
      nutritionist = Nutritionist.defaultNutritionist();
      fitness = Fitness.defaultFitness();
      psychology = Psychology.defaultPsychology();
    }
  }

  // Save all current data to the local JSON file
  static Future<void> saveData() async {
    final file = await _localFile;
    final Map<String, dynamic> allData = {
      "user_profile": userProfile?.toJson(),
      "doctor": doctor?.toJson(),
      "nutritionist": nutritionist?.toJson(),
      "fitness": fitness?.toJson(),
      "psychology": psychology?.toJson(),
    };
    await file.writeAsString(jsonEncode(allData));
    print("All app models data saved to ${file.path}");
  }
}
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
  List<WeightEntry> weightHistory; // Added: 体重历史列表

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
  final double weightKg;

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
  final List<String> allergyMedications; // 过敏药物
  final List<String> currentMedications; // 正在服用的药物
  final List<String> existingMedicalConditions; // 现有疾病 (例如: "高血压", "糖尿病")
  final Map<String, double>? bloodLipidProfile; // 血脂水平 (例如: {"Total Cholesterol": 200.0, "LDL": 100.0, "HDL": 45.0, "Triglycerides": 150.0})
  final String? thyroidFunction; // 甲状腺功能 (例如: "正常", "甲减", "甲亢")
  final String? liverKidneyFunction; // 肝肾功能概述 (例如: "正常", "ALT偏高")
  final List<DoctorDailyData> dailyDataHistory; // 每日数据历史

  Doctor({
    this.allergyMedications = const [],
    this.currentMedications = const [],
    this.existingMedicalConditions = const [],
    this.bloodLipidProfile,
    this.thyroidFunction,
    this.liverKidneyFunction,
    this.dailyDataHistory = const [],
  });

  // 将Doctor对象转换为JSON兼容的Map
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

  // 从JSON Map创建Doctor对象
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

  // 用于初始化的默认医生资料 (现在是用户的默认医疗信息)
  static Doctor defaultDoctor() {
    return Doctor(
      allergyMedications: ["无"],
      currentMedications: ["无"],
      existingMedicalConditions: ["无"],
      bloodLipidProfile: {"总胆固醇": 180.0, "低密度脂蛋白": 90.0, "高密度脂蛋白": 50.0, "甘油三酯": 100.0},
      thyroidFunction: "正常",
      liverKidneyFunction: "正常",
      dailyDataHistory: [
        DoctorDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          bloodGlucose: 90.0,
          bloodPressure: "110/70",
          bodyStatus: "感觉良好，精力充沛。",
          sleepQuality: "良好",
          waterIntakeMl: 2000.0,
          bowelMovementStatus: "正常",
          medicationAdherence: "已服药",
          symptoms: [],
        ),
      ],
    );
  }
}

// 医生每日数据条目数据类
class DoctorDailyData {
  final String date; // 格式: 'yyyy-MM-dd'
  final double? bloodGlucose; // 每日血糖
  final String? bloodPressure; // 每日血压 (例如: "120/80")
  final String? bodyStatus; // 身体状态描述 (例如: "感觉良好", "轻微疲劳")
  final String? sleepQuality; // 睡眠质量 (例如: "良好", "一般", "差")
  final double? waterIntakeMl; // 饮水量 (毫升)
  final String? bowelMovementStatus; // 排便情况 (例如: "正常", "便秘", "腹泻")
  final String? medicationAdherence; // 服药依从性 (例如: "已服药", "漏服", "未服")
  final List<String> symptoms; // 记录的症状 (例如: ["头痛", "轻微恶心"])

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
  // 固定信息
  final String dailyEatingPattern; // 日常饮食模式
  final String cookingPreference; // 烹饪方式偏好
  final List<String> dislikedFoods; // 不喜欢吃的食物
  final List<String> foodAllergies; // 食物过敏
  final String eatingOutFrequency; // 外出就餐频率
  final String alcoholConsumption; // 饮酒习惯
  final String caffeineIntake; // 咖啡因摄入
  final List<String> possibleNutrientDeficiencies; // 可能的营养缺失
  final List<String> recommendedSupplements; // 需要补充的药剂
  final String digestiveHealthOverview; // 消化系统健康概述

  // 每日数据历史
  final List<NutritionistDailyData> dailyDataHistory;

  Nutritionist({
    this.dailyEatingPattern = "一日三餐规律",
    this.cookingPreference = "蒸煮",
    this.dislikedFoods = const [],
    this.foodAllergies = const [],
    this.eatingOutFrequency = "每周1-2次",
    this.alcoholConsumption = "无",
    this.caffeineIntake = "每日1杯咖啡",
    this.possibleNutrientDeficiencies = const [],
    this.recommendedSupplements = const [],
    this.digestiveHealthOverview = "正常",
    this.dailyDataHistory = const [],
  });

  // 将Nutritionist对象转换为JSON兼容的Map
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

  // 从JSON Map创建Nutritionist对象
  factory Nutritionist.fromJson(Map<String, dynamic> json) {
    return Nutritionist(
      dailyEatingPattern: json['daily_eating_pattern'] as String? ?? "一日三餐规律",
      cookingPreference: json['cooking_preference'] as String? ?? "蒸煮",
      dislikedFoods: List<String>.from(json['disliked_foods'] as List? ?? []),
      foodAllergies: List<String>.from(json['food_allergies'] as List? ?? []),
      eatingOutFrequency: json['eating_out_frequency'] as String? ?? "每周1-2次",
      alcoholConsumption: json['alcohol_consumption'] as String? ?? "无",
      caffeineIntake: json['caffeine_intake'] as String? ?? "每日1杯咖啡",
      possibleNutrientDeficiencies: List<String>.from(json['possible_nutrient_deficiencies'] as List? ?? []),
      recommendedSupplements: List<String>.from(json['recommended_supplements'] as List? ?? []),
      digestiveHealthOverview: json['digestive_health_overview'] as String? ?? "正常",
      dailyDataHistory: (json['daily_data_history'] as List<dynamic>?)
          ?.map((e) => NutritionistDailyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // 用于初始化的默认营养师资料 (用户的默认营养信息)
  static Nutritionist defaultNutritionist() {
    return Nutritionist(
      dailyEatingPattern: "一日三餐规律，少量加餐",
      cookingPreference: "蒸煮为主，偶尔烤",
      dislikedFoods: ["香菜", "肥肉"],
      foodAllergies: ["无"],
      eatingOutFrequency: "每周1次",
      alcoholConsumption: "偶尔小酌",
      caffeineIntake: "每日1杯咖啡",
      possibleNutrientDeficiencies: ["维生素D", "钙"],
      recommendedSupplements: ["维生素D3", "钙片"],
      digestiveHealthOverview: "正常，偶尔轻微腹胀",
      dailyDataHistory: [
        NutritionistDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          mealCategory: "早餐",
          imageUrl: "",
          foodNutritionSummary: "燕麦粥加水果，营养均衡。",
          foodMetricsData: {"蛋白质": 15.0, "脂肪": 10.0, "能量": 350.0, "碳水": 50.0, "其他": 5.0},
        ),
        NutritionistDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          mealCategory: "午餐",
          imageUrl: "",
          foodNutritionSummary: "鸡胸肉沙拉，高蛋白低脂。",
          foodMetricsData: {"蛋白质": 30.0, "脂肪": 15.0, "能量": 450.0, "碳水": 20.0, "其他": 10.0},
        ),
      ],
    );
  }
}

// 营养师每日数据条目数据类
class NutritionistDailyData {
  final String date; // 格式: 'yyyy-MM-dd'
  final String mealCategory; // 用餐类别: 早/中午/晚餐/零食
  final String? imageUrl; // 用餐食物图片地址: 默认为空白字符串
  final String? foodNutritionSummary; // 食物营养总结: 一段文字描述这次食物
  final Map<String, double> foodMetricsData; // 食物中各个指标数据 : 蛋白质,脂肪,能量,碳水,其他

  NutritionistDailyData({
    required this.date,
    required this.mealCategory,
    this.imageUrl = "", // 默认为空白字符串
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

// 健身数据类 (记录用户的健身信息)
class Fitness {
  // 固定信息
  final Map<String, double> bodyMeasurements; // 身体围度测量 (例如: {"腰围": 75.0, "臀围": 90.0, "胸围": 85.0})
  final List<String> likedExercises; // 喜欢的运动
  final List<String> dislikedExercises; // 不喜欢的运动
  final String preferredWorkoutStyle; // 偏好的运动风格
  final List<String> physicalLimitations; // 身体旧伤
  final List<String> fitnessGoals; // 健身目标

  // 每日数据历史
  final List<FitnessDailyData> dailyDataHistory;

  Fitness({
    this.bodyMeasurements = const {},
    this.likedExercises = const [],
    this.dislikedExercises = const [],
    this.preferredWorkoutStyle = "混合训练",
    this.physicalLimitations = const [],
    this.fitnessGoals = const [],
    this.dailyDataHistory = const [],
  });

  // 将Fitness对象转换为JSON兼容的Map
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

  // 从JSON Map创建Fitness对象
  factory Fitness.fromJson(Map<String, dynamic> json) {
    return Fitness(
      bodyMeasurements: Map<String, double>.from(json['body_measurements'] as Map? ?? {}),
      likedExercises: List<String>.from(json['liked_exercises'] as List? ?? []),
      dislikedExercises: List<String>.from(json['disliked_exercises'] as List? ?? []),
      preferredWorkoutStyle: json['preferred_workout_style'] as String? ?? "混合训练",
      physicalLimitations: List<String>.from(json['physical_limitations'] as List? ?? []),
      fitnessGoals: List<String>.from(json['fitness_goals'] as List? ?? []),
      dailyDataHistory: (json['daily_data_history'] as List<dynamic>?)
          ?.map((e) => FitnessDailyData.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // 用于初始化的默认健身资料 (用户的默认健身信息)
  static Fitness defaultFitness() {
    return Fitness(
      bodyMeasurements: {"腰围": 75.0, "臀围": 90.0, "胸围": 85.0},
      likedExercises: ["力量训练", "游泳", "瑜伽", "普拉提"],
      dislikedExercises: ["长跑"],
      preferredWorkoutStyle: "高强度间歇训练",
      physicalLimitations: ["膝盖痛"],
      fitnessGoals: ["减肥", "锻炼手臂肌肉"],
      dailyDataHistory: [
        FitnessDailyData(
          date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          exerciseItem: "力量训练 (全身)",
          estimatedCalorieBurn: 400.0,
          fatLossArea: "全身",
          workoutDurationMinutes: 60,
          intensityLevel: "中高",
          exerciseSummary: "完成了计划的所有组数和次数，状态不错。",
          averageHeartRate: 140.0,
          peakHeartRate: 165.0,
          strengthTrainingDetails: [
            {"exercise": "深蹲", "sets": 3, "reps": 8, "weight": 60.0},
            {"exercise": "卧推", "sets": 3, "reps": 8, "weight": 40.0},
          ],
          cardioDetails: null, // 没有有氧训练
          userBodyStatus: "感觉良好，肌肉有泵感。",
          feelingAfterWorkout: "精力充沛",
          recoveryStatus: "轻微肌肉酸痛",
        ),
      ],
    );
  }
}

// 健身每日数据条目数据类
class FitnessDailyData {
  final String date; // 格式: 'yyyy-MM-dd'
  final String exerciseItem; // 运动项目
  final double estimatedCalorieBurn; // 预估热量消耗
  final String? fatLossArea; // 脂肪消耗部位
  final int? workoutDurationMinutes; // 运动时长 (分钟)
  final String? intensityLevel; // 运动强度 (例如: 低, 中, 高)
  final String? exerciseSummary; // 运动小结
  final double? averageHeartRate; // 运动过程中的平均心率
  final double? peakHeartRate; // 运动过程中的峰值心率
  final List<Map<String, dynamic>>? strengthTrainingDetails; // 力量训练细节 (例如: [{"exercise": "深蹲", "sets": 3, "reps": 8, "weight": 60.0}])
  final Map<String, dynamic>? cardioDetails; // 有氧训练细节 (例如: {"distanceKm": 5.0, "paceMinPerKm": 6.0})
  final String? userBodyStatus; // 用户身体状态 (例如: "感觉强壮，精力充沛。")
  final String? feelingAfterWorkout; // 运动后的感受 (例如: "精力充沛", "疲惫", "酸痛")
  final String? recoveryStatus; // 恢复状态 (例如: "肌肉酸痛", "睡眠质量影响")

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

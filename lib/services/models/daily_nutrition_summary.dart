import 'package:cloud_firestore/cloud_firestore.dart';

class DailyNutritionSummary {
  const DailyNutritionSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.updatedAt,
  });

  const DailyNutritionSummary.empty()
      : calories = 0,
        protein = 0,
        carbs = 0,
        fat = 0,
        updatedAt = null;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime? updatedAt;

  DailyNutritionSummary copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? updatedAt,
  }) {
    return DailyNutritionSummary(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DailyNutritionSummary.fromMap(Map<String, dynamic>? data) {
    final updatedAtRaw = data?['updatedAt'];

    return DailyNutritionSummary(
      calories: (data?['totalCalories'] as num?)?.toDouble() ?? 0,
      protein: (data?['totalProtein'] as num?)?.toDouble() ?? 0,
      carbs: (data?['totalCarbs'] as num?)?.toDouble() ?? 0,
      fat: (data?['totalFat'] as num?)?.toDouble() ?? 0,
      updatedAt: updatedAtRaw is Timestamp
          ? updatedAtRaw.toDate()
          : updatedAtRaw as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCalories': calories,
      'totalProtein': protein,
      'totalCarbs': carbs,
      'totalFat': fat,
      'updatedAt': updatedAt,
    };
  }
}

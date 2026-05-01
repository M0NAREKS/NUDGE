import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  const FoodItem({
    this.id = '',
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
    this.baseCalories,
    this.baseProtein,
    this.baseCarbs,
    this.baseFat,
    this.servingLabel,
    this.servingGrams,
    this.selectedGrams,
    this.isEstimated = false,
    this.confidence,
    this.createdAt,
  });

  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String source;
  final int? baseCalories;
  final double? baseProtein;
  final double? baseCarbs;
  final double? baseFat;
  final String? servingLabel;
  final double? servingGrams;
  final double? selectedGrams;
  final bool isEstimated;
  final double? confidence;
  final DateTime? createdAt;

  bool get isPersisted => id.isNotEmpty;
  int get resolvedBaseCalories => baseCalories ?? calories;
  double get resolvedBaseProtein => baseProtein ?? protein;
  double get resolvedBaseCarbs => baseCarbs ?? carbs;
  double get resolvedBaseFat => baseFat ?? fat;
  bool get hasServingInfo =>
      (servingLabel?.trim().isNotEmpty ?? false) || (servingGrams ?? 0) > 0;

  String? get amountLabel {
    if ((selectedGrams ?? 0) > 0) {
      return '${_formatAmount(selectedGrams!)} g';
    }
    if ((servingLabel?.trim().isNotEmpty ?? false)) {
      return servingLabel!.trim();
    }
    return null;
  }

  String? get baseServingLabel {
    if ((servingLabel?.trim().isNotEmpty ?? false)) {
      return servingLabel!.trim();
    }
    if ((servingGrams ?? 0) > 0) {
      return '${_formatAmount(servingGrams!)} g';
    }
    return null;
  }

  String get sourceLabel {
    switch (source) {
      case 'fatsecret':
        return 'FatSecret';
      case 'ai_estimate':
        return 'AI tahmin';
      case 'manual':
        return 'Manuel';
      default:
        return source;
    }
  }

  FoodItem copyWith({
    String? id,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? source,
    int? baseCalories,
    double? baseProtein,
    double? baseCarbs,
    double? baseFat,
    String? servingLabel,
    double? servingGrams,
    double? selectedGrams,
    bool? isEstimated,
    double? confidence,
    DateTime? createdAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      source: source ?? this.source,
      baseCalories: baseCalories ?? this.baseCalories,
      baseProtein: baseProtein ?? this.baseProtein,
      baseCarbs: baseCarbs ?? this.baseCarbs,
      baseFat: baseFat ?? this.baseFat,
      servingLabel: servingLabel ?? this.servingLabel,
      servingGrams: servingGrams ?? this.servingGrams,
      selectedGrams: selectedGrams ?? this.selectedGrams,
      isEstimated: isEstimated ?? this.isEstimated,
      confidence: confidence ?? this.confidence,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'source': source,
      'baseCalories': baseCalories ?? calories,
      'baseProtein': baseProtein ?? protein,
      'baseCarbs': baseCarbs ?? carbs,
      'baseFat': baseFat ?? fat,
      'servingLabel': servingLabel,
      'servingGrams': servingGrams,
      'selectedGrams': selectedGrams,
      'isEstimated': isEstimated,
      'confidence': confidence,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> data, {String id = ''}) {
    final normalizedSource = _normalizeSource(data['source'] as String?);

    return FoodItem(
      id: id,
      name: data['name'] as String? ?? '',
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0,
      source: normalizedSource,
      baseCalories: (data['baseCalories'] as num?)?.toInt(),
      baseProtein: (data['baseProtein'] as num?)?.toDouble(),
      baseCarbs: (data['baseCarbs'] as num?)?.toDouble(),
      baseFat: (data['baseFat'] as num?)?.toDouble(),
      servingLabel: data['servingLabel'] as String?,
      servingGrams: (data['servingGrams'] as num?)?.toDouble(),
      selectedGrams: (data['selectedGrams'] as num?)?.toDouble(),
      isEstimated: data['isEstimated'] as bool? ?? normalizedSource == 'ai_estimate',
      confidence: (data['confidence'] as num?)?.toDouble(),
      createdAt: _parseCreatedAt(data['createdAt']),
    );
  }

  FoodItem scaleToGrams(double grams) {
    if ((servingGrams ?? 0) <= 0 || grams <= 0) {
      return copyWith(selectedGrams: grams > 0 ? grams : null);
    }

    final multiplier = grams / servingGrams!;
    return copyWith(
      calories: (resolvedBaseCalories * multiplier).round(),
      protein: resolvedBaseProtein * multiplier,
      carbs: resolvedBaseCarbs * multiplier,
      fat: resolvedBaseFat * multiplier,
      selectedGrams: grams,
    );
  }

  static DateTime? _parseCreatedAt(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    return null;
  }

  static String _normalizeSource(String? raw) {
    switch (raw) {
      case 'ai':
      case 'ai_estimate':
        return 'ai_estimate';
      case 'manual':
        return 'manual';
      case 'fatsecret':
      default:
        return raw ?? 'fatsecret';
    }
  }

  static String _formatAmount(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

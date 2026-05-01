import 'functions_gateway.dart';
import 'models/food_item.dart';

class FatSecretApiService {
  FatSecretApiService({FunctionsGateway? gateway})
      : _gateway = gateway ?? FirebaseFunctionsGateway();

  final FunctionsGateway _gateway;

  Future<List<FoodItem>> performSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const [];

    final data = await _gateway.getJson(
      'fatsecretSearch',
      queryParameters: {'q': trimmedQuery},
    );
    final upstreamError = data['error'];
    if (upstreamError is Map<String, dynamic>) {
      throw FunctionGatewayException(
        upstreamError['message'] as String? ?? 'FatSecret araması başarısız oldu.',
        statusCode: (upstreamError['code'] as num?)?.toInt(),
      );
    }

    final foodsData = data['foods']?['food'];
    if (foodsData == null) return const [];

    final items = foodsData is List ? foodsData : [foodsData];

    return items
        .map(
          (item) => _mapFoodItem(
            item as Map<String, dynamic>,
            fallbackName: trimmedQuery,
          ),
        )
        .whereType<FoodItem>()
        .toList();
  }

  FoodItem? _mapFoodItem(
    Map<String, dynamic>? data, {
    required String fallbackName,
  }) {
    if (data == null) return null;

    final name = data['food_name'] as String? ?? fallbackName;
    final description = data['food_description'] as String? ?? '';
    final calories = _extract('Calories', description).round();
    final protein = _extract('Protein', description);
    final carbs = _extract('Carbs', description);
    final fat = _extract('Fat', description);
    final servingLabel = _extractServingLabel(description);
    final servingGrams = _extractServingGrams(description);

    return FoodItem(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      source: 'fatsecret',
      baseCalories: calories,
      baseProtein: protein,
      baseCarbs: carbs,
      baseFat: fat,
      servingLabel: servingLabel,
      servingGrams: servingGrams,
      selectedGrams: servingGrams,
      isEstimated: false,
    );
  }

  double _extract(String key, String text) {
    final regex = RegExp('$key:?\\s*([0-9]+(?:\\.[0-9]+)?)');
    final match = regex.firstMatch(text);
    return double.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  String? _extractServingLabel(String text) {
    final prefix = text.split(' - ').first.trim();
    if (prefix.isEmpty || prefix == text.trim()) {
      return null;
    }
    return prefix;
  }

  double? _extractServingGrams(String text) {
    final regex = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*g\b', caseSensitive: false);
    final match = regex.firstMatch(text);
    return double.tryParse(match?.group(1) ?? '');
  }
}

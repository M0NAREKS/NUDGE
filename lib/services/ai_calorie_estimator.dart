import 'functions_gateway.dart';
import 'models/food_item.dart';

class AiCalorieEstimator {
  AiCalorieEstimator({FunctionsGateway? gateway})
      : _gateway = gateway ?? FirebaseFunctionsGateway();

  final FunctionsGateway _gateway;

  Future<FoodItem?> estimate(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return null;

    final data = await _gateway.postJson(
      'foodEstimate',
      body: {'query': trimmedQuery},
    );
    final item = data['item'];
    if (item is! Map<String, dynamic>) {
      return null;
    }

    return FoodItem.fromMap(item).copyWith(
      source: 'ai_estimate',
      isEstimated: true,
    );
  }
}

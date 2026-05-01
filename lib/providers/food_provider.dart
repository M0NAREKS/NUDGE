import 'package:flutter/material.dart';

import '../services/app_analytics.dart';
import '../services/ai_calorie_estimator.dart';
import '../services/fatsecret_api_service.dart';
import '../services/functions_gateway.dart';
import '../services/local_storage_service.dart';
import '../services/models/daily_nutrition_summary.dart';
import '../services/models/food_item.dart';
import '../services/nutrition_repository.dart';
import 'user_provider.dart';

class FoodProvider extends ChangeNotifier {
  FoodProvider({
    FatSecretApiService? fatSecretApiService,
    AiCalorieEstimator? aiCalorieEstimator,
    NutritionRepository? nutritionRepository,
    AppAnalytics? analytics,
    DateTime Function()? now,
  })  : _fatSecretApiService = fatSecretApiService ?? FatSecretApiService(),
        _aiCalorieEstimator = aiCalorieEstimator ?? AiCalorieEstimator(),
        _nutritionRepository =
            nutritionRepository ?? FirestoreNutritionRepository(),
        _analytics = analytics,
        _now = now ?? DateTime.now;

  final FatSecretApiService _fatSecretApiService;
  final AiCalorieEstimator _aiCalorieEstimator;
  final NutritionRepository _nutritionRepository;
  final AppAnalytics? _analytics;
  final DateTime Function() _now;

  bool _loading = false;
  String? _errorMessage;
  String? _helperMessage;
  List<FoodItem> _results = [];

  bool get isLoading => _loading;
  String? get errorMessage => _errorMessage;
  String? get helperMessage => _helperMessage;
  List<FoodItem> get results => _results;

  void clearSearch() {
    _results = [];
    _errorMessage = null;
    _helperMessage = null;
    notifyListeners();
  }

  Future<void> searchFood(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      clearSearch();
      return;
    }

    final isEnglish = await _isEnglish();

    _loading = true;
    _errorMessage = null;
    _helperMessage = null;
    notifyListeners();

    try {
      await _analytics?.logEvent(
        'food_search',
        {'query_length': trimmedQuery.length},
      );

      final fatSecretResults = await _fatSecretApiService.performSearch(trimmedQuery);
      if (fatSecretResults.isNotEmpty) {
        _results = fatSecretResults;
        await _analytics?.logEvent(
          'food_search_result',
          {
            'source': 'fatsecret',
            'result_count': fatSecretResults.length,
          },
        );
        return;
      }

      await _setFallbackResult(
        trimmedQuery,
        fallbackReason: isEnglish
            ? 'FatSecret returned no results.'
            : 'FatSecret sonuç vermedi.',
        isEnglish: isEnglish,
      );
    } on FunctionGatewayException {
      await _setFallbackResult(
        trimmedQuery,
        fallbackReason: isEnglish
            ? 'FatSecret is unavailable right now.'
            : 'FatSecret şu anda kullanılamıyor.',
        isEnglish: isEnglish,
      );
    } catch (_) {
      await _setFallbackResult(
        trimmedQuery,
        fallbackReason: isEnglish
            ? 'Food search failed unexpectedly.'
            : 'Yemek araması beklenmedik şekilde başarısız oldu.',
        isEnglish: isEnglish,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<FoodItem?> resolveFoodFromQuery(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return null;

    try {
      final fatSecretResults = await _fatSecretApiService.performSearch(trimmedQuery);
      if (fatSecretResults.isNotEmpty) {
        return fatSecretResults.first;
      }
    } catch (_) {
      // Fallback is handled below.
    }

    try {
      return await _aiCalorieEstimator.estimate(trimmedQuery);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setFallbackResult(
    String query, {
    required String fallbackReason,
    required bool isEnglish,
  }) async {
    try {
      await _analytics?.logEvent(
        'food_search_fallback',
        {'reason': fallbackReason},
      );
      final estimation = await _aiCalorieEstimator.estimate(query);
      if (estimation != null) {
        _results = [estimation];
        _helperMessage = isEnglish
            ? '$fallbackReason Showing AI estimate.'
            : '$fallbackReason AI tahmini gösteriliyor.';
        return;
      }
    } catch (_) {
      // Manual fallback message will be shown below.
    }

    _results = [];
    _errorMessage = isEnglish
        ? '$fallbackReason You can use manual entry.'
        : '$fallbackReason Manuel giriş yapabilirsiniz.';
  }

  Future<void> addFood({
    required UserProvider userProvider,
    required FoodItem item,
  }) async {
    final user = userProvider.profile;
    if (user == null) return;

    await _nutritionRepository.addFood(
      uid: user.uid,
      date: _now(),
      item: item,
    );
    await _analytics?.logEvent(
      'food_added',
      {
        'source': item.source,
        'is_estimated': item.isEstimated,
        'has_serving_info': item.hasServingInfo,
      },
    );
  }

  Future<void> updateFood({
    required UserProvider userProvider,
    required FoodItem item,
  }) async {
    final user = userProvider.profile;
    if (user == null) return;

    await _nutritionRepository.updateFood(
      uid: user.uid,
      date: _now(),
      item: item,
    );
  }

  Future<void> deleteFood({
    required UserProvider userProvider,
    required FoodItem item,
  }) async {
    final user = userProvider.profile;
    if (user == null || item.id.isEmpty) return;

    await _nutritionRepository.deleteFood(
      uid: user.uid,
      date: _now(),
      foodId: item.id,
    );
  }

  Future<void> addFoodFromQuery({
    required UserProvider userProvider,
    required String query,
  }) async {
    final resolvedItem = await resolveFoodFromQuery(query);
    if (resolvedItem == null) {
      final isEnglish = await _isEnglish();
      throw FunctionGatewayException(
        isEnglish
            ? 'Food could not be found. You can use manual entry.'
            : 'Yemek bulunamadı. Manuel giriş yapabilirsiniz.',
      );
    }

    await addFood(userProvider: userProvider, item: resolvedItem);
  }

  Stream<List<FoodItem>> mealsForToday(String uid) {
    return _nutritionRepository.mealsForDate(uid, _now());
  }

  Stream<DailyNutritionSummary> summaryForToday(String uid) {
    return _nutritionRepository.summaryForDate(uid, _now());
  }

  Future<bool> _isEnglish() async {
    final settings = await LocalStorageService.getAppSettings();
    return settings.localeCode == 'en';
  }
}


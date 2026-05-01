import 'package:nudge/providers/food_provider.dart';
import 'package:nudge/providers/health_provider.dart';
import 'package:nudge/providers/hydration_provider.dart';
import 'package:nudge/providers/user_provider.dart';
import 'package:nudge/services/ai_calorie_estimator.dart';
import 'package:nudge/services/fatsecret_api_service.dart';
import 'package:nudge/services/functions_gateway.dart';
import 'package:nudge/services/models/food_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const {'locale_code': 'tr'});

  group('FoodProvider', () {
    final today = DateTime(2026, 3, 16);
    const userProfile = AppUserProfile(
      uid: 'user-1',
      email: 'nudge@example.com',
      name: 'Fit Coach',
      age: 25,
      height: 175,
      weight: 72,
      gender: 'male',
      activity: 'light',
      dailyCalories: 2200,
    );

    test('uses FatSecret result before AI fallback', () async {
      var aiCalled = false;
      final fatSecret = FatSecretApiService(
        gateway: FakeFunctionsGateway(
          getHandler: (functionName, queryParameters) async {
            return <String, dynamic>{
              'foods': <String, dynamic>{
                'food': <String, dynamic>{
                  'food_name': 'Banana',
                  'food_description':
                      'Calories: 89, Protein: 1.1, Carbs: 23, Fat: 0.3',
                },
              },
            };
          },
        ),
      );
      final aiEstimator = AiCalorieEstimator(
        gateway: FakeFunctionsGateway(
          postHandler: (functionName, body) async {
            aiCalled = true;
            return <String, dynamic>{};
          },
        ),
      );
      final provider = FoodProvider(
        fatSecretApiService: fatSecret,
        aiCalorieEstimator: aiEstimator,
        nutritionRepository: FakeNutritionRepository(now: () => today),
        now: () => today,
      );

      await provider.searchFood('banana');

      expect(provider.results, hasLength(1));
      expect(provider.results.single.source, 'fatsecret');
      expect(aiCalled, isFalse);
    });

    test('falls back to AI estimate when FatSecret returns empty', () async {
      final fatSecret = FatSecretApiService(
        gateway: FakeFunctionsGateway(
          getHandler: (functionName, queryParameters) async {
            return <String, dynamic>{'foods': <String, dynamic>{}};
          },
        ),
      );
      final aiEstimator = AiCalorieEstimator(
        gateway: FakeFunctionsGateway(
          postHandler: (functionName, body) async {
            return <String, dynamic>{
              'item': <String, dynamic>{
                'name': 'Custom Salad',
                'calories': 250,
                'protein': 12,
                'carbs': 18,
                'fat': 14,
                'source': 'ai_estimate',
                'isEstimated': true,
                'confidence': 0.6,
              },
            };
          },
        ),
      );
      final provider = FoodProvider(
        fatSecretApiService: fatSecret,
        aiCalorieEstimator: aiEstimator,
        nutritionRepository: FakeNutritionRepository(now: () => today),
        now: () => today,
      );

      await provider.searchFood('custom salad');

      expect(provider.results, hasLength(1));
      expect(provider.results.single.source, 'ai_estimate');
      expect(provider.results.single.isEstimated, isTrue);
      expect(provider.helperMessage, contains('AI tahmini'));
    });

    test('shows manual-entry message when fallback also fails', () async {
      final fatSecret = FatSecretApiService(
        gateway: FakeFunctionsGateway(
          getHandler: (functionName, queryParameters) async =>
              <String, dynamic>{'foods': <String, dynamic>{}},
        ),
      );
      final aiEstimator = AiCalorieEstimator(
        gateway: FakeFunctionsGateway(
          postHandler: (functionName, body) async {
            throw const FunctionGatewayException('estimate failed');
          },
        ),
      );
      final provider = FoodProvider(
        fatSecretApiService: fatSecret,
        aiCalorieEstimator: aiEstimator,
        nutritionRepository: FakeNutritionRepository(now: () => today),
        now: () => today,
      );

      await provider.searchFood('unknown food');

      expect(provider.results, isEmpty);
      expect(provider.errorMessage, contains('Manuel'));
    });

    test('rebuilds daily summary on add update and delete', () async {
      final repository = FakeNutritionRepository(now: () => today);
      final provider = FoodProvider(
        fatSecretApiService: FatSecretApiService(
          gateway: FakeFunctionsGateway(),
        ),
        aiCalorieEstimator: AiCalorieEstimator(gateway: FakeFunctionsGateway()),
        nutritionRepository: repository,
        now: () => today,
      );
      final userProvider = FakeUserProvider(profile: userProfile);

      await provider.addFood(
        userProvider: userProvider,
        item: const FoodItem(
          name: 'Apple',
          calories: 95,
          protein: 0.5,
          carbs: 25,
          fat: 0.3,
          source: 'fatsecret',
        ),
      );

      final firstSummary = await provider
          .summaryForToday(userProfile.uid)
          .first;
      expect(firstSummary.calories, 95);
      expect(firstSummary.protein, 0.5);

      final storedMeal =
          (await provider.mealsForToday(userProfile.uid).first).single;
      final updatedMeal = storedMeal.copyWith(calories: 120, protein: 1.0);
      await provider.updateFood(userProvider: userProvider, item: updatedMeal);

      final secondSummary = await provider
          .summaryForToday(userProfile.uid)
          .first;
      expect(secondSummary.calories, 120);
      expect(secondSummary.protein, 1.0);

      await provider.deleteFood(userProvider: userProvider, item: updatedMeal);

      final thirdSummary = await provider
          .summaryForToday(userProfile.uid)
          .first;
      expect(thirdSummary.calories, 0);
      expect(thirdSummary.protein, 0);
    });
  });

  group('HealthProvider', () {
    test('calculates BMR and activity multiplier correctly', () {
      expect(
        HealthProvider.calculateBmr(
          weight: 72,
          height: 175,
          age: 25,
          gender: 'male',
        ),
        closeTo(1693.75, 0.01),
      );
      expect(HealthProvider.activityMultiplier('light'), 1.375);
      expect(HealthProvider.activityMultiplier('very_active'), 1.9);
    });

    test('syncProfile updates daily calories from profile data', () {
      final provider = HealthProvider();
      provider.syncProfile(
        const AppUserProfile(
          uid: 'user-1',
          email: 'nudge@example.com',
          name: 'Fit Coach',
          age: 30,
          height: 180,
          weight: 80,
          gender: 'male',
          activity: 'moderate',
        ),
      );

      expect(provider.bmr, closeTo(1780, 0.1));
      expect(provider.dailyCalories, closeTo(2759, 1));
    });

    test('builds extra workout when calorie surplus is high', () {
      final provider = HealthProvider();
      provider.syncProfile(
        const AppUserProfile(
          uid: 'user-1',
          email: 'nudge@example.com',
          name: 'Fit Coach',
          age: 30,
          height: 180,
          weight: 80,
          gender: 'male',
          activity: 'moderate',
          dailyCalories: 2400,
        ),
      );

      final recommendation = provider.workoutRecommendation(
        consumedCalories: 2850,
      );

      expect(recommendation.calorieDelta, 450);
      expect(recommendation.primaryPlan.title, isNotEmpty);
      expect(recommendation.extraPlan, isNotNull);
      expect(recommendation.extraPlan!.estimatedBurn, greaterThan(100));
    });
  });

  group('HydrationProvider', () {
    final today = DateTime(2026, 3, 16);
    const userProfile = AppUserProfile(
      uid: 'user-1',
      email: 'nudge@example.com',
      name: 'Fit Coach',
      age: 25,
      height: 175,
      weight: 72,
      gender: 'male',
      activity: 'light',
      dailyCalories: 2200,
    );

    test('derives hydration target from user weight', () {
      final provider = HydrationProvider(
        hydrationRepository: FakeHydrationRepository(now: () => today),
        now: () => today,
      );

      expect(provider.recommendedGoalMl(userProfile), 2520);
      expect(provider.recommendedGoalMl(null), 2500);
    });

    test(
      'adds and removes hydration entries while keeping summary in sync',
      () async {
        final provider = HydrationProvider(
          hydrationRepository: FakeHydrationRepository(now: () => today),
          now: () => today,
        );
        final userProvider = FakeUserProvider(profile: userProfile);

        await provider.addQuickEntry(
          userProvider: userProvider,
          amountMl: 500,
          label: 'Bottle',
        );

        final firstSummary = await provider
            .summaryForToday(userProfile.uid, profile: userProfile)
            .first;
        expect(firstSummary.totalMl, 500);
        expect(firstSummary.goalMl, 2520);

        final firstEntry =
            (await provider.entriesForToday(userProfile.uid).first).single;
        await provider.deleteEntry(
          userProvider: userProvider,
          entryId: firstEntry.id,
        );

        final secondSummary = await provider
            .summaryForToday(userProfile.uid, profile: userProfile)
            .first;
        expect(secondSummary.totalMl, 0);
      },
    );
  });
}

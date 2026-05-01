import 'package:nudge/providers/daily_insight_provider.dart';
import 'package:nudge/providers/user_provider.dart';
import 'package:nudge/services/daily_insight_engine.dart';
import 'package:nudge/services/daily_insight_repository.dart';
import 'package:nudge/services/daily_narrative_service.dart';
import 'package:nudge/services/functions_gateway.dart';
import 'package:nudge/services/models/daily_hydration_summary.dart';
import 'package:nudge/services/models/daily_insight.dart';
import 'package:nudge/services/models/daily_nutrition_summary.dart';
import 'package:nudge/services/models/food_item.dart';
import 'package:nudge/services/models/smart_nudge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const {'locale_code': 'tr'});
  });

  group('DailyInsightEngine', () {
    final now = DateTime(2026, 3, 16, 21);
    const profile = AppUserProfile(
      uid: 'user-1',
      email: 'nudge@example.com',
      name: 'Nudge User',
      age: 25,
      height: 175,
      weight: 72,
      gender: 'male',
      activity: 'light',
      dailyCalories: 2200,
    );

    test('builds a high consistency score for balanced tracking', () {
      const engine = DailyInsightEngine();
      final insight = engine.build(
        profile: profile,
        summary: const DailyNutritionSummary(
          calories: 2100,
          protein: 120,
          carbs: 220,
          fat: 70,
          updatedAt: null,
        ),
        meals: const [
          FoodItem(
            name: 'Breakfast',
            calories: 500,
            protein: 35,
            carbs: 45,
            fat: 16,
            source: 'manual',
          ),
          FoodItem(
            name: 'Lunch',
            calories: 800,
            protein: 45,
            carbs: 90,
            fat: 24,
            source: 'manual',
          ),
          FoodItem(
            name: 'Dinner',
            calories: 800,
            protein: 40,
            carbs: 85,
            fat: 30,
            source: 'manual',
          ),
        ],
        hydration: DailyHydrationSummary(
          totalMl: 2300,
          goalMl: 2500,
          updatedAt: now,
        ),
        localeCode: 'tr',
        now: now,
      );

      expect(insight.consistencyScore, greaterThanOrEqualTo(90));
      expect(insight.recoveryMode, isFalse);
      expect(insight.breakdown['tracking'], 20);
    });

    test('enables recovery mode for surplus and low protein', () {
      const engine = DailyInsightEngine();
      final insight = engine.build(
        profile: profile,
        summary: const DailyNutritionSummary(
          calories: 3000,
          protein: 30,
          carbs: 360,
          fat: 120,
          updatedAt: null,
        ),
        meals: const [
          FoodItem(
            name: 'Late meal',
            calories: 3000,
            protein: 30,
            carbs: 360,
            fat: 120,
            source: 'manual',
          ),
        ],
        hydration: null,
        localeCode: 'en',
        now: now,
      );

      expect(insight.recoveryMode, isTrue);
      expect(insight.status, 'recovery');
      expect(insight.tomorrowAction, contains('protein'));
    });
  });

  group('SmartNudgeEngine', () {
    final now = DateTime(2026, 3, 16, 14);
    const engine = SmartNudgeEngine();
    final insight = DailyInsight(
      dateKey: '2026-03-16',
      consistencyScore: 60,
      breakdown: const {'protein': 18},
      status: 'building',
      narrative: 'Today is building.',
      positiveSignal: 'Tracking started.',
      riskSignal: 'No meal yet.',
      tomorrowAction: 'Log breakfast.',
      recoveryMode: false,
      generatedAt: now,
    );

    test('does not repeat the same rule on the same day', () {
      final nudge = engine.evaluate(
        insight: insight,
        summary: const DailyNutritionSummary.empty(),
        meals: const <FoodItem>[],
        hydration: null,
        targetCalories: 2200,
        localeCode: 'tr',
        history: SmartNudgeHistory(
          dateKey: '2026-03-16',
          firedRuleIds: const ['meal_gap'],
          lastShownAt: now.subtract(const Duration(hours: 6)),
        ),
        now: now,
      );

      expect(nudge, isNull);
    });

    test('respects daily limit and cooldown', () {
      final limited = engine.evaluate(
        insight: insight,
        summary: const DailyNutritionSummary.empty(),
        meals: const <FoodItem>[],
        hydration: null,
        targetCalories: 2200,
        localeCode: 'tr',
        history: SmartNudgeHistory(
          dateKey: '2026-03-16',
          firedRuleIds: const ['a', 'b', 'c'],
          lastShownAt: now.subtract(const Duration(hours: 6)),
        ),
        now: now,
      );
      final coolingDown = engine.evaluate(
        insight: insight,
        summary: const DailyNutritionSummary.empty(),
        meals: const <FoodItem>[],
        hydration: null,
        targetCalories: 2200,
        localeCode: 'tr',
        history: SmartNudgeHistory(
          dateKey: '2026-03-16',
          firedRuleIds: const <String>[],
          lastShownAt: now.subtract(const Duration(hours: 1)),
        ),
        now: now,
      );

      expect(limited, isNull);
      expect(coolingDown, isNull);
    });
  });

  group('DailyInsightProvider', () {
    test('keeps local narrative when Groq narrative fails', () async {
      final now = DateTime(2026, 3, 16, 21);
      final repository = _MemoryDailyInsightRepository();
      final provider = DailyInsightProvider(
        narrativeService: _FailingDailyNarrativeService(),
        repository: repository,
        now: () => now,
      );
      const profile = AppUserProfile(
        uid: 'user-1',
        email: 'nudge@example.com',
        name: 'Nudge User',
        age: 25,
        height: 175,
        weight: 72,
        gender: 'male',
        activity: 'light',
        dailyCalories: 2200,
      );

      await provider.refreshFromDailyData(
        profile: profile,
        summary: const DailyNutritionSummary(
          calories: 2100,
          protein: 110,
          carbs: 210,
          fat: 70,
          updatedAt: null,
        ),
        meals: const [
          FoodItem(
            name: 'Meal 1',
            calories: 700,
            protein: 40,
            carbs: 80,
            fat: 20,
            source: 'manual',
          ),
          FoodItem(
            name: 'Meal 2',
            calories: 700,
            protein: 35,
            carbs: 70,
            fat: 25,
            source: 'manual',
          ),
          FoodItem(
            name: 'Meal 3',
            calories: 700,
            protein: 35,
            carbs: 60,
            fat: 25,
            source: 'manual',
          ),
        ],
        hydration: DailyHydrationSummary(
          totalMl: 2200,
          goalMl: 2500,
          updatedAt: now,
        ),
        localeCode: 'tr',
      );

      expect(provider.current, isNotNull);
      expect(provider.current!.narrative, contains('İyi giden'));
      expect(repository.saved, isNotNull);
    });
  });
}

class _FailingDailyNarrativeService extends DailyNarrativeService {
  _FailingDailyNarrativeService() : super(gateway: FakeFunctionsGateway());

  @override
  Future<String> polishNarrative({
    required DailyInsight insight,
    required String localeCode,
  }) {
    throw const FunctionGatewayException('dailyNarrative failed');
  }
}

class _MemoryDailyInsightRepository implements DailyInsightRepository {
  DailyInsight? saved;

  @override
  Future<void> saveInsight({
    required String uid,
    required DailyInsight insight,
  }) async {
    saved = insight;
  }

  @override
  Stream<DailyInsight?> insightForDate({
    required String uid,
    required String dateKey,
  }) async* {
    yield saved;
  }
}

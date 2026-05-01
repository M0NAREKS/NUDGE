import '../providers/user_provider.dart';
import '../utils/app_routes.dart';
import 'models/daily_hydration_summary.dart';
import 'models/daily_insight.dart';
import 'models/daily_nutrition_summary.dart';
import 'models/food_item.dart';
import 'models/smart_nudge.dart';

class DailyInsightEngine {
  const DailyInsightEngine();

  DailyInsight build({
    required AppUserProfile profile,
    required DailyNutritionSummary summary,
    required List<FoodItem> meals,
    required DailyHydrationSummary? hydration,
    required String localeCode,
    required DateTime now,
  }) {
    final dateKey = dateKeyFor(now);
    final targetCalories = profile.dailyCalories ?? 0;
    final proteinTarget = proteinTargetFor(profile);
    final calorieScore = _calorieScore(summary.calories, targetCalories);
    final proteinScore = _proteinScore(summary.protein, proteinTarget);
    final mealScore = _mealScore(meals.length);
    final trackingScore = _trackingScore(meals);
    final score = (calorieScore + proteinScore + mealScore + trackingScore)
        .clamp(0, 100);

    final calorieRatio = targetCalories > 0
        ? summary.calories / targetCalories
        : 0;
    final lowProtein =
        proteinTarget > 0 && summary.protein < proteinTarget * 0.45;
    final weakTracking = now.hour >= 20 && meals.length < 2;
    final recoveryMode =
        score < 45 || calorieRatio >= 1.3 || lowProtein || weakTracking;
    final status = recoveryMode
        ? 'recovery'
        : score >= 75
        ? 'on_track'
        : score >= 55
        ? 'building'
        : 'at_risk';
    final positiveSignal = _positiveSignal(
      localeCode: localeCode,
      calorieScore: calorieScore,
      proteinScore: proteinScore,
      mealScore: mealScore,
      hydration: hydration,
    );
    final riskSignal = _riskSignal(
      localeCode: localeCode,
      summary: summary,
      targetCalories: targetCalories,
      proteinTarget: proteinTarget,
      meals: meals,
      hydration: hydration,
      now: now,
    );
    final tomorrowAction = _tomorrowAction(
      localeCode: localeCode,
      recoveryMode: recoveryMode,
      summary: summary,
      targetCalories: targetCalories,
      proteinTarget: proteinTarget,
      meals: meals,
    );

    return DailyInsight(
      dateKey: dateKey,
      consistencyScore: score.round(),
      breakdown: {
        'calories': calorieScore.round(),
        'protein': proteinScore.round(),
        'mealRhythm': mealScore.round(),
        'tracking': trackingScore.round(),
      },
      status: status,
      narrative: _fallbackNarrative(
        localeCode: localeCode,
        positiveSignal: positiveSignal,
        riskSignal: riskSignal,
        tomorrowAction: tomorrowAction,
      ),
      positiveSignal: positiveSignal,
      riskSignal: riskSignal,
      tomorrowAction: tomorrowAction,
      recoveryMode: recoveryMode,
      generatedAt: now,
    );
  }

  static String dateKeyFor(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static double proteinTargetFor(AppUserProfile profile) {
    final weight = profile.weight;
    if (weight == null || weight <= 0) return 100;
    return (weight * 1.6).clamp(75, 180).toDouble();
  }

  double _calorieScore(double consumed, double target) {
    if (target <= 0 || consumed <= 0) return 0;
    final ratio = consumed / target;
    final penalty = ((ratio - 1).abs() / 0.6).clamp(0, 1).toDouble();
    return 35 * (1 - penalty);
  }

  double _proteinScore(double protein, double target) {
    if (target <= 0 || protein <= 0) return 0;
    return (25 * (protein / target).clamp(0, 1)).toDouble();
  }

  double _mealScore(int mealCount) {
    if (mealCount <= 0) return 0;
    if (mealCount == 1) return 8;
    if (mealCount == 2) return 15;
    return 20;
  }

  double _trackingScore(List<FoodItem> meals) {
    if (meals.isEmpty) return 0;
    final estimatedCount = meals.where((meal) => meal.isEstimated).length;
    final estimatedShare = estimatedCount / meals.length;
    final confidenceBonus = estimatedShare <= 0.35
        ? 4
        : estimatedShare <= 0.65
        ? 2
        : 0;
    final rhythmBonus = meals.length >= 2 ? 4 : 0;
    return (12 + rhythmBonus + confidenceBonus).toDouble();
  }

  String _positiveSignal({
    required String localeCode,
    required double calorieScore,
    required double proteinScore,
    required double mealScore,
    required DailyHydrationSummary? hydration,
  }) {
    final isEnglish = localeCode == 'en';
    final hydrationProgress = hydration?.progress ?? 0;
    if (hydrationProgress >= 0.8) {
      return isEnglish ? 'Hydration rhythm is strong.' : 'Su ritmin güçlü.';
    }
    if (proteinScore >= 18) {
      return isEnglish
          ? 'Protein intake is carrying the day.'
          : 'Protein alımın günü taşıyor.';
    }
    if (calorieScore >= 26) {
      return isEnglish
          ? 'Calories are close to the target lane.'
          : 'Kalori hedef çizgisine yakınsın.';
    }
    if (mealScore >= 15) {
      return isEnglish
          ? 'Meal tracking is consistent.'
          : 'Öğün takibin düzenli.';
    }
    return isEnglish
        ? 'You created trackable data today.'
        : 'Bugün takip edilebilir veri oluşturdun.';
  }

  String _riskSignal({
    required String localeCode,
    required DailyNutritionSummary summary,
    required double targetCalories,
    required double proteinTarget,
    required List<FoodItem> meals,
    required DailyHydrationSummary? hydration,
    required DateTime now,
  }) {
    final isEnglish = localeCode == 'en';
    if (targetCalories > 0 && summary.calories > targetCalories * 1.3) {
      return isEnglish
          ? 'Calories moved clearly above target.'
          : 'Kalori hedefin belirgin üstüne çıktı.';
    }
    if (proteinTarget > 0 && summary.protein < proteinTarget * 0.45) {
      return isEnglish
          ? 'Protein is too low for recovery.'
          : 'Protein toparlanma için düşük kaldı.';
    }
    if (now.hour >= 20 && meals.length < 2) {
      return isEnglish
          ? 'Tracking is too thin for a reliable day.'
          : 'Günün güvenilir görünmesi için takip eksik kaldı.';
    }
    if ((hydration?.progress ?? 1) < 0.45 && now.hour >= 17) {
      return isEnglish
          ? 'Water intake is behind the day.'
          : 'Su takibi günün gerisinde kaldı.';
    }
    return isEnglish
        ? 'No major risk is visible right now.'
        : 'Şu an büyük bir risk görünmüyor.';
  }

  String _tomorrowAction({
    required String localeCode,
    required bool recoveryMode,
    required DailyNutritionSummary summary,
    required double targetCalories,
    required double proteinTarget,
    required List<FoodItem> meals,
  }) {
    final isEnglish = localeCode == 'en';
    if (recoveryMode) {
      return isEnglish
          ? 'Start tomorrow with a protein-first breakfast and log it early.'
          : 'Yarın güne protein ağırlıklı bir kahvaltıyla başla ve erken kaydet.';
    }
    if (proteinTarget > 0 && summary.protein < proteinTarget * 0.7) {
      return isEnglish
          ? 'Add one lean protein source before dinner tomorrow.'
          : 'Yarın akşamdan önce bir yağsız protein kaynağı ekle.';
    }
    if (meals.length < 3) {
      return isEnglish
          ? 'Log at least three eating moments tomorrow.'
          : 'Yarın en az üç beslenme anını kaydet.';
    }
    if (targetCalories > 0 && summary.calories < targetCalories * 0.75) {
      return isEnglish
          ? 'Keep lunch stronger so the evening does not carry the load.'
          : 'Akşam yük binmesin diye öğle öğününü daha güçlü tut.';
    }
    return isEnglish
        ? 'Repeat today’s tracking rhythm and keep protein visible.'
        : 'Bugünkü takip ritmini tekrarla ve proteini görünür tut.';
  }

  String _fallbackNarrative({
    required String localeCode,
    required String positiveSignal,
    required String riskSignal,
    required String tomorrowAction,
  }) {
    if (localeCode == 'en') {
      return 'Good: $positiveSignal Risk: $riskSignal Tomorrow: $tomorrowAction';
    }
    return 'İyi giden: $positiveSignal Risk: $riskSignal Yarın: $tomorrowAction';
  }
}

class SmartNudgeEngine {
  const SmartNudgeEngine();

  SmartNudge? evaluate({
    required DailyInsight insight,
    required DailyNutritionSummary summary,
    required List<FoodItem> meals,
    required DailyHydrationSummary? hydration,
    required double targetCalories,
    required String localeCode,
    required SmartNudgeHistory history,
    required DateTime now,
  }) {
    final candidates = <SmartNudge>[
      if (insight.recoveryMode)
        _nudge(
          ruleId: 'recovery_reset',
          localeCode: localeCode,
          trTitle: 'Toparlanma planı hazır',
          trBody: 'Bugünü kapatmak için tek aksiyon: ${insight.tomorrowAction}',
          enTitle: 'Recovery plan is ready',
          enBody: 'One clear action: ${insight.tomorrowAction}',
          route: AppRoutes.home,
        ),
      if (now.hour >= 14 && meals.isEmpty)
        _nudge(
          ruleId: 'meal_gap',
          localeCode: localeCode,
          trTitle: 'İlk öğünü kaçırma',
          trBody:
              'Bugün henüz öğün yok. Küçük bir proteinli öğünle ritmi başlat.',
          enTitle: 'Do not miss the first meal',
          enBody: 'No meal is logged yet. Start with a small protein-led meal.',
          route: AppRoutes.food,
        ),
      if (now.hour >= 17 &&
          targetCalories > 0 &&
          summary.calories < targetCalories * 0.55)
        _nudge(
          ruleId: 'evening_risk',
          localeCode: localeCode,
          trTitle: 'Akşam yükünü azalt',
          trBody:
              'Kalori günün gerisinde. Akşamı kontrol etmek için dengeli bir öğün planla.',
          enTitle: 'Reduce evening load',
          enBody:
              'Calories are behind the day. Plan a balanced meal before evening pressure builds.',
          route: AppRoutes.food,
        ),
      if (now.hour >= 16 &&
          insight.breakdown['protein'] != null &&
          insight.breakdown['protein']! < 14)
        _nudge(
          ruleId: 'protein_gap',
          localeCode: localeCode,
          trTitle: 'Protein açığını kapat',
          trBody:
              'Bugün protein düşük. Bir protein kaynağı eklemek skoru toparlar.',
          enTitle: 'Close the protein gap',
          enBody:
              'Protein is low today. Add one protein source to recover the score.',
          route: AppRoutes.food,
        ),
      if (now.hour >= 15 && (hydration?.progress ?? 1) < 0.45)
        _nudge(
          ruleId: 'hydration_gap',
          localeCode: localeCode,
          trTitle: 'Su ritmini yakala',
          trBody:
              'Su hedefinin gerisindesin. Bir şişe su ekleyerek ritmi toparla.',
          enTitle: 'Catch up on water',
          enBody:
              'You are behind the water target. Add one bottle to recover rhythm.',
          route: AppRoutes.hydration,
        ),
    ];

    for (final candidate in candidates) {
      if (history.canShow(candidate.ruleId, now)) {
        return candidate;
      }
    }
    return null;
  }

  SmartNudge _nudge({
    required String ruleId,
    required String localeCode,
    required String trTitle,
    required String trBody,
    required String enTitle,
    required String enBody,
    required String route,
  }) {
    final isEnglish = localeCode == 'en';
    return SmartNudge(
      ruleId: ruleId,
      title: isEnglish ? enTitle : trTitle,
      body: isEnglish ? enBody : trBody,
      route: route,
    );
  }
}

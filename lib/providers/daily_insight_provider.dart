import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/app_analytics.dart';
import '../services/daily_insight_engine.dart';
import '../services/daily_insight_repository.dart';
import '../services/daily_narrative_service.dart';
import '../services/local_storage_service.dart';
import '../services/models/daily_hydration_summary.dart';
import '../services/models/daily_insight.dart';
import '../services/models/daily_nutrition_summary.dart';
import '../services/models/food_item.dart';
import '../services/models/notification_payload.dart';
import '../services/notification_service.dart';
import 'user_provider.dart';

class DailyInsightProvider extends ChangeNotifier {
  DailyInsightProvider({
    NotificationService? notificationService,
    DailyInsightEngine? engine,
    SmartNudgeEngine? nudgeEngine,
    DailyNarrativeService? narrativeService,
    DailyInsightRepository? repository,
    AppAnalytics? analytics,
    DateTime Function()? now,
  }) : _notificationService = notificationService,
       _engine = engine ?? const DailyInsightEngine(),
       _nudgeEngine = nudgeEngine ?? const SmartNudgeEngine(),
       _narrativeService = narrativeService ?? DailyNarrativeService(),
       _repository = repository ?? FirestoreDailyInsightRepository(),
       _analytics = analytics,
       _now = now ?? DateTime.now;

  final NotificationService? _notificationService;
  final DailyInsightEngine _engine;
  final SmartNudgeEngine _nudgeEngine;
  final DailyNarrativeService _narrativeService;
  final DailyInsightRepository _repository;
  final AppAnalytics? _analytics;
  final DateTime Function() _now;

  DailyInsight? _current;
  String? _lastSignature;
  bool _refreshing = false;

  DailyInsight? get current => _current;
  bool get isRefreshing => _refreshing;

  DailyInsight buildLocalInsight({
    required AppUserProfile profile,
    required DailyNutritionSummary summary,
    required List<FoodItem> meals,
    required DailyHydrationSummary? hydration,
    required String localeCode,
  }) {
    return _engine.build(
      profile: profile,
      summary: summary,
      meals: meals,
      hydration: hydration,
      localeCode: localeCode,
      now: _now(),
    );
  }

  Future<void> refreshFromDailyData({
    required AppUserProfile profile,
    required DailyNutritionSummary summary,
    required List<FoodItem> meals,
    required DailyHydrationSummary? hydration,
    required String localeCode,
  }) async {
    final localInsight = buildLocalInsight(
      profile: profile,
      summary: summary,
      meals: meals,
      hydration: hydration,
      localeCode: localeCode,
    );
    final signature = _signature(
      insight: localInsight,
      summary: summary,
      meals: meals,
      hydration: hydration,
      localeCode: localeCode,
    );
    if (_lastSignature == signature) {
      return;
    }

    _lastSignature = signature;
    _current = localInsight;
    _refreshing = true;
    notifyListeners();

    await _maybeShowSmartNudge(
      insight: localInsight,
      summary: summary,
      meals: meals,
      hydration: hydration,
      targetCalories: profile.dailyCalories ?? 0,
      localeCode: localeCode,
    );

    var finalInsight = localInsight;
    try {
      final narrative = await _narrativeService.polishNarrative(
        insight: localInsight,
        localeCode: localeCode,
      );
      finalInsight = localInsight.copyWith(narrative: narrative);
    } catch (_) {
      // Local narrative is deliberately good enough for offline and Groq errors.
    }

    try {
      await _repository.saveInsight(uid: profile.uid, insight: finalInsight);
    } catch (_) {
      // Insights are useful but should never block the dashboard.
    }

    _current = finalInsight;
    _refreshing = false;
    notifyListeners();

    await _analytics?.logEvent('daily_insight_generated', {
      'score': finalInsight.consistencyScore,
      'status': finalInsight.status,
      'recovery_mode': finalInsight.recoveryMode,
    });
  }

  Future<void> _maybeShowSmartNudge({
    required DailyInsight insight,
    required DailyNutritionSummary summary,
    required List<FoodItem> meals,
    required DailyHydrationSummary? hydration,
    required double targetCalories,
    required String localeCode,
  }) async {
    final settings = await LocalStorageService.getAppSettings();
    final preferences = settings.notificationPreferences;
    if (!preferences.enabled || !preferences.smartNudges) return;
    final notificationService = _notificationService;
    if (notificationService == null) return;

    final now = _now();
    final history = await LocalStorageService.getSmartNudgeHistory(
      insight.dateKey,
    );
    final nudge = _nudgeEngine.evaluate(
      insight: insight,
      summary: summary,
      meals: meals,
      hydration: hydration,
      targetCalories: targetCalories,
      localeCode: localeCode,
      history: history,
      now: now,
    );
    if (nudge == null) return;

    final shown = await notificationService.showSmartNudge(
      NotificationPayload(
        type: nudge.type,
        route: nudge.route,
        title: nudge.title,
        body: nudge.body,
      ),
    );
    if (!shown) return;

    await LocalStorageService.saveSmartNudgeHistory(
      history.record(nudge.ruleId, now),
    );
    await _analytics?.logEvent('smart_nudge_shown', {
      'rule_id': nudge.ruleId,
      'route': nudge.route,
    });
  }

  String _signature({
    required DailyInsight insight,
    required DailyNutritionSummary summary,
    required List<FoodItem> meals,
    required DailyHydrationSummary? hydration,
    required String localeCode,
  }) {
    final mealSignature = meals
        .map(
          (meal) =>
              '${meal.id}:${meal.calories}:${meal.protein}:${meal.isEstimated}',
        )
        .join('|');
    return [
      insight.dateKey,
      localeCode,
      summary.calories.toStringAsFixed(1),
      summary.protein.toStringAsFixed(1),
      summary.carbs.toStringAsFixed(1),
      summary.fat.toStringAsFixed(1),
      hydration?.totalMl ?? 0,
      hydration?.goalMl ?? 0,
      mealSignature,
    ].join('::');
  }
}

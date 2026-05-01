import 'package:flutter/foundation.dart';

import '../services/app_analytics.dart';
import '../services/hydration_repository.dart';
import '../services/models/daily_hydration_summary.dart';
import '../services/models/hydration_entry.dart';
import 'user_provider.dart';

class HydrationProvider extends ChangeNotifier {
  HydrationProvider({
    HydrationRepository? hydrationRepository,
    AppAnalytics? analytics,
    DateTime Function()? now,
  })  : _hydrationRepository =
            hydrationRepository ?? FirestoreHydrationRepository(),
        _analytics = analytics,
        _now = now ?? DateTime.now;

  final HydrationRepository _hydrationRepository;
  final AppAnalytics? _analytics;
  final DateTime Function() _now;

  bool _saving = false;
  String? _errorMessage;

  bool get isSaving => _saving;
  String? get errorMessage => _errorMessage;

  int recommendedGoalMl(AppUserProfile? profile) {
    final weight = profile?.weight;
    if (weight == null || weight <= 0) return 2500;
    final recommendation = (weight * 35).round();
    return recommendation.clamp(1800, 4200).toInt();
  }

  Stream<DailyHydrationSummary> summaryForToday(
    String uid, {
    AppUserProfile? profile,
  }) {
    final fallbackGoalMl = recommendedGoalMl(profile);
    return _hydrationRepository.summaryForDate(uid, _now()).map(
      (summary) => summary.updatedAt.millisecondsSinceEpoch == 0
          ? summary.copyWith(goalMl: fallbackGoalMl)
          : summary,
    );
  }

  Stream<List<HydrationEntry>> entriesForToday(String uid) {
    return _hydrationRepository.entriesForDate(uid, _now());
  }

  Future<void> addQuickEntry({
    required UserProvider userProvider,
    required int amountMl,
    required String label,
  }) async {
    final profile = userProvider.profile;
    if (profile == null) return;
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _hydrationRepository.addEntry(
        uid: profile.uid,
        date: _now(),
        entry: HydrationEntry(
          amountMl: amountMl,
          label: label,
          createdAt: _now(),
        ),
        fallbackGoalMl: recommendedGoalMl(profile),
      );
      await _analytics?.logEvent(
        'hydration_entry_added',
        {
          'amount_ml': amountMl,
          'label': label,
        },
      );
    } catch (error) {
      _errorMessage = '$error';
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry({
    required UserProvider userProvider,
    required String entryId,
  }) async {
    final profile = userProvider.profile;
    if (profile == null || entryId.trim().isEmpty) return;
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _hydrationRepository.deleteEntry(
        uid: profile.uid,
        date: _now(),
        entryId: entryId,
        fallbackGoalMl: recommendedGoalMl(profile),
      );
      await _analytics?.logEvent('hydration_entry_deleted');
    } catch (error) {
      _errorMessage = '$error';
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> updateGoal({
    required UserProvider userProvider,
    required int goalMl,
  }) async {
    final profile = userProvider.profile;
    if (profile == null) return;
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _hydrationRepository.setGoal(
        uid: profile.uid,
        date: _now(),
        goalMl: goalMl.clamp(1000, 6000).toInt(),
      );
      await _analytics?.logEvent(
        'hydration_goal_updated',
        {'goal_ml': goalMl},
      );
    } catch (error) {
      _errorMessage = '$error';
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:nudge/providers/user_provider.dart';
import 'package:nudge/services/functions_gateway.dart';
import 'package:nudge/services/hydration_repository.dart';
import 'package:nudge/services/models/daily_nutrition_summary.dart';
import 'package:nudge/services/models/daily_hydration_summary.dart';
import 'package:nudge/services/models/food_item.dart';
import 'package:nudge/services/models/hydration_entry.dart';
import 'package:nudge/services/nutrition_repository.dart';

class FakeFunctionsGateway implements FunctionsGateway {
  FakeFunctionsGateway({this.getHandler, this.postHandler});

  final Future<Map<String, dynamic>> Function(
    String functionName,
    Map<String, String>? queryParameters,
  )?
  getHandler;
  final Future<Map<String, dynamic>> Function(
    String functionName,
    Map<String, dynamic>? body,
  )?
  postHandler;

  @override
  Future<Map<String, dynamic>> getJson(
    String functionName, {
    Map<String, String>? queryParameters,
  }) async {
    if (getHandler == null) {
      return <String, dynamic>{};
    }
    return getHandler!(functionName, queryParameters);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String functionName, {
    Map<String, dynamic>? body,
  }) async {
    if (postHandler == null) {
      return <String, dynamic>{};
    }
    return postHandler!(functionName, body);
  }
}

class FakeNutritionRepository implements NutritionRepository {
  FakeNutritionRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, List<FoodItem>> _meals = <String, List<FoodItem>>{};
  final Map<String, StreamController<List<FoodItem>>> _mealControllers =
      <String, StreamController<List<FoodItem>>>{};
  final Map<String, StreamController<DailyNutritionSummary>>
  _summaryControllers = <String, StreamController<DailyNutritionSummary>>{};
  int _idCounter = 0;

  void seed({
    required String uid,
    required DateTime date,
    required List<FoodItem> meals,
  }) {
    final key = _key(uid, date);
    _meals[key] = meals;
    _emit(uid, date);
  }

  @override
  Future<void> addFood({
    required String uid,
    required DateTime date,
    required FoodItem item,
  }) async {
    final key = _key(uid, date);
    final nextMeals = List<FoodItem>.from(_meals[key] ?? const <FoodItem>[])
      ..add(
        item.copyWith(
          id: item.id.isEmpty ? 'meal_${_idCounter++}' : item.id,
          createdAt: _now(),
        ),
      );
    _meals[key] = nextMeals;
    await rebuildDailySummary(uid: uid, date: date);
  }

  @override
  Future<void> updateFood({
    required String uid,
    required DateTime date,
    required FoodItem item,
  }) async {
    final key = _key(uid, date);
    final existing = List<FoodItem>.from(_meals[key] ?? const <FoodItem>[]);
    final index = existing.indexWhere((meal) => meal.id == item.id);
    if (index >= 0) {
      existing[index] = item;
      _meals[key] = existing;
    }
    await rebuildDailySummary(uid: uid, date: date);
  }

  @override
  Future<void> deleteFood({
    required String uid,
    required DateTime date,
    required String foodId,
  }) async {
    final key = _key(uid, date);
    _meals[key] = List<FoodItem>.from(_meals[key] ?? const <FoodItem>[])
      ..removeWhere((meal) => meal.id == foodId);
    await rebuildDailySummary(uid: uid, date: date);
  }

  @override
  Future<DailyNutritionSummary> rebuildDailySummary({
    required String uid,
    required DateTime date,
  }) async {
    final summary = DailyNutritionSummaryCalculator.calculate(
      _meals[_key(uid, date)] ?? const <FoodItem>[],
    );
    _emit(uid, date, summary: summary);
    return summary;
  }

  @override
  Stream<List<FoodItem>> mealsForDate(String uid, DateTime date) async* {
    final key = _key(uid, date);
    _ensureControllers(key);
    yield List<FoodItem>.unmodifiable(_meals[key] ?? const <FoodItem>[]);
    yield* _mealControllers[key]!.stream;
  }

  @override
  Stream<DailyNutritionSummary> summaryForDate(
    String uid,
    DateTime date,
  ) async* {
    final key = _key(uid, date);
    _ensureControllers(key);
    yield DailyNutritionSummaryCalculator.calculate(
      _meals[key] ?? const <FoodItem>[],
    );
    yield* _summaryControllers[key]!.stream;
  }

  void _emit(String uid, DateTime date, {DailyNutritionSummary? summary}) {
    final key = _key(uid, date);
    _ensureControllers(key);
    final meals = List<FoodItem>.unmodifiable(
      _meals[key] ?? const <FoodItem>[],
    );
    _mealControllers[key]!.add(meals);
    _summaryControllers[key]!.add(
      summary ?? DailyNutritionSummaryCalculator.calculate(meals),
    );
  }

  void _ensureControllers(String key) {
    _mealControllers.putIfAbsent(
      key,
      () => StreamController<List<FoodItem>>.broadcast(),
    );
    _summaryControllers.putIfAbsent(
      key,
      () => StreamController<DailyNutritionSummary>.broadcast(),
    );
  }

  String _key(String uid, DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$uid-${date.year}-$month-$day';
  }
}

class FakeHydrationRepository implements HydrationRepository {
  FakeHydrationRepository({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, List<HydrationEntry>> _entries =
      <String, List<HydrationEntry>>{};
  final Map<String, int> _goals = <String, int>{};
  final Map<String, StreamController<List<HydrationEntry>>> _entryControllers =
      <String, StreamController<List<HydrationEntry>>>{};
  final Map<String, StreamController<DailyHydrationSummary>>
  _summaryControllers = <String, StreamController<DailyHydrationSummary>>{};
  int _idCounter = 0;

  @override
  Future<void> addEntry({
    required String uid,
    required DateTime date,
    required HydrationEntry entry,
    required int fallbackGoalMl,
  }) async {
    final key = _key(uid, date);
    _goals.putIfAbsent(key, () => fallbackGoalMl);
    final nextEntries =
        List<HydrationEntry>.from(_entries[key] ?? const <HydrationEntry>[])
          ..add(
            entry.copyWith(
              id: entry.id.isEmpty ? 'water_${_idCounter++}' : entry.id,
              createdAt: _now(),
            ),
          );
    _entries[key] = nextEntries;
    _emit(uid, date);
  }

  @override
  Future<void> deleteEntry({
    required String uid,
    required DateTime date,
    required String entryId,
    required int fallbackGoalMl,
  }) async {
    final key = _key(uid, date);
    _goals.putIfAbsent(key, () => fallbackGoalMl);
    _entries[key] = List<HydrationEntry>.from(
      _entries[key] ?? const <HydrationEntry>[],
    )..removeWhere((entry) => entry.id == entryId);
    _emit(uid, date);
  }

  @override
  Future<void> setGoal({
    required String uid,
    required DateTime date,
    required int goalMl,
  }) async {
    _goals[_key(uid, date)] = goalMl;
    _emit(uid, date);
  }

  @override
  Stream<List<HydrationEntry>> entriesForDate(
    String uid,
    DateTime date,
  ) async* {
    final key = _key(uid, date);
    _ensureControllers(key);
    yield List<HydrationEntry>.unmodifiable(
      _entries[key] ?? const <HydrationEntry>[],
    );
    yield* _entryControllers[key]!.stream;
  }

  @override
  Stream<DailyHydrationSummary> summaryForDate(
    String uid,
    DateTime date,
  ) async* {
    final key = _key(uid, date);
    _ensureControllers(key);
    yield _summary(uid, date);
    yield* _summaryControllers[key]!.stream;
  }

  void _emit(String uid, DateTime date) {
    final key = _key(uid, date);
    _ensureControllers(key);
    _entryControllers[key]!.add(
      List<HydrationEntry>.unmodifiable(
        _entries[key] ?? const <HydrationEntry>[],
      ),
    );
    _summaryControllers[key]!.add(_summary(uid, date));
  }

  DailyHydrationSummary _summary(String uid, DateTime date) {
    final key = _key(uid, date);
    final totalMl = (_entries[key] ?? const <HydrationEntry>[]).fold<int>(
      0,
      (sum, entry) => sum + entry.amountMl,
    );
    return DailyHydrationSummary(
      totalMl: totalMl,
      goalMl: _goals[key] ?? 2500,
      updatedAt: _now(),
    );
  }

  void _ensureControllers(String key) {
    _entryControllers.putIfAbsent(
      key,
      () => StreamController<List<HydrationEntry>>.broadcast(),
    );
    _summaryControllers.putIfAbsent(
      key,
      () => StreamController<DailyHydrationSummary>.broadcast(),
    );
  }

  String _key(String uid, DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$uid-${date.year}-$month-$day';
  }
}

class FakeUserProvider extends ChangeNotifier implements UserProvider {
  FakeUserProvider({
    AppUserProfile? profile,
    bool loggedIn = false,
    bool ready = true,
    bool loading = false,
  }) : _profile = profile,
       _loggedIn = loggedIn || profile != null,
       _ready = ready,
       _loading = loading;

  AppUserProfile? _profile;
  bool _loggedIn;
  final bool _ready;
  final bool _loading;

  @override
  User? get firebaseUser => null;

  @override
  AppUserProfile? get profile => _profile;

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  bool get isLoading => _loading;

  @override
  bool get isReady => _ready;

  @override
  bool get hasCompleteProfile => _profile?.isComplete ?? false;

  void setProfile(AppUserProfile? profile) {
    _profile = profile;
    _loggedIn = profile != null;
    notifyListeners();
  }

  @override
  Future<void> initGoogleSignIn() async {}

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {}

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> loginWithGoogle() async {}

  @override
  Future<void> logout() async {
    _loggedIn = false;
    _profile = null;
    notifyListeners();
  }

  @override
  Future<void> updateProfile({
    String? name,
    DateTime? birthDate,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? activity,
    double? bmr,
    double? dailyCalories,
  }) async {
    final current = _profile;
    if (current == null) return;
    _profile = current.copyWith(
      name: name,
      birthDate: birthDate,
      age: age,
      height: height,
      weight: weight,
      gender: gender,
      activity: activity,
      bmr: bmr,
      dailyCalories: dailyCalories,
    );
    notifyListeners();
  }
}

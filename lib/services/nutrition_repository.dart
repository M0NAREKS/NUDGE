import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'models/daily_nutrition_summary.dart';
import 'models/food_item.dart';

class DailyNutritionSummaryCalculator {
  static DailyNutritionSummary calculate(Iterable<FoodItem> meals) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.protein;
      carbs += meal.carbs;
      fat += meal.fat;
    }

    return DailyNutritionSummary(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      updatedAt: DateTime.now(),
    );
  }
}

abstract class NutritionRepository {
  Future<void> addFood({
    required String uid,
    required DateTime date,
    required FoodItem item,
  });

  Future<void> updateFood({
    required String uid,
    required DateTime date,
    required FoodItem item,
  });

  Future<void> deleteFood({
    required String uid,
    required DateTime date,
    required String foodId,
  });

  Future<DailyNutritionSummary> rebuildDailySummary({
    required String uid,
    required DateTime date,
  });

  Stream<List<FoodItem>> mealsForDate(String uid, DateTime date);

  Stream<DailyNutritionSummary> summaryForDate(String uid, DateTime date);
}

class FirestoreNutritionRepository implements NutritionRepository {
  FirestoreNutritionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, StreamController<List<FoodItem>>> _mealControllers =
      <String, StreamController<List<FoodItem>>>{};
  final Map<String, StreamController<DailyNutritionSummary>> _summaryControllers =
      <String, StreamController<DailyNutritionSummary>>{};

  @override
  Future<void> addFood({
    required String uid,
    required DateTime date,
    required FoodItem item,
  }) async {
    final mealsCollection = _mealsCollection(uid, date);
    final mealDoc = item.id.isEmpty ? mealsCollection.doc() : mealsCollection.doc(item.id);
    final mealData = item.copyWith(id: mealDoc.id).toMap()
      ..['createdAt'] = FieldValue.serverTimestamp();

    await mealDoc.set(mealData, SetOptions(merge: true));
    await rebuildDailySummary(uid: uid, date: date);
    await _refreshWebStreams(uid, date);
  }

  @override
  Future<void> updateFood({
    required String uid,
    required DateTime date,
    required FoodItem item,
  }) async {
    if (item.id.isEmpty) {
      throw ArgumentError('Food id is required for updates.');
    }

    await _mealsCollection(uid, date).doc(item.id).set(
          item.toMap(),
          SetOptions(merge: true),
        );
    await rebuildDailySummary(uid: uid, date: date);
    await _refreshWebStreams(uid, date);
  }

  @override
  Future<void> deleteFood({
    required String uid,
    required DateTime date,
    required String foodId,
  }) async {
    await _mealsCollection(uid, date).doc(foodId).delete();
    await rebuildDailySummary(uid: uid, date: date);
    await _refreshWebStreams(uid, date);
  }

  @override
  Future<DailyNutritionSummary> rebuildDailySummary({
    required String uid,
    required DateTime date,
  }) async {
    final mealsSnapshot = await _mealsCollection(uid, date).get();
    final meals = mealsSnapshot.docs
        .map((doc) => FoodItem.fromMap(doc.data(), id: doc.id))
        .toList();
    final summary = DailyNutritionSummaryCalculator.calculate(meals);

    await _summaryDocument(uid, date).set(
      {
        ...summary.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return summary;
  }

  @override
  Stream<List<FoodItem>> mealsForDate(String uid, DateTime date) {
    if (!kIsWeb) {
      return _mealsCollection(uid, date)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FoodItem.fromMap(doc.data(), id: doc.id))
                .toList(),
          );
    }

    final key = _streamKey(uid, date);
    final controller = _mealControllers.putIfAbsent(
      key,
      () => StreamController<List<FoodItem>>.broadcast(
        onListen: () {
          unawaited(_refreshWebStreams(uid, date));
        },
      ),
    );
    unawaited(_refreshWebStreams(uid, date));
    return controller.stream;
  }

  @override
  Stream<DailyNutritionSummary> summaryForDate(String uid, DateTime date) {
    if (!kIsWeb) {
      return _summaryDocument(uid, date)
          .snapshots()
          .map((snapshot) => DailyNutritionSummary.fromMap(snapshot.data()));
    }

    final key = _streamKey(uid, date);
    final controller = _summaryControllers.putIfAbsent(
      key,
      () => StreamController<DailyNutritionSummary>.broadcast(
        onListen: () {
          unawaited(_refreshWebStreams(uid, date));
        },
      ),
    );
    unawaited(_refreshWebStreams(uid, date));
    return controller.stream;
  }

  Future<void> _refreshWebStreams(String uid, DateTime date) async {
    if (!kIsWeb) return;

    final key = _streamKey(uid, date);
    final mealController = _mealControllers[key];
    final summaryController = _summaryControllers[key];
    if (mealController == null && summaryController == null) {
      return;
    }

    try {
      final mealsSnapshot = await _mealsCollection(uid, date)
          .orderBy('createdAt', descending: true)
          .get();
      final meals = mealsSnapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data(), id: doc.id))
          .toList();
      final summarySnapshot = await _summaryDocument(uid, date).get();
      final summary = DailyNutritionSummary.fromMap(summarySnapshot.data());

      mealController?.add(meals);
      summaryController?.add(summary);
    } on FirebaseException catch (error) {
      debugPrint('Nutrition web refresh failed: ${error.code} ${error.message}');
      if (error.code == 'permission-denied') {
        mealController?.add(const <FoodItem>[]);
        summaryController?.add(const DailyNutritionSummary.empty());
        return;
      }
      rethrow;
    }
  }

  CollectionReference<Map<String, dynamic>> _mealsCollection(
    String uid,
    DateTime date,
  ) {
    return _summaryDocument(uid, date).collection('meals');
  }

  DocumentReference<Map<String, dynamic>> _summaryDocument(
    String uid,
    DateTime date,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('nutrition')
        .doc(_dateKey(date));
  }

  String _streamKey(String uid, DateTime date) {
    return '$uid:${_dateKey(date)}';
  }

  String _dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

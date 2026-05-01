import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/daily_insight.dart';

abstract class DailyInsightRepository {
  Future<void> saveInsight({
    required String uid,
    required DailyInsight insight,
  });

  Stream<DailyInsight?> insightForDate({
    required String uid,
    required String dateKey,
  });
}

class FirestoreDailyInsightRepository implements DailyInsightRepository {
  FirestoreDailyInsightRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> saveInsight({
    required String uid,
    required DailyInsight insight,
  }) async {
    await _insightDocument(uid, insight.dateKey).set({
      ...insight.toMap(),
      'generatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Stream<DailyInsight?> insightForDate({
    required String uid,
    required String dateKey,
  }) {
    return _insightDocument(uid, dateKey).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return DailyInsight.fromMap(data);
    });
  }

  DocumentReference<Map<String, dynamic>> _insightDocument(
    String uid,
    String dateKey,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('dailyInsights')
        .doc(dateKey);
  }
}

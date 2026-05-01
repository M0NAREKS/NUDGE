import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'models/daily_hydration_summary.dart';
import 'models/hydration_entry.dart';

abstract class HydrationRepository {
  Future<void> addEntry({
    required String uid,
    required DateTime date,
    required HydrationEntry entry,
    required int fallbackGoalMl,
  });

  Future<void> deleteEntry({
    required String uid,
    required DateTime date,
    required String entryId,
    required int fallbackGoalMl,
  });

  Future<void> setGoal({
    required String uid,
    required DateTime date,
    required int goalMl,
  });

  Stream<DailyHydrationSummary> summaryForDate(String uid, DateTime date);

  Stream<List<HydrationEntry>> entriesForDate(String uid, DateTime date);
}

class FirestoreHydrationRepository implements HydrationRepository {
  FirestoreHydrationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> addEntry({
    required String uid,
    required DateTime date,
    required HydrationEntry entry,
    required int fallbackGoalMl,
  }) async {
    final entries = _entriesCollection(uid, date);
    final doc = entry.id.isEmpty ? entries.doc() : entries.doc(entry.id);
    await doc.set(
      {
        'amountMl': entry.amountMl,
        'label': entry.label,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _rebuildDailySummary(
      uid: uid,
      date: date,
      fallbackGoalMl: fallbackGoalMl,
    );
  }

  @override
  Future<void> deleteEntry({
    required String uid,
    required DateTime date,
    required String entryId,
    required int fallbackGoalMl,
  }) async {
    await _entriesCollection(uid, date).doc(entryId).delete();
    await _rebuildDailySummary(
      uid: uid,
      date: date,
      fallbackGoalMl: fallbackGoalMl,
    );
  }

  @override
  Future<void> setGoal({
    required String uid,
    required DateTime date,
    required int goalMl,
  }) async {
    final summaryDoc = _summaryDocument(uid, date);
    final current = await summaryDoc.get();
    final currentSummary = DailyHydrationSummary.fromMap(current.data());
    final nextSummary = currentSummary.copyWith(
      goalMl: goalMl,
      updatedAt: DateTime.now(),
    );

    await summaryDoc.set(
      {
        'totalMl': nextSummary.totalMl,
        'goalMl': nextSummary.goalMl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _sharedStatusDocument(uid, date).set(
      {
        'waterMl': nextSummary.totalMl,
        'waterGoalMl': nextSummary.goalMl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Stream<DailyHydrationSummary> summaryForDate(String uid, DateTime date) {
    return _summaryDocument(uid, date).snapshots().map(
          (snapshot) => DailyHydrationSummary.fromMap(snapshot.data()),
        );
  }

  @override
  Stream<List<HydrationEntry>> entriesForDate(String uid, DateTime date) {
    return _entriesCollection(uid, date)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HydrationEntry.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> _rebuildDailySummary({
    required String uid,
    required DateTime date,
    required int fallbackGoalMl,
  }) async {
    final entrySnapshot = await _entriesCollection(uid, date).get();
    final currentSummarySnapshot = await _summaryDocument(uid, date).get();
    final currentSummary = DailyHydrationSummary.fromMap(
      currentSummarySnapshot.data(),
    );
    final totalMl = entrySnapshot.docs.fold<int>(
      0,
      (currentTotal, doc) =>
          currentTotal + ((doc.data()['amountMl'] as num?)?.round() ?? 0),
    );
    final goalMl = currentSummary.goalMl > 0
        ? currentSummary.goalMl
        : fallbackGoalMl;

    await _summaryDocument(uid, date).set(
      {
        'totalMl': totalMl,
        'goalMl': goalMl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await _sharedStatusDocument(uid, date).set(
      {
        'waterMl': totalMl,
        'waterGoalMl': goalMl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  CollectionReference<Map<String, dynamic>> _entriesCollection(
    String uid,
    DateTime date,
  ) {
    return _summaryDocument(uid, date).collection('entries');
  }

  DocumentReference<Map<String, dynamic>> _summaryDocument(
    String uid,
    DateTime date,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('hydration')
        .doc(_dateKey(date));
  }

  DocumentReference<Map<String, dynamic>> _sharedStatusDocument(
    String uid,
    DateTime date,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sharedDailyStatus')
        .doc(_dateKey(date));
  }

  String _dateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class PushTokenRepository {
  PushTokenRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> upsertToken({
    required String uid,
    required String provider,
    required String token,
    required String platform,
    required String localeCode,
    required bool notificationsEnabled,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('pushTokens')
        .doc('${provider}_$platform')
        .set(
      {
        'provider': provider,
        'token': token,
        'platform': platform,
        'localeCode': localeCode,
        'notificationsEnabled': notificationsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> setNotificationsEnabledForUser({
    required String uid,
    required bool enabled,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('pushTokens')
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }
}

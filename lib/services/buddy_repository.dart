import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../providers/user_provider.dart';
import 'functions_gateway.dart';
import 'models/buddy_connection.dart';
import 'models/buddy_request.dart';
import 'models/shared_daily_status.dart';

abstract class BuddyRepository {
  Future<void> sendRequest({
    required AppUserProfile currentUser,
    required String buddyEmail,
  });

  Future<void> acceptRequest({
    required BuddyRequest request,
  });

  Future<void> declineRequest(BuddyRequest request);

  Stream<List<BuddyRequest>> incomingRequests(String uid);

  Stream<List<BuddyConnection>> buddies(String uid);

  Stream<SharedDailyStatus> sharedStatusForDate(String uid, DateTime date);

  Future<void> sendNudge({
    required BuddyConnection buddy,
    required String localeCode,
  });
}

class FirestoreBuddyRepository implements BuddyRepository {
  FirestoreBuddyRepository({
    FirebaseFirestore? firestore,
    FunctionsGateway? functionsGateway,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functionsGateway = functionsGateway ?? FirebaseFunctionsGateway();

  final FirebaseFirestore _firestore;
  final FunctionsGateway _functionsGateway;

  @override
  Future<void> sendRequest({
    required AppUserProfile currentUser,
    required String buddyEmail,
  }) async {
    final normalizedEmail = buddyEmail.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Buddy email is required.');
    }
    if (normalizedEmail == currentUser.email.trim().toLowerCase()) {
      throw Exception('You cannot add yourself as a buddy.');
    }

    final targetSnapshot = await _firestore
        .collection('userDirectory')
        .where('emailLower', isEqualTo: normalizedEmail)
        .limit(1)
        .get();
    if (targetSnapshot.docs.isEmpty) {
      throw Exception('No user was found with this email address.');
    }

    final targetDoc = targetSnapshot.docs.first;
    final targetUid = targetDoc.id;
    final targetName = targetDoc.data()['name'] as String? ?? '';
    final targetEmail = targetDoc.data()['email'] as String? ?? normalizedEmail;
    final requestId = _requestId(currentUser.uid, targetUid);
    final requestRef = _firestore.collection('buddyRequests').doc(requestId);
    final existingRequest = await _findExistingRequest(
      currentUser.uid,
      targetUid,
    );

    if (existingRequest != null) {
      if (existingRequest.status == 'accepted') {
        throw Exception('This user is already in your buddy list.');
      }
      if (existingRequest.status == 'pending') {
        throw Exception('A pending buddy request already exists.');
      }
    }

    await requestRef.set(
      {
        'fromUid': currentUser.uid,
        'fromName': currentUser.name,
        'fromEmail': currentUser.email,
        'toUid': targetUid,
        'toName': targetName,
        'toEmail': targetEmail,
        'participants': [currentUser.uid, targetUid],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> acceptRequest({
    required BuddyRequest request,
  }) async {
    await _firestore.collection('buddyRequests').doc(request.id).set(
      {
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> declineRequest(BuddyRequest request) async {
    await _firestore.collection('buddyRequests').doc(request.id).set(
      {
        'status': 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Stream<List<BuddyRequest>> incomingRequests(String uid) {
    return _firestore
        .collection('buddyRequests')
        .where('toUid', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BuddyRequest.fromMap(doc.id, doc.data()))
              .where((request) => request.status == 'pending')
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
        );
  }

  @override
  Stream<List<BuddyConnection>> buddies(String uid) {
    late final StreamController<List<BuddyConnection>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? outgoingSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? incomingSub;
    var outgoing = <BuddyRequest>[];
    var incoming = <BuddyRequest>[];

    void emit() {
      final requests = <BuddyRequest>[...outgoing, ...incoming]
          .where((request) => request.status == 'accepted')
          .toList();
      final buddies = requests
          .map(
            (request) => request.fromUid == uid
                ? BuddyConnection(
                    uid: request.toUid,
                    name: request.toName,
                    email: request.toEmail,
                    acceptedAt: request.updatedAt,
                  )
                : BuddyConnection(
                    uid: request.fromUid,
                    name: request.fromName,
                    email: request.fromEmail,
                    acceptedAt: request.updatedAt,
                  ),
          )
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      controller.add(buddies);
    }

    controller = StreamController<List<BuddyConnection>>.broadcast(
      onListen: () {
        outgoingSub = _firestore
            .collection('buddyRequests')
            .where('fromUid', isEqualTo: uid)
            .snapshots()
            .listen(
              (snapshot) {
                outgoing = snapshot.docs
                    .map((doc) => BuddyRequest.fromMap(doc.id, doc.data()))
                    .toList();
                emit();
              },
              onError: controller.addError,
            );
        incomingSub = _firestore
            .collection('buddyRequests')
            .where('toUid', isEqualTo: uid)
            .snapshots()
            .listen(
              (snapshot) {
                incoming = snapshot.docs
                    .map((doc) => BuddyRequest.fromMap(doc.id, doc.data()))
                    .toList();
                emit();
              },
              onError: controller.addError,
            );
      },
      onCancel: () async {
        await outgoingSub?.cancel();
        await incomingSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<SharedDailyStatus> sharedStatusForDate(String uid, DateTime date) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sharedDailyStatus')
        .doc(DateFormat('yyyy-MM-dd').format(date))
        .snapshots()
        .map((snapshot) => SharedDailyStatus.fromMap(snapshot.data()));
  }

  @override
  Future<void> sendNudge({
    required BuddyConnection buddy,
    required String localeCode,
  }) async {
    final buddyUid = buddy.uid.trim();
    if (buddyUid.isEmpty) {
      throw Exception('Buddy nudge target is missing.');
    }

    await _functionsGateway.postJson(
      'buddyNudge',
      body: {
        'buddyUid': buddyUid,
        'locale': localeCode,
      },
    );
  }

  String _requestId(String firstUid, String secondUid) {
    final ids = [firstUid, secondUid]..sort();
    return ids.join('__');
  }

  Future<BuddyRequest?> _findExistingRequest(
    String currentUid,
    String targetUid,
  ) async {
    final outgoing = await _firestore
        .collection('buddyRequests')
        .where('fromUid', isEqualTo: currentUid)
        .where('toUid', isEqualTo: targetUid)
        .limit(1)
        .get();
    if (outgoing.docs.isNotEmpty) {
      final doc = outgoing.docs.first;
      return BuddyRequest.fromMap(doc.id, doc.data());
    }

    final incoming = await _firestore
        .collection('buddyRequests')
        .where('fromUid', isEqualTo: targetUid)
        .where('toUid', isEqualTo: currentUid)
        .limit(1)
        .get();
    if (incoming.docs.isNotEmpty) {
      final doc = incoming.docs.first;
      return BuddyRequest.fromMap(doc.id, doc.data());
    }

    return null;
  }
}

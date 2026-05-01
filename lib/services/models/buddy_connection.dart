import 'package:cloud_firestore/cloud_firestore.dart';

class BuddyConnection {
  const BuddyConnection({
    required this.uid,
    required this.name,
    required this.email,
    required this.acceptedAt,
  });

  final String uid;
  final String name;
  final String email;
  final DateTime acceptedAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'acceptedAt': acceptedAt.toIso8601String(),
    };
  }

  factory BuddyConnection.fromMap(
    String uid,
    Map<String, dynamic>? data,
  ) {
    final rawAcceptedAt = data?['acceptedAt'];
    DateTime acceptedAt;
    if (rawAcceptedAt is Timestamp) {
      acceptedAt = rawAcceptedAt.toDate();
    } else if (rawAcceptedAt is DateTime) {
      acceptedAt = rawAcceptedAt;
    } else if (rawAcceptedAt is String) {
      acceptedAt = DateTime.tryParse(rawAcceptedAt) ?? DateTime.now();
    } else {
      acceptedAt = DateTime.now();
    }

    return BuddyConnection(
      uid: uid,
      name: data?['name'] as String? ?? '',
      email: data?['email'] as String? ?? '',
      acceptedAt: acceptedAt,
    );
  }
}

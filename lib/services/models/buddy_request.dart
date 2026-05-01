import 'package:cloud_firestore/cloud_firestore.dart';

class BuddyRequest {
  const BuddyRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromEmail,
    required this.toUid,
    required this.toName,
    required this.toEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String fromEmail;
  final String toUid;
  final String toName;
  final String toEmail;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'pending';

  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'fromName': fromName,
      'fromEmail': fromEmail,
      'toUid': toUid,
      'toName': toName,
      'toEmail': toEmail,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BuddyRequest.fromMap(String id, Map<String, dynamic>? data) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return BuddyRequest(
      id: id,
      fromUid: data?['fromUid'] as String? ?? '',
      fromName: data?['fromName'] as String? ?? '',
      fromEmail: data?['fromEmail'] as String? ?? '',
      toUid: data?['toUid'] as String? ?? '',
      toName: data?['toName'] as String? ?? '',
      toEmail: data?['toEmail'] as String? ?? '',
      status: data?['status'] as String? ?? 'pending',
      createdAt: parseDate(data?['createdAt']),
      updatedAt: parseDate(data?['updatedAt']),
    );
  }
}

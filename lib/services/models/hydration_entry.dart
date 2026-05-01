import 'package:cloud_firestore/cloud_firestore.dart';

class HydrationEntry {
  const HydrationEntry({
    this.id = '',
    required this.amountMl,
    required this.label,
    required this.createdAt,
  });

  final String id;
  final int amountMl;
  final String label;
  final DateTime createdAt;

  HydrationEntry copyWith({
    String? id,
    int? amountMl,
    String? label,
    DateTime? createdAt,
  }) {
    return HydrationEntry(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amountMl': amountMl,
      'label': label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HydrationEntry.fromMap(
    Map<String, dynamic>? data, {
    String id = '',
  }) {
    final rawCreatedAt = data?['createdAt'];
    DateTime createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is DateTime) {
      createdAt = rawCreatedAt;
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return HydrationEntry(
      id: id,
      amountMl: (data?['amountMl'] as num?)?.round() ?? 0,
      label: data?['label'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}

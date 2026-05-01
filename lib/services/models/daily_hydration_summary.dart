import 'package:cloud_firestore/cloud_firestore.dart';

class DailyHydrationSummary {
  const DailyHydrationSummary({
    this.totalMl = 0,
    this.goalMl = 2500,
    required this.updatedAt,
  });

  DailyHydrationSummary.empty()
      : totalMl = 0,
        goalMl = 2500,
        updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  final int totalMl;
  final int goalMl;
  final DateTime updatedAt;

  double get progress {
    if (goalMl <= 0) return 0;
    return (totalMl / goalMl).clamp(0, 1).toDouble();
  }

  int get remainingMl {
    return goalMl > totalMl ? goalMl - totalMl : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'totalMl': totalMl,
      'goalMl': goalMl,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DailyHydrationSummary copyWith({
    int? totalMl,
    int? goalMl,
    DateTime? updatedAt,
  }) {
    return DailyHydrationSummary(
      totalMl: totalMl ?? this.totalMl,
      goalMl: goalMl ?? this.goalMl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DailyHydrationSummary.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return DailyHydrationSummary.empty();
    }
    final rawUpdatedAt = data['updatedAt'];
    DateTime updatedAt;
    if (rawUpdatedAt is Timestamp) {
      updatedAt = rawUpdatedAt.toDate();
    } else if (rawUpdatedAt is DateTime) {
      updatedAt = rawUpdatedAt;
    } else if (rawUpdatedAt is String) {
      updatedAt = DateTime.tryParse(rawUpdatedAt) ?? DateTime.now();
    } else {
      updatedAt = DateTime.now();
    }

    return DailyHydrationSummary(
      totalMl: (data['totalMl'] as num?)?.round() ?? 0,
      goalMl: (data['goalMl'] as num?)?.round() ?? 2500,
      updatedAt: updatedAt,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SharedDailyStatus {
  const SharedDailyStatus({
    this.waterMl = 0,
    this.waterGoalMl = 2500,
    required this.updatedAt,
  });

  SharedDailyStatus.empty()
      : waterMl = 0,
        waterGoalMl = 2500,
        updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  final int waterMl;
  final int waterGoalMl;
  final DateTime updatedAt;

  double get progress {
    if (waterGoalMl <= 0) return 0;
    return (waterMl / waterGoalMl).clamp(0, 1).toDouble();
  }

  factory SharedDailyStatus.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return SharedDailyStatus.empty();
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

    return SharedDailyStatus(
      waterMl: (data['waterMl'] as num?)?.round() ?? 0,
      waterGoalMl: (data['waterGoalMl'] as num?)?.round() ?? 2500,
      updatedAt: updatedAt,
    );
  }
}

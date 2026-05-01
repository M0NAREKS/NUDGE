import 'package:cloud_firestore/cloud_firestore.dart';

class DailyInsight {
  const DailyInsight({
    required this.dateKey,
    required this.consistencyScore,
    required this.breakdown,
    required this.status,
    required this.narrative,
    required this.positiveSignal,
    required this.riskSignal,
    required this.tomorrowAction,
    required this.recoveryMode,
    required this.generatedAt,
  });

  final String dateKey;
  final int consistencyScore;
  final Map<String, int> breakdown;
  final String status;
  final String narrative;
  final String positiveSignal;
  final String riskSignal;
  final String tomorrowAction;
  final bool recoveryMode;
  final DateTime generatedAt;

  DailyInsight copyWith({
    String? dateKey,
    int? consistencyScore,
    Map<String, int>? breakdown,
    String? status,
    String? narrative,
    String? positiveSignal,
    String? riskSignal,
    String? tomorrowAction,
    bool? recoveryMode,
    DateTime? generatedAt,
  }) {
    return DailyInsight(
      dateKey: dateKey ?? this.dateKey,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      breakdown: breakdown ?? this.breakdown,
      status: status ?? this.status,
      narrative: narrative ?? this.narrative,
      positiveSignal: positiveSignal ?? this.positiveSignal,
      riskSignal: riskSignal ?? this.riskSignal,
      tomorrowAction: tomorrowAction ?? this.tomorrowAction,
      recoveryMode: recoveryMode ?? this.recoveryMode,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'consistencyScore': consistencyScore,
      'breakdown': breakdown,
      'status': status,
      'narrative': narrative,
      'positiveSignal': positiveSignal,
      'riskSignal': riskSignal,
      'tomorrowAction': tomorrowAction,
      'recoveryMode': recoveryMode,
      'generatedAt': generatedAt,
    };
  }

  factory DailyInsight.fromMap(Map<String, dynamic>? data) {
    final rawGeneratedAt = data?['generatedAt'];
    final rawBreakdown = data?['breakdown'];
    return DailyInsight(
      dateKey: data?['dateKey'] as String? ?? '',
      consistencyScore: (data?['consistencyScore'] as num?)?.round() ?? 0,
      breakdown: rawBreakdown is Map
          ? rawBreakdown.map(
              (key, value) =>
                  MapEntry(key.toString(), (value as num?)?.round() ?? 0),
            )
          : const <String, int>{},
      status: data?['status'] as String? ?? 'building',
      narrative: data?['narrative'] as String? ?? '',
      positiveSignal: data?['positiveSignal'] as String? ?? '',
      riskSignal: data?['riskSignal'] as String? ?? '',
      tomorrowAction: data?['tomorrowAction'] as String? ?? '',
      recoveryMode: data?['recoveryMode'] as bool? ?? false,
      generatedAt: _dateTimeFromRaw(rawGeneratedAt),
    );
  }

  static DateTime _dateTimeFromRaw(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class SmartNudge {
  const SmartNudge({
    required this.ruleId,
    required this.title,
    required this.body,
    required this.route,
    this.type = 'smart_nudge',
  });

  final String ruleId;
  final String title;
  final String body;
  final String route;
  final String type;
}

class SmartNudgeHistory {
  const SmartNudgeHistory({
    required this.dateKey,
    this.firedRuleIds = const <String>[],
    this.lastShownAt,
  });

  final String dateKey;
  final List<String> firedRuleIds;
  final DateTime? lastShownAt;

  int get count => firedRuleIds.length;

  SmartNudgeHistory copyWith({
    String? dateKey,
    List<String>? firedRuleIds,
    DateTime? lastShownAt,
  }) {
    return SmartNudgeHistory(
      dateKey: dateKey ?? this.dateKey,
      firedRuleIds: firedRuleIds ?? this.firedRuleIds,
      lastShownAt: lastShownAt ?? this.lastShownAt,
    );
  }

  bool canShow(String ruleId, DateTime now) {
    if (firedRuleIds.contains(ruleId)) return false;
    if (firedRuleIds.length >= 3) return false;

    final last = lastShownAt;
    if (last == null) return true;
    return now.difference(last) >= const Duration(hours: 4);
  }

  SmartNudgeHistory record(String ruleId, DateTime now) {
    return SmartNudgeHistory(
      dateKey: dateKey,
      firedRuleIds: [...firedRuleIds, ruleId],
      lastShownAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'firedRuleIds': firedRuleIds,
      'lastShownAt': lastShownAt?.toIso8601String(),
    };
  }

  factory SmartNudgeHistory.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return SmartNudgeHistory(dateKey: _todayKey(DateTime.now()));
    }
    final rawLastShownAt = data['lastShownAt'];
    final rawRules = data['firedRuleIds'];
    return SmartNudgeHistory(
      dateKey: data['dateKey'] as String? ?? _todayKey(DateTime.now()),
      firedRuleIds: rawRules is List
          ? rawRules.map((item) => item.toString()).toList()
          : const <String>[],
      lastShownAt: _dateTimeFromRaw(rawLastShownAt),
    );
  }

  static DateTime? _dateTimeFromRaw(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static String _todayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

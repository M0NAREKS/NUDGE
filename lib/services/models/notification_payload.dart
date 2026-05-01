import 'dart:convert';

import '../../utils/app_routes.dart';

class NotificationPayload {
  const NotificationPayload({
    required this.type,
    required this.route,
    this.entityId,
    this.title,
    this.body,
  });

  final String type;
  final String route;
  final String? entityId;
  final String? title;
  final String? body;

  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    final normalizedRoute = AppRoutes.canonicalRoute(
      data['route'] as String? ?? data['screen'] as String?,
    );

    return NotificationPayload(
      type: (data['type'] as String?)?.trim().isNotEmpty == true
          ? (data['type'] as String).trim()
          : 'general',
      route: normalizedRoute,
      entityId: (data['entityId'] as String?)?.trim(),
      title: (data['title'] as String?)?.trim(),
      body: (data['body'] as String?)?.trim(),
    );
  }

  static NotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return NotificationPayload.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'route': route,
      'entityId': entityId,
      'title': title,
      'body': body,
    };
  }

  String toJsonString() => jsonEncode(toMap());
}

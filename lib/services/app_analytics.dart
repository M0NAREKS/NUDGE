import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:huawei_analytics/huawei_analytics.dart';

import 'platform_capability_service.dart';

abstract class AnalyticsSink {
  Future<void> initialize();

  Future<void> logEvent(String name, Map<String, Object> params);

  Future<void> setUserId(String? uid);

  Future<void> setUserProperty(String key, String value);
}

class AppAnalytics {
  AppAnalytics(this._sinks);

  final List<AnalyticsSink> _sinks;

  static AppAnalytics build(PlatformCapabilities capabilities) {
    return AppAnalytics(
      [
        FirebaseAnalyticsSink(FirebaseAnalytics.instance),
        if (capabilities.supportsHuaweiAnalytics) HuaweiAnalyticsSink(),
      ],
    );
  }

  Future<void> initialize() async {
    for (final sink in _sinks) {
      await _ignoreErrors(() => sink.initialize());
    }
  }

  Future<void> logEvent(
    String name, [
    Map<String, Object?> params = const <String, Object?>{},
  ]) async {
    final normalizedName = _normalizeEventName(name);
    final normalizedParams = _sanitizeParams(params);
    for (final sink in _sinks) {
      await _ignoreErrors(() => sink.logEvent(normalizedName, normalizedParams));
    }
  }

  Future<void> setUserId(String uid) async {
    for (final sink in _sinks) {
      await _ignoreErrors(() => sink.setUserId(uid));
    }
  }

  Future<void> clearUserIdentity() async {
    for (final sink in _sinks) {
      await _ignoreErrors(() => sink.setUserId(null));
    }
  }

  Future<void> setUserProperty(String key, String value) async {
    final normalizedKey = key.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    for (final sink in _sinks) {
      await _ignoreErrors(() => sink.setUserProperty(normalizedKey, value));
    }
  }

  Future<void> _ignoreErrors(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      debugPrint('Analytics sink error: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Map<String, Object> _sanitizeParams(Map<String, Object?> raw) {
    final sanitized = <String, Object>{};
    raw.forEach((key, value) {
      if (value == null) return;
      final normalizedKey =
          key.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
      if (normalizedKey.isEmpty) return;
      if (value is String || value is num || value is bool) {
        sanitized[normalizedKey] = value;
      } else {
        sanitized[normalizedKey] = value.toString();
      }
    });
    return sanitized;
  }

  String _normalizeEventName(String name) {
    final normalized =
        name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_').toLowerCase();
    return normalized.isEmpty ? 'event' : normalized;
  }
}

class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> logEvent(String name, Map<String, Object> params) {
    return _analytics.logEvent(name: name, parameters: params);
  }

  @override
  Future<void> setUserId(String? uid) {
    return _analytics.setUserId(id: uid);
  }

  @override
  Future<void> setUserProperty(String key, String value) {
    return _analytics.setUserProperty(name: key, value: value);
  }
}

class HuaweiAnalyticsSink implements AnalyticsSink {
  HMSAnalytics? _analytics;

  @override
  Future<void> initialize() async {
    _analytics ??= await HMSAnalytics.getInstance();
    await _analytics?.setAnalyticsEnabled(true);
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> params) async {
    await initialize();
    await _analytics?.onEvent(name, params);
  }

  @override
  Future<void> setUserId(String? uid) async {
    await initialize();
    await _analytics?.setUserId(uid);
  }

  @override
  Future<void> setUserProperty(String key, String value) async {
    await initialize();
    await _analytics?.setUserProfile(key, value);
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as local;
import 'package:huawei_analytics/huawei_analytics.dart';
import 'package:huawei_push/huawei_push.dart' as hms_push;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../utils/app_routes.dart';
import 'app_analytics.dart';
import 'app_navigation.dart';
import 'local_storage_service.dart';
import 'models/notification_preferences.dart';
import 'models/notification_payload.dart';
import 'platform_capability_service.dart';
import 'push_token_repository.dart';

const _remoteChannelIdValue = 'nudge_remote';
const _reminderChannelIdValue = 'nudge_reminders';
const _notificationIconNameValue = 'ic_notification';
const _notificationColorValue = Color(0xFFFF7A33);

class NotificationService {
  NotificationService({
    required PlatformCapabilityService platformCapabilityService,
    required AppAnalytics analytics,
    PushTokenRepository? pushTokenRepository,
    fcm.FirebaseMessaging? firebaseMessaging,
    local.FlutterLocalNotificationsPlugin? localNotifications,
  }) : _platformCapabilityService = platformCapabilityService,
       _analytics = analytics,
       _pushTokenRepository = pushTokenRepository ?? PushTokenRepository(),
       _firebaseMessaging = firebaseMessaging ?? fcm.FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? local.FlutterLocalNotificationsPlugin();

  final PlatformCapabilityService _platformCapabilityService;
  final AppAnalytics _analytics;
  final PushTokenRepository _pushTokenRepository;
  final fcm.FirebaseMessaging _firebaseMessaging;
  final local.FlutterLocalNotificationsPlugin _localNotifications;

  static const _remoteChannelId = _remoteChannelIdValue;
  static const _reminderChannelId = _reminderChannelIdValue;
  static const _notificationIconName = _notificationIconNameValue;
  static const _notificationColor = _notificationColorValue;
  static const _mealReminderId = 4101;
  static const _workoutReminderId = 4102;
  static const _dailyCheckInReminderId = 4103;
  static const _testReminderId = 4199;

  HMSAnalytics? _huaweiAnalytics;
  NotificationPayload? _pendingPayload;
  String? _uid;
  StreamSubscription<String>? _huaweiTokenSubscription;
  StreamSubscription<fcm.RemoteMessage>? _fcmForegroundSubscription;
  StreamSubscription<fcm.RemoteMessage>? _fcmOpenedSubscription;
  StreamSubscription<hms_push.RemoteMessage>? _hmsForegroundSubscription;
  StreamSubscription<dynamic>? _hmsOpenedSubscription;
  StreamSubscription<Map<String, dynamic>>? _hmsLocalClickSubscription;
  StreamSubscription<String>? _fcmTokenRefreshSubscription;
  bool _initialized = false;
  bool _timeZonesInitialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _initialized = true;
    await _initializeTimeZones();
    await _initializeLocalNotifications();
    await _attachFirebaseMessaging();
    await _attachHuaweiMessaging();
  }

  Future<void> syncUser(String? uid) async {
    _uid = uid;
    if (uid == null || uid.isEmpty) return;
    final preferences = await LocalStorageService.getNotificationPreferences();
    if (!preferences.enabled) return;
    await _registerCurrentToken();
  }

  Future<bool> ensurePermissions() async {
    var remoteGranted = true;
    var localGranted = true;

    final capabilities = _platformCapabilityService.capabilities;
    final shouldRequestFcmPermission =
        kIsWeb ||
        !capabilities.isAndroid ||
        capabilities.preferredPushProvider == PushProviderKind.fcm;

    if (shouldRequestFcmPermission) {
      try {
        final permissions = await _firebaseMessaging.requestPermission();
        final status = permissions.authorizationStatus;
        remoteGranted =
            status == fcm.AuthorizationStatus.authorized ||
            status == fcm.AuthorizationStatus.provisional;
      } catch (_) {
        remoteGranted = !capabilities.isAndroid;
      }
    }

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              local.AndroidFlutterLocalNotificationsPlugin
            >();
        localGranted =
            await androidPlugin?.requestNotificationsPermission() ?? true;
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        localGranted =
            await _localNotifications
                .resolvePlatformSpecificImplementation<
                  local.IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
        localGranted =
            await _localNotifications
                .resolvePlatformSpecificImplementation<
                  local.MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
      }
    } catch (_) {
      localGranted = true;
    }

    final granted = remoteGranted && localGranted;
    if (granted) {
      await _registerCurrentToken();
    }

    return granted;
  }

  Future<bool> syncPreferenceDrivenNotifications({
    required NotificationPreferences preferences,
    required String localeCode,
    bool requestPermissionIfNeeded = false,
  }) async {
    if (!preferences.enabled) {
      await _cancelReminderSchedules();
      final uid = _uid;
      if (uid != null && uid.isNotEmpty) {
        await _pushTokenRepository.setNotificationsEnabledForUser(
          uid: uid,
          enabled: false,
        );
      }
      return true;
    }

    if (requestPermissionIfNeeded) {
      final granted = await ensurePermissions();
      if (!granted) {
        await _cancelReminderSchedules();
        return false;
      }
    }

    await _initializeTimeZones();
    await _cancelReminderSchedules();

    if (preferences.mealReminders) {
      await _scheduleDailyReminder(
        id: _mealReminderId,
        scheduledHour: 12,
        scheduledMinute: 30,
        title: localeCode == 'en' ? 'Meal reminder' : 'Öğün hatırlatması',
        body: localeCode == 'en'
            ? 'Log your meals before the day gets away from you.'
            : 'Gün dağılmadan öğünlerini kaydet.',
        payload: NotificationPayload(
          type: 'meal',
          route: AppRoutes.food,
          title: localeCode == 'en' ? 'Meal reminder' : 'Öğün hatırlatması',
          body: localeCode == 'en'
              ? 'Open nutrition and log what you ate.'
              : 'Beslenme ekranını açıp ne yediğini kaydet.',
        ),
      );
    }

    if (preferences.workoutReminders) {
      await _scheduleDailyReminder(
        id: _workoutReminderId,
        scheduledHour: 18,
        scheduledMinute: 30,
        title: localeCode == 'en'
            ? 'Workout reminder'
            : 'Antrenman hatırlatması',
        body: localeCode == 'en'
            ? 'Your pace plan is ready. Check today\'s workout.'
            : 'Tempo planın hazır. Bugünkü antrenman ekranını kontrol et.',
        payload: NotificationPayload(
          type: 'workout',
          route: AppRoutes.workout,
          title: localeCode == 'en'
              ? 'Workout reminder'
              : 'Antrenman hatırlatması',
          body: localeCode == 'en'
              ? 'Open workout and keep the day on track.'
              : 'Antrenman ekranını açıp günü ritimde tut.',
        ),
      );
    }

    if (preferences.dailyCheckIn) {
      await _scheduleDailyReminder(
        id: _dailyCheckInReminderId,
        scheduledHour: 21,
        scheduledMinute: 0,
        title: localeCode == 'en' ? 'Daily check-in' : 'Günlük kontrol',
        body: localeCode == 'en'
            ? 'Review calories, water, and your daily balance before you close the day.'
            : 'Günü kapatmadan önce kalori, su ve günlük dengeyi gözden geçir.',
        payload: NotificationPayload(
          type: 'daily',
          route: AppRoutes.home,
          title: localeCode == 'en' ? 'Daily check-in' : 'Günlük kontrol',
          body: localeCode == 'en'
              ? 'Open home and review today\'s balance.'
              : 'Ana sayfayı açıp bugünkü dengeyi kontrol et.',
        ),
      );
    }

    await _registerCurrentToken();
    return true;
  }

  Future<bool> showTestReminder({
    required String localeCode,
    bool requestPermissionIfNeeded = false,
  }) async {
    if (requestPermissionIfNeeded) {
      final granted = await ensurePermissions();
      if (!granted) {
        return false;
      }
    }

    final payload = NotificationPayload(
      type: 'daily',
      route: AppRoutes.home,
      title: localeCode == 'en' ? 'Test notification' : 'Test bildirimi',
      body: localeCode == 'en'
          ? 'Notifications are working and the reminder channel is alive.'
          : 'Bildirimler çalışıyor ve hatırlatma kanalı aktif.',
    );

    await _localNotifications.show(
      id: _testReminderId,
      title: payload.title,
      body: payload.body,
      notificationDetails: _reminderDetails(),
      payload: payload.toJsonString(),
    );
    return true;
  }

  Future<bool> showSmartNudge(NotificationPayload payload) async {
    if (kIsWeb) return false;
    final preferences = await LocalStorageService.getNotificationPreferences();
    if (!preferences.allowsType(payload.type)) return false;

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: payload.title ?? 'Nudge',
      body: payload.body,
      notificationDetails: _reminderDetails(),
      payload: payload.toJsonString(),
    );
    return true;
  }

  Future<void> registerToken(String provider, String token) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty || token.trim().isEmpty) return;

    final settings = await LocalStorageService.getAppSettings();
    final platform = defaultTargetPlatform.name.toLowerCase();
    await _pushTokenRepository.upsertToken(
      uid: uid,
      provider: provider,
      token: token.trim(),
      platform: platform,
      localeCode: settings.localeCode,
      notificationsEnabled: settings.notificationPreferences.enabled,
    );

    if (provider == 'hms') {
      try {
        _huaweiAnalytics ??= await HMSAnalytics.getInstance();
        await _huaweiAnalytics?.setPushToken(token.trim());
      } catch (_) {
        // Ignore Huawei analytics failures and keep push registration alive.
      }
    }
  }

  Future<void> handleForegroundMessage(NotificationPayload payload) async {
    if (kIsWeb) return;
    final preferences = await LocalStorageService.getNotificationPreferences();
    if (!preferences.allowsType(payload.type)) return;

    final notificationDetails = local.NotificationDetails(
      android: local.AndroidNotificationDetails(
        _remoteChannelId,
        'Nudge Remote',
        channelDescription: 'Remote coaching and nutrition notifications',
        icon: _notificationIconName,
        color: _notificationColor,
        importance: local.Importance.max,
        priority: local.Priority.high,
      ),
      iOS: const local.DarwinNotificationDetails(),
      macOS: const local.DarwinNotificationDetails(),
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(
      id: id,
      title: payload.title ?? 'Nudge',
      body: payload.body ?? 'Yeni bir Nudge bildirimi var.',
      notificationDetails: notificationDetails,
      payload: payload.toJsonString(),
    );
  }

  Future<void> handleNotificationOpen(NotificationPayload payload) async {
    await _analytics.logEvent('notification_opened', {
      'type': payload.type,
      'route': AppRoutes.canonicalRoute(payload.route),
    });

    final navigator = AppNavigation.navigatorKey.currentState;
    if (navigator == null) {
      _pendingPayload = payload;
      _schedulePendingFlush();
      return;
    }

    AppNavigation.openRoute(payload.route);
  }

  void flushPendingNavigation() {
    final payload = _pendingPayload;
    if (payload == null) return;
    if (AppNavigation.navigatorKey.currentState == null) {
      _schedulePendingFlush();
      return;
    }
    _pendingPayload = null;
    unawaited(handleNotificationOpen(payload));
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = local.InitializationSettings(
      android: local.AndroidInitializationSettings(_notificationIconName),
      iOS: local.DarwinInitializationSettings(),
      macOS: local.DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = NotificationPayload.tryParse(response.payload);
        if (payload != null) {
          unawaited(handleNotificationOpen(payload));
        }
      },
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            local.AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const local.AndroidNotificationChannel(
              _remoteChannelId,
              'Nudge Remote',
              description: 'Remote coaching and nutrition notifications',
              importance: local.Importance.max,
            ),
          );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            local.AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const local.AndroidNotificationChannel(
              _reminderChannelId,
              'Nudge Reminders',
              description:
                  'Scheduled meal, workout and daily check-in reminders',
              importance: local.Importance.max,
            ),
          );
    }
  }

  Future<void> _initializeTimeZones() async {
    if (_timeZonesInitialized) return;
    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fall back to timezone package default if local timezone lookup fails.
    }
    _timeZonesInitialized = true;
  }

  Future<void> _cancelReminderSchedules() async {
    await _localNotifications.cancel(id: _mealReminderId);
    await _localNotifications.cancel(id: _workoutReminderId);
    await _localNotifications.cancel(id: _dailyCheckInReminderId);
    await _localNotifications.cancel(id: _testReminderId);
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required int scheduledHour,
    required int scheduledMinute,
    required String title,
    required String body,
    required NotificationPayload payload,
  }) async {
    final scheduleTime = _nextInstanceOfTime(
      hour: scheduledHour,
      minute: scheduledMinute,
    );

    await _localNotifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduleTime,
      notificationDetails: _reminderDetails(),
      payload: payload.toJsonString(),
      androidScheduleMode: local.AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: local.DateTimeComponents.time,
    );
  }

  local.NotificationDetails _reminderDetails() {
    return const local.NotificationDetails(
      android: local.AndroidNotificationDetails(
        _reminderChannelId,
        'Nudge Reminders',
        channelDescription: 'Scheduled meal, workout and daily reminders',
        icon: _notificationIconName,
        color: _notificationColor,
        importance: local.Importance.max,
        priority: local.Priority.high,
      ),
      iOS: local.DarwinNotificationDetails(),
      macOS: local.DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _attachFirebaseMessaging() async {
    _fcmForegroundSubscription = fcm.FirebaseMessaging.onMessage.listen((
      message,
    ) async {
      final payload = _payloadFromFirebaseMessage(message);
      if (payload != null) {
        await handleForegroundMessage(payload);
      }
    });

    _fcmOpenedSubscription = fcm.FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      final payload = _payloadFromFirebaseMessage(message);
      if (payload != null) {
        unawaited(handleNotificationOpen(payload));
      }
    });

    _fcmTokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(
      (token) => unawaited(registerToken('fcm', token)),
    );

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    final initialPayload = _payloadFromFirebaseMessage(initialMessage);
    if (initialPayload != null) {
      _pendingPayload = initialPayload;
      _schedulePendingFlush();
    }
  }

  Future<void> _attachHuaweiMessaging() async {
    final capabilities = _platformCapabilityService.capabilities;
    if (!capabilities.hasHuaweiServices || !capabilities.isAndroid) {
      return;
    }

    try {
      _huaweiAnalytics = await HMSAnalytics.getInstance();
    } catch (_) {
      // Analytics is optional for Huawei runtime support.
    }

    _huaweiTokenSubscription = hms_push.Push.getTokenStream.listen(
      (token) => unawaited(registerToken('hms', token)),
    );

    _hmsForegroundSubscription = hms_push.Push.onMessageReceivedStream.listen((
      message,
    ) async {
      final payload = _payloadFromHuaweiRemoteMessage(message);
      if (payload != null) {
        await handleForegroundMessage(payload);
      }
    });

    _hmsOpenedSubscription = hms_push.Push.onNotificationOpenedApp.listen((
      dynamic event,
    ) {
      final payload = _payloadFromHuaweiOpenEvent(event);
      if (payload != null) {
        unawaited(handleNotificationOpen(payload));
      }
    });

    _hmsLocalClickSubscription = hms_push.Push.onLocalNotificationClick.listen((
      event,
    ) {
      final payload = NotificationPayload.fromMap(event);
      unawaited(handleNotificationOpen(payload));
    });

    final initialNotification = await hms_push.Push.getInitialNotification();
    final initialPayload = _payloadFromHuaweiOpenEvent(initialNotification);
    if (initialPayload != null) {
      _pendingPayload = initialPayload;
      _schedulePendingFlush();
    }

    try {
      await hms_push.Push.registerBackgroundMessageHandler(
        _huaweiBackgroundHandler,
      );
    } catch (_) {
      // Background handler is optional during local development.
    }
  }

  Future<void> _registerCurrentToken() async {
    final preferences = await LocalStorageService.getNotificationPreferences();
    if (!preferences.enabled) return;

    final provider =
        _platformCapabilityService.capabilities.preferredPushProvider;
    switch (provider) {
      case PushProviderKind.fcm:
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await registerToken('fcm', token);
        }
        break;
      case PushProviderKind.hms:
        try {
          hms_push.Push.getToken(hms_push.RemoteMessage.INSTANCE_ID_SCOPE);
        } catch (_) {
          // Token stream will remain silent if HMS is not configured yet.
        }
        break;
      case PushProviderKind.none:
        break;
    }
  }

  NotificationPayload? _payloadFromFirebaseMessage(fcm.RemoteMessage? message) {
    if (message == null) return null;

    final map = <String, dynamic>{
      ...message.data,
      'title': message.data['title'] ?? message.notification?.title,
      'body': message.data['body'] ?? message.notification?.body,
      'route':
          message.data['route'] ?? message.data['screen'] ?? AppRoutes.home,
      'type': message.data['type'] ?? 'general',
    };

    return NotificationPayload.fromMap(map);
  }

  NotificationPayload? _payloadFromHuaweiRemoteMessage(
    hms_push.RemoteMessage message,
  ) {
    final data = message.getDataOfMap ?? _decodeData(message.getData);
    final map = <String, dynamic>{
      ...data,
      'title': data['title'] ?? message.getNotification?.getTitle,
      'body': data['body'] ?? message.getNotification?.getBody,
      'route': data['route'] ?? data['screen'] ?? AppRoutes.home,
      'type': data['type'] ?? 'general',
    };

    return NotificationPayload.fromMap(map);
  }

  NotificationPayload? _payloadFromHuaweiOpenEvent(dynamic event) {
    if (event == null) return null;

    if (event is Map) {
      final extrasRaw = event['extras'];
      final remoteMessageRaw = event['remoteMessage'];
      final extras = extrasRaw is Map
          ? extrasRaw.map((key, value) => MapEntry('$key', value))
          : <String, dynamic>{};
      final remoteMessage = remoteMessageRaw is Map
          ? remoteMessageRaw.map((key, value) => MapEntry('$key', value))
          : <String, dynamic>{};
      final notification = remoteMessage['notification'];
      final notificationMap = notification is Map
          ? notification.map((key, value) => MapEntry('$key', value))
          : <String, dynamic>{};

      return NotificationPayload.fromMap({
        ...remoteMessage,
        ...extras,
        'title': extras['title'] ?? notificationMap['title'],
        'body': extras['body'] ?? notificationMap['body'],
        'route': extras['route'] ?? extras['screen'] ?? AppRoutes.home,
        'type': extras['type'] ?? 'general',
      });
    }

    if (event is String) {
      return NotificationPayload.tryParse(event);
    }

    return null;
  }

  Map<String, dynamic> _decodeData(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Non-JSON data payloads are ignored.
    }
    return const <String, dynamic>{};
  }

  void _schedulePendingFlush() {
    Future<void>.delayed(
      const Duration(milliseconds: 350),
      flushPendingNavigation,
    );
  }

  Future<void> dispose() async {
    await _huaweiTokenSubscription?.cancel();
    await _fcmForegroundSubscription?.cancel();
    await _fcmOpenedSubscription?.cancel();
    await _hmsForegroundSubscription?.cancel();
    await _hmsOpenedSubscription?.cancel();
    await _hmsLocalClickSubscription?.cancel();
    await _fcmTokenRefreshSubscription?.cancel();
  }
}

void _huaweiBackgroundHandler(hms_push.RemoteMessage remoteMessage) {}

@pragma('vm:entry-point')
Future<void> showBackgroundFirebaseNotification(
  fcm.RemoteMessage message,
) async {
  if (kIsWeb) return;
  if (message.notification != null) {
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  final payload = NotificationPayload.fromMap({
    ...message.data,
    'title': message.data['title'],
    'body': message.data['body'],
    'route': message.data['route'] ?? message.data['screen'] ?? AppRoutes.home,
    'type': message.data['type'] ?? 'general',
  });

  final preferences = await LocalStorageService.getNotificationPreferences();
  if (!preferences.allowsType(payload.type)) return;

  final title = payload.title?.trim();
  final body = payload.body?.trim();
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return;
  }

  final notifications = local.FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    settings: const local.InitializationSettings(
      android: local.AndroidInitializationSettings(_notificationIconNameValue),
      iOS: local.DarwinInitializationSettings(),
      macOS: local.DarwinInitializationSettings(),
    ),
  );
  await notifications.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title ?? 'Nudge',
    body: body ?? '',
    notificationDetails: const local.NotificationDetails(
      android: local.AndroidNotificationDetails(
        _remoteChannelIdValue,
        'Nudge Remote',
        channelDescription: 'Remote coaching and nutrition notifications',
        icon: _notificationIconNameValue,
        color: _notificationColorValue,
        importance: local.Importance.max,
        priority: local.Priority.high,
      ),
      iOS: local.DarwinNotificationDetails(),
      macOS: local.DarwinNotificationDetails(),
    ),
    payload: payload.toJsonString(),
  );
}

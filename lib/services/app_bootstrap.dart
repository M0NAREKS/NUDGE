import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'dart:async';
import 'package:flutter/widgets.dart';

import '../firebase_options.dart';
import 'app_analytics.dart';
import 'notification_service.dart';
import 'platform_capability_service.dart';

class NudgeBootstrapData {
  const NudgeBootstrapData({
    required this.analytics,
    required this.notificationService,
    required this.platformCapabilityService,
  });

  final AppAnalytics analytics;
  final NotificationService notificationService;
  final PlatformCapabilityService platformCapabilityService;
}

class NudgeBootstrap {
  static Future<NudgeBootstrapData> initialize() async {
    final platformCapabilityService = PlatformCapabilityService();
    final firebaseInitialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final capabilitiesFuture = platformCapabilityService.refresh();

    await firebaseInitialization;
    fcm.FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
    unawaited(FirebaseFirestore.instance.enableNetwork());

    final capabilities = await capabilitiesFuture;
    final analytics = AppAnalytics.build(capabilities);
    final notificationService = NotificationService(
      platformCapabilityService: platformCapabilityService,
      analytics: analytics,
    );
    unawaited(analytics.initialize());
    unawaited(notificationService.initialize());

    return NudgeBootstrapData(
      analytics: analytics,
      notificationService: notificationService,
      platformCapabilityService: platformCapabilityService,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
  fcm.RemoteMessage message,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await showBackgroundFirebaseNotification(message);
}

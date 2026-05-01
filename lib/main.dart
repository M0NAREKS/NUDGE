import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_settings_provider.dart';
import 'providers/buddy_provider.dart';
import 'providers/daily_insight_provider.dart';
import 'providers/food_provider.dart';
import 'providers/health_provider.dart';
import 'providers/hydration_provider.dart';
import 'providers/user_provider.dart';
import 'services/app_analytics.dart';
import 'services/app_bootstrap.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/platform_capability_service.dart';
import 'utils/colors.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapGate());
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate();

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  late final Future<NudgeBootstrapData> _bootstrapFuture;
  String _bootstrapLocaleCode = 'tr';

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = NudgeBootstrap.initialize();
    LocalStorageService.getAppSettings().then((settings) {
      if (!mounted) return;
      setState(() => _bootstrapLocaleCode = settings.localeCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NudgeBootstrapData>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        final bootstrap = snapshot.data;
        if (bootstrap == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(brightness: Brightness.light),
            home: _BootstrapSplash(
              error: snapshot.error,
              localeCode: _bootstrapLocaleCode,
            ),
          );
        }

        return MultiProvider(
          providers: [
            Provider<AppAnalytics>.value(value: bootstrap.analytics),
            Provider<NotificationService>.value(
              value: bootstrap.notificationService,
            ),
            Provider<PlatformCapabilityService>.value(
              value: bootstrap.platformCapabilityService,
            ),
            ChangeNotifierProvider(
              create: (_) => AppSettingsProvider(
                notificationService: bootstrap.notificationService,
              )..initialize(),
            ),
            ChangeNotifierProvider(
              create: (_) => UserProvider(
                analytics: bootstrap.analytics,
                notificationService: bootstrap.notificationService,
              ),
            ),
            ChangeNotifierProxyProvider<UserProvider, HealthProvider>(
              create: (_) => HealthProvider(),
              update: (_, user, health) =>
                  (health ?? HealthProvider())..syncUser(user),
            ),
            ChangeNotifierProvider(
              create: (_) => FoodProvider(analytics: bootstrap.analytics),
            ),
            ChangeNotifierProvider(
              create: (_) => HydrationProvider(analytics: bootstrap.analytics),
            ),
            ChangeNotifierProvider(
              create: (_) => BuddyProvider(analytics: bootstrap.analytics),
            ),
            ChangeNotifierProvider(
              create: (_) => DailyInsightProvider(
                notificationService: bootstrap.notificationService,
                analytics: bootstrap.analytics,
              ),
            ),
          ],
          child: const NudgeApp(),
        );
      },
    );
  }
}

class _BootstrapSplash extends StatelessWidget {
  const _BootstrapSplash({
    this.error,
    required this.localeCode,
  });

  final Object? error;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final isEnglish = localeCode == 'en';
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppPalette.dark.shellGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppPalette.dark.heroGradient,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.alpha(Colors.white, 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.alpha(Colors.black, 0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.alpha(AppColors.secondary, 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.secondary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Nudge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEnglish ? 'Loading Nudge' : 'Nudge yükleniyor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error == null
                        ? (isEnglish
                            ? 'The first screen opens immediately while services prepare in the background.'
                            : 'İlk ekran önce açılıyor, servisler arka planda hazırlanıyor.')
                        : (isEnglish
                            ? 'A startup error occurred. Try reopening the app.'
                            : 'Başlangıç sırasında bir hata oluştu. Uygulamayı yeniden açmayı dene.'),
                    style: TextStyle(
                      color: AppColors.alpha(Colors.white, 0.74),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (error == null)
                    const LinearProgressIndicator(minHeight: 8)
                  else
                    Text(
                      '$error',
                      style: TextStyle(
                        color: AppColors.alpha(AppColors.ember, 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

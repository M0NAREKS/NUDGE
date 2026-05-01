import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_settings_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/hydration/hydration_page.dart';
import 'screens/onboarding/setup_profile_page.dart';
import 'screens/shell/app_shell_page.dart';
import 'screens/splash/splash_redirect_page.dart';
import 'screens/social/buddy_page.dart';
import 'services/app_navigation.dart';
import 'utils/app_routes.dart';
import 'utils/theme.dart';

class NudgeApp extends StatelessWidget {
  const NudgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.t('app_name'),
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigation.navigatorKey,
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashRedirectPage(),
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => const RegisterPage(),
        AppRoutes.app: (_) => const AppShellPage(initialTab: 0),
        AppRoutes.home: (_) => const AppShellPage(initialTab: 0),
        AppRoutes.food: (_) => const AppShellPage(initialTab: 1),
        AppRoutes.addFood: (_) => const AppShellPage(initialTab: 1),
        AppRoutes.hydration: (_) => const HydrationPage(),
        AppRoutes.workout: (_) => const AppShellPage(initialTab: 2),
        AppRoutes.coach: (_) => const AppShellPage(initialTab: 3),
        AppRoutes.coachChat: (_) => const AppShellPage(initialTab: 3),
        AppRoutes.profile: (_) => const AppShellPage(initialTab: 4),
        AppRoutes.buddy: (_) => const BuddyPage(),
        AppRoutes.setupProfile: (_) => const SetupProfilePage(),
        AppRoutes.splash: (_) => const SplashRedirectPage(),
      },
    );
  }
}

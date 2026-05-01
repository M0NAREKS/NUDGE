import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/l10n/app_localizations.dart';
import 'package:nudge/providers/food_provider.dart';
import 'package:nudge/providers/health_provider.dart';
import 'package:nudge/providers/user_provider.dart';
import 'package:nudge/screens/food/food_editor_page.dart';
import 'package:nudge/screens/home/home_page.dart';
import 'package:nudge/screens/onboarding/setup_profile_page.dart';
import 'package:nudge/screens/profile/profile_page.dart';
import 'package:nudge/screens/shell/app_shell_page.dart';
import 'package:nudge/screens/splash/splash_redirect_page.dart';
import 'package:nudge/screens/workout/workout_page.dart';
import 'package:nudge/services/ai_calorie_estimator.dart';
import 'package:nudge/services/fatsecret_api_service.dart';
import 'package:nudge/services/models/food_item.dart';
import 'package:nudge/utils/theme.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../helpers/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const completeProfile = AppUserProfile(
    uid: 'user-1',
    email: 'nudge@example.com',
    name: 'Very Long User Name For Responsive Checks',
    age: 28,
    height: 172,
    weight: 68,
    gender: 'female',
    activity: 'moderate',
    dailyCalories: 2100,
  );

  FoodProvider buildFoodProvider({
    FakeNutritionRepository? repository,
    DateTime Function()? now,
  }) {
    final effectiveNow = now ?? DateTime.now;
    return FoodProvider(
      fatSecretApiService: FatSecretApiService(gateway: FakeFunctionsGateway()),
      aiCalorieEstimator: AiCalorieEstimator(gateway: FakeFunctionsGateway()),
      nutritionRepository:
          repository ?? FakeNutritionRepository(now: effectiveNow),
      now: effectiveNow,
    );
  }

  Widget buildLocalizedApp({
    required Widget home,
    List<SingleChildWidget> providers = const [],
  }) {
    final app = MaterialApp(
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

    if (providers.isEmpty) {
      return app;
    }

    return MultiProvider(
      providers: providers,
      child: app,
    );
  }

  Widget buildSplashApp(FakeUserProvider userProvider) {
    return ChangeNotifierProvider<UserProvider>.value(
      value: userProvider,
      child: MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light),
        darkTheme: buildAppTheme(brightness: Brightness.dark),
        locale: const Locale('tr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashRedirectPage(),
        routes: {
          '/login': (_) => const Scaffold(body: Text('login-screen')),
          '/setupProfile': (_) => const Scaffold(body: Text('setup-screen')),
          '/home': (_) => const Scaffold(body: Text('home-screen')),
        },
      ),
    );
  }

  testWidgets('logged out user is routed to login', (tester) async {
    await tester.pumpWidget(
      buildSplashApp(FakeUserProvider(loggedIn: false, ready: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('login-screen'), findsOneWidget);
  });

  testWidgets('incomplete profile is routed to setup', (tester) async {
    await tester.pumpWidget(
      buildSplashApp(
        FakeUserProvider(
          profile: const AppUserProfile(
            uid: 'user-1',
            email: 'nudge@example.com',
            name: 'Fit Coach',
          ),
          ready: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('setup-screen'), findsOneWidget);
  });

  testWidgets('complete profile is routed to home', (tester) async {
    await tester.pumpWidget(
      buildSplashApp(FakeUserProvider(profile: completeProfile, ready: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('home-screen'), findsOneWidget);
  });

  testWidgets('home page does not overflow on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testDate = DateTime(2026, 3, 16);
    final healthProvider = HealthProvider()..syncProfile(completeProfile);
    final repository = FakeNutritionRepository(now: () => testDate);
    repository.seed(
      uid: completeProfile.uid,
      date: testDate,
      meals: const [
        FoodItem(
          id: 'meal-1',
          name: 'Very Long Meal Name For Responsive Layout Validation',
          calories: 430,
          protein: 32,
          carbs: 40,
          fat: 12,
          source: 'fatsecret',
        ),
      ],
    );

    await tester.pumpWidget(
      buildLocalizedApp(
        home: const HomePage(),
        providers: [
          ChangeNotifierProvider<UserProvider>.value(
            value: FakeUserProvider(profile: completeProfile, ready: true),
          ),
          ChangeNotifierProvider<HealthProvider>.value(value: healthProvider),
          ChangeNotifierProvider<FoodProvider>(
            create: (_) =>
                buildFoodProvider(repository: repository, now: () => testDate),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('app shell switches between home food coach and profile tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildLocalizedApp(
        home: AppShellPage(
          pages: const [
            Center(child: Text('home-tab')),
            Center(child: Text('food-tab')),
            Center(child: Text('workout-tab')),
            Center(child: Text('coach-tab')),
            Center(child: Text('profile-tab')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('home-tab'), findsOneWidget);

    await tester.tap(find.text('Beslenme'));
    await tester.pumpAndSettle();
    expect(find.text('food-tab'), findsOneWidget);

    await tester.tap(find.text('Antrenman'));
    await tester.pumpAndSettle();
    expect(find.text('workout-tab'), findsOneWidget);

    await tester.tap(find.text('Koç'));
    await tester.pumpAndSettle();
    expect(find.text('coach-tab'), findsOneWidget);

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('profile-tab'), findsOneWidget);
  });

  testWidgets('setup profile stays accessible when keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildLocalizedApp(
        home: const SetupProfilePage(),
        providers: [
          ChangeNotifierProvider<UserProvider>.value(
            value: FakeUserProvider(profile: completeProfile, ready: true),
          ),
          ChangeNotifierProvider<HealthProvider>(
            create: (_) => HealthProvider(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    expect(find.text('Kaydet ve devam et'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('food editor remains stable on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testDate = DateTime(2026, 3, 16);

    await tester.pumpWidget(
      buildLocalizedApp(
        home: const FoodEditorPage(initialQuery: 'manual meal'),
        providers: [
          ChangeNotifierProvider<UserProvider>.value(
            value: FakeUserProvider(profile: completeProfile, ready: true),
          ),
          ChangeNotifierProvider<FoodProvider>(
            create: (_) => buildFoodProvider(
              repository: FakeNutritionRepository(now: () => testDate),
              now: () => testDate,
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextFormField).first);
    await tester.pumpAndSettle();

    expect(find.text('Yemek ekle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile page does not overflow on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      buildLocalizedApp(
        home: const ProfilePage(),
        providers: [
          ChangeNotifierProvider<UserProvider>.value(
            value: FakeUserProvider(profile: completeProfile, ready: true),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profili düzenle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout page does not overflow on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final testDate = DateTime(2026, 3, 16);
    final repository = FakeNutritionRepository(now: () => testDate);
    final healthProvider = HealthProvider()..syncProfile(completeProfile);

    await tester.pumpWidget(
      buildLocalizedApp(
        home: const WorkoutPage(enableEmbeddedMedia: false),
        providers: [
          ChangeNotifierProvider<UserProvider>.value(
            value: FakeUserProvider(profile: completeProfile, ready: true),
          ),
          ChangeNotifierProvider<HealthProvider>.value(value: healthProvider),
          ChangeNotifierProvider<FoodProvider>(
            create: (_) =>
                buildFoodProvider(repository: repository, now: () => testDate),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bugünkü tempo planı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:nudge/screens/shell/app_shell_page.dart';
import 'package:nudge/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nudge/l10n/app_localizations.dart';

void main() {
  testWidgets('app shell respects initial tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
        home: AppShellPage(
          initialTab: 3,
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

    expect(find.text('coach-tab'), findsOneWidget);
    expect(find.text('home-tab'), findsNothing);
  });
}

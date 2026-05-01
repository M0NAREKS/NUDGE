import 'package:flutter/widgets.dart';

import '../utils/app_routes.dart';

class AppNavigation {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void openRoute(String route) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.canonicalRoute(route),
      (existingRoute) => false,
    );
  }
}

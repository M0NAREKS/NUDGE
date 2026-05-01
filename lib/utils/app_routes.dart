class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const setupProfile = '/setupProfile';
  static const app = '/app';
  static const home = '/home';
  static const food = '/food';
  static const addFood = '/addFood';
  static const hydration = '/hydration';
  static const workout = '/workout';
  static const coach = '/coach';
  static const coachChat = '/coachChat';
  static const profile = '/profile';
  static const buddy = '/buddy';

  static int shellIndexForRoute(String? route) {
    switch (canonicalShellRoute(route)) {
      case food:
        return 1;
      case workout:
        return 2;
      case coach:
        return 3;
      case profile:
        return 4;
      case home:
      default:
        return 0;
    }
  }

  static String shellRouteForIndex(int index) {
    switch (index) {
      case 1:
        return food;
      case 2:
        return workout;
      case 3:
        return coach;
      case 4:
        return profile;
      case 0:
      default:
        return home;
    }
  }

  static String canonicalShellRoute(String? route) {
    switch (canonicalRoute(route)) {
      case food:
        return food;
      case workout:
        return workout;
      case coach:
        return coach;
      case profile:
        return profile;
      default:
        return home;
    }
  }

  static String canonicalRoute(String? route) {
    switch (_normalize(route)) {
      case 'food':
      case 'addfood':
      case '/food':
      case '/addfood':
        return food;
      case 'hydration':
      case '/hydration':
        return hydration;
      case 'workout':
      case '/workout':
        return workout;
      case 'coach':
      case 'coachchat':
      case '/coach':
      case '/coachchat':
        return coach;
      case 'profile':
      case '/profile':
        return profile;
      case 'buddy':
      case '/buddy':
        return buddy;
      case 'app':
      case '/app':
      case 'home':
      case '/home':
      default:
        return home;
    }
  }

  static String _normalize(String? route) {
    return (route ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z/]'),
      '',
    );
  }
}

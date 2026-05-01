import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/theme.dart';

class SplashRedirectPage extends StatefulWidget {
  const SplashRedirectPage({super.key});

  @override
  State<SplashRedirectPage> createState() => _SplashRedirectPageState();
}

class _SplashRedirectPageState extends State<SplashRedirectPage> {
  bool _hasNavigated = false;
  UserProvider? _userProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextProvider = context.read<UserProvider>();
    if (identical(_userProvider, nextProvider)) {
      return;
    }

    _userProvider?.removeListener(_redirectIfNeeded);
    _userProvider = nextProvider;
    _userProvider?.addListener(_redirectIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirectIfNeeded());
  }

  @override
  void dispose() {
    _userProvider?.removeListener(_redirectIfNeeded);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: palette.shellGradient,
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.panelElevated,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: palette.border,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 18),
                Text(
                  l10n.t('splash_preparing'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _redirectIfNeeded() {
    final provider = _userProvider;
    if (!mounted || _hasNavigated || provider == null || !provider.isReady) {
      return;
    }

    final routeName = !provider.isLoggedIn
        ? AppRoutes.login
        : provider.hasCompleteProfile
            ? AppRoutes.home
            : AppRoutes.setupProfile;

    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed(routeName);
  }
}

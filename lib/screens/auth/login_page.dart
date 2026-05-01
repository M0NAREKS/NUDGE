import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  Future<void> _submit(UserProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _error = null);

    try {
      await provider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.splash);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final provider = context.watch<UserProvider>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: palette.accentGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('auth_welcome'),
                      style: TextStyle(
                        color: palette.onPanel,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.t('auth_welcome_subtitle'),
                      style: TextStyle(color: palette.onPanelMuted),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('login_title'),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: l10n.t('email'),
                                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (value) => value != null && value.contains('@')
                                    ? null
                                    : l10n.t('valid_email_error'),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: l10n.t('password'),
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                ),
                                obscureText: true,
                                validator: (value) => value != null && value.length >= 6
                                    ? null
                                    : l10n.t('min_chars_error'),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: provider.isLoading ? null : () => _submit(provider),
                                  child: provider.isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(l10n.t('login_title')),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: provider.isLoading
                                      ? null
                                      : () async {
                                          final navigator = Navigator.of(context);
                                          setState(() => _error = null);
                                          try {
                                            await provider.loginWithGoogle();
                                            if (!mounted) return;
                                            navigator.pushReplacementNamed(AppRoutes.splash);
                                          } catch (error) {
                                            if (!mounted) return;
                                            setState(() => _error = _errorMessage(error));
                                          }
                                        },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.account_circle_outlined),
                                      const SizedBox(width: 8),
                                      Flexible(child: Text(l10n.t('google_login'))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.t('no_account'),
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushReplacementNamed(
                                      context,
                                      AppRoutes.register,
                                    ),
                                    child: Text(l10n.t('register_title')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.replaceFirst('Exception: ', '')
        : message;
  }
}

import 'package:flutter/material.dart';
import 'package:nudge/screens/shell/app_shell_page.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Mobile Navigation',
  type: AppShellPage,
  path: '[Responsive]/Shell',
)
Widget appShellMobileUseCase(BuildContext context) {
  return SizedBox(
    width: 390,
    height: 844,
    child: AppShellPage(
      pages: const [
        _PreviewPage(title: 'Home preview'),
        _PreviewPage(title: 'Food preview'),
        _PreviewPage(title: 'Workout preview'),
        _PreviewPage(title: 'Coach preview'),
        _PreviewPage(title: 'Profile preview'),
      ],
    ),
  );
}

class _PreviewPage extends StatelessWidget {
  const _PreviewPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF101733), Color(0xFF171D3E), Color(0xFF211C40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

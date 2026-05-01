import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action, this.actionLabel});

  final String title;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            child: Text(actionLabel ?? context.l10n.t('view_all')),
          ),
      ],
    );
  }
}

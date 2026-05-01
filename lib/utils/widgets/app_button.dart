import 'package:flutter/material.dart';

import '../colors.dart';
import '../theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.variant = ButtonVariant.filled,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final ButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = context.palette;
    final isFilled = variant == ButtonVariant.filled;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: isFilled ? Colors.white : colorScheme.primary),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isFilled ? Colors.white : colorScheme.primary,
            ),
          ),
        ),
      ],
    );

    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isFilled ? colorScheme.primary : palette.panelElevated,
        elevation: isFilled ? 3 : 0,
        shadowColor: isFilled
            ? AppColors.alpha(colorScheme.primary, 0.3)
            : Colors.transparent,
        foregroundColor: isFilled ? Colors.white : colorScheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isFilled
              ? BorderSide.none
              : BorderSide(
                  color: AppColors.alpha(colorScheme.primary, 0.4),
                  width: 1.2,
                ),
        ),
      ),
      onPressed: onPressed,
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum ButtonVariant { filled, outlined }

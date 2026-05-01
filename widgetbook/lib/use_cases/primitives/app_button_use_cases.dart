import 'package:flutter/material.dart';
import 'package:nudge/utils/widgets/app_button.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Filled',
  type: AppButton,
  path: '[Primitives]/Buttons',
)
Widget filledAppButtonUseCase(BuildContext context) {
  return AppButton(
    label: 'Planı kaydet',
    icon: Icons.auto_awesome_rounded,
    onPressed: () {},
  );
}

@widgetbook.UseCase(
  name: 'Outlined Long Label',
  type: AppButton,
  path: '[Primitives]/Buttons',
)
Widget outlinedLongLabelAppButtonUseCase(BuildContext context) {
  return AppButton(
    label: 'Bu buton küçük ekranda taşmamalı ve okunabilir kalmalı',
    icon: Icons.tips_and_updates_outlined,
    onPressed: () {},
    variant: ButtonVariant.outlined,
  );
}

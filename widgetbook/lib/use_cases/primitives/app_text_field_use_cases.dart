import 'package:flutter/material.dart';
import 'package:nudge/utils/widgets/app_text_field.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Default',
  type: AppTextField,
  path: '[Primitives]/Inputs',
)
Widget appTextFieldDefaultUseCase(BuildContext context) {
  final controller = TextEditingController(text: '');
  return SizedBox(
    width: 320,
    child: AppTextField(
      controller: controller,
      label: 'Yemek veya porsiyon girin',
    ),
  );
}

@widgetbook.UseCase(
  name: 'Long Label',
  type: AppTextField,
  path: '[Primitives]/Inputs',
)
Widget appTextFieldLongLabelUseCase(BuildContext context) {
  final controller = TextEditingController(text: '200');
  return SizedBox(
    width: 320,
    child: AppTextField(
      controller: controller,
      label: 'Bu alan küçük ekranda da net ve dengeli görünmeli',
      keyboardType: TextInputType.number,
    ),
  );
}

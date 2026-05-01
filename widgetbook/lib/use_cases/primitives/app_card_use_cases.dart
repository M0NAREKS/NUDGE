import 'package:flutter/material.dart';
import 'package:nudge/utils/widgets/app_card.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(
  name: 'Insight Summary',
  type: AppCard,
  path: '[Primitives]/Cards',
)
Widget appCardInsightUseCase(BuildContext context) {
  return AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Günlük analiz',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 10),
        Text(
          'Tutarlılık skorun dengeli. Yarın için tek aksiyon: akşam öğününü daha erken tamamla.',
        ),
      ],
    ),
  );
}

// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_workspace/use_cases/primitives/app_button_use_cases.dart'
    as _widgetbook_workspace_use_cases_primitives_app_button_use_cases;
import 'package:widgetbook_workspace/use_cases/primitives/app_card_use_cases.dart'
    as _widgetbook_workspace_use_cases_primitives_app_card_use_cases;
import 'package:widgetbook_workspace/use_cases/primitives/app_text_field_use_cases.dart'
    as _widgetbook_workspace_use_cases_primitives_app_text_field_use_cases;
import 'package:widgetbook_workspace/use_cases/shell/app_shell_use_cases.dart'
    as _widgetbook_workspace_use_cases_shell_app_shell_use_cases;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookCategory(
    name: 'Primitives',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'Buttons',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Filled',
                builder:
                    _widgetbook_workspace_use_cases_primitives_app_button_use_cases
                        .filledAppButtonUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Outlined Long Label',
                builder:
                    _widgetbook_workspace_use_cases_primitives_app_button_use_cases
                        .outlinedLongLabelAppButtonUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Cards',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Insight Summary',
                builder:
                    _widgetbook_workspace_use_cases_primitives_app_card_use_cases
                        .appCardInsightUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'Inputs',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppTextField',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _widgetbook_workspace_use_cases_primitives_app_text_field_use_cases
                        .appTextFieldDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Long Label',
                builder:
                    _widgetbook_workspace_use_cases_primitives_app_text_field_use_cases
                        .appTextFieldLongLabelUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookCategory(
    name: 'Responsive',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'Shell',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AppShellPage',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Mobile Navigation',
                builder:
                    _widgetbook_workspace_use_cases_shell_app_shell_use_cases
                        .appShellMobileUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];

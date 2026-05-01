import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/food_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/models/food_item.dart';
import '../../utils/colors.dart';

class FoodEditorPage extends StatefulWidget {
  const FoodEditorPage({
    super.key,
    this.initialItem,
    this.initialQuery,
  });

  final FoodItem? initialItem;
  final String? initialQuery;

  @override
  State<FoodEditorPage> createState() => _FoodEditorPageState();
}

class _FoodEditorPageState extends State<FoodEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gramsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  bool _saving = false;

  FoodItem? get _initialItem => widget.initialItem;
  bool get _isEditing => _initialItem?.isPersisted ?? false;

  @override
  void initState() {
    super.initState();
    final item = _initialItem;
    _nameController = TextEditingController(text: item?.name ?? widget.initialQuery ?? '');
    _gramsController = TextEditingController(
      text: _formatOptionalAmount(item?.selectedGrams ?? item?.servingGrams),
    );
    _caloriesController = TextEditingController(
      text: item != null && item.calories > 0 ? item.calories.toString() : '',
    );
    _proteinController = TextEditingController(
      text: item != null && item.protein > 0 ? item.protein.toStringAsFixed(1) : '',
    );
    _carbsController = TextEditingController(
      text: item != null && item.carbs > 0 ? item.carbs.toStringAsFixed(1) : '',
    );
    _fatController = TextEditingController(
      text: item != null && item.fat > 0 ? item.fat.toStringAsFixed(1) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = _initialItem;
    final source = item?.source ?? 'manual';
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.t('food_edit_title') : l10n.t('food_detail_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6750A4), Color(0xFF007F8F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaChip(label: l10n.sourceLabel(source), darkText: false),
                          if ((item?.amountLabel?.isNotEmpty ?? false))
                            _MetaChip(label: item!.amountLabel!, darkText: false),
                          if (item?.isEstimated ?? false)
                            _MetaChip(label: l10n.t('estimated_data'), darkText: false),
                          if ((item?.confidence ?? 0) > 0)
                            _MetaChip(
                              label: l10n.t(
                                'confidence_short',
                                params: {
                                  'value':
                                      '${(item!.confidence! * 100).round()}',
                                },
                              ),
                              darkText: false,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.t('food_name'),
                        prefixIcon: const Icon(Icons.fastfood_outlined),
                      ),
                      validator: (value) => value != null && value.trim().isNotEmpty
                          ? null
                          : l10n.t('food_name_required'),
                    ),
                    if (item?.hasServingInfo ?? false) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.alpha(AppColors.secondary, 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.alpha(AppColors.secondary, 0.16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.t('base_portion')}: ${item!.baseServingLabel ?? l10n.t('unknown')}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.t('grams_hint'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _gramsController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: _handleGramChange,
                        decoration: InputDecoration(
                          labelText: l10n.t('grams_label'),
                          prefixIcon: const Icon(Icons.scale_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = _parseNullableDouble(value);
                          if (parsed == null || parsed <= 0) {
                            return l10n.t('grams_invalid');
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    _NumberField(
                      controller: _caloriesController,
                      label: l10n.t('calories_title'),
                      icon: Icons.local_fire_department_outlined,
                      isRequired: true,
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 360;
                        final fields = [
                          _NumberField(
                            controller: _proteinController,
                            label: l10n.t('protein_grams'),
                            icon: Icons.fitness_center,
                          ),
                          _NumberField(
                            controller: _carbsController,
                            label: l10n.t('carbs_grams'),
                            icon: Icons.grain_outlined,
                          ),
                          _NumberField(
                            controller: _fatController,
                            label: l10n.t('fat_grams'),
                            icon: Icons.opacity_outlined,
                          ),
                        ];

                        if (compact) {
                          return Column(
                            children: [
                              fields[0],
                              const SizedBox(height: 12),
                              fields[1],
                              const SizedBox(height: 12),
                              fields[2],
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: fields[0]),
                                const SizedBox(width: 12),
                                Expanded(child: fields[1]),
                              ],
                            ),
                            const SizedBox(height: 12),
                            fields[2],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.check_circle_outline),
                        label: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isEditing ? l10n.t('save_changes') : l10n.t('add_food_title')),
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : _delete,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(l10n.t('delete_meal_title')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final userProvider = context.read<UserProvider>();
    final foodProvider = context.read<FoodProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      final baseItem = _initialItem;
      final selectedGrams = _parseNullableDouble(_gramsController.text);
      final item = FoodItem(
        id: baseItem?.id ?? '',
        name: _nameController.text.trim(),
        calories: _parseInt(_caloriesController.text),
        protein: _parseDouble(_proteinController.text),
        carbs: _parseDouble(_carbsController.text),
        fat: _parseDouble(_fatController.text),
        source: baseItem?.source ?? 'manual',
        baseCalories: baseItem?.resolvedBaseCalories ?? _parseInt(_caloriesController.text),
        baseProtein: baseItem?.resolvedBaseProtein ?? _parseDouble(_proteinController.text),
        baseCarbs: baseItem?.resolvedBaseCarbs ?? _parseDouble(_carbsController.text),
        baseFat: baseItem?.resolvedBaseFat ?? _parseDouble(_fatController.text),
        servingLabel: baseItem?.servingLabel,
        servingGrams: baseItem?.servingGrams,
        selectedGrams: selectedGrams,
        isEstimated: baseItem?.isEstimated ?? false,
        confidence: baseItem?.confidence,
        createdAt: baseItem?.createdAt,
      );

      if (_isEditing) {
        await foodProvider.updateFood(userProvider: userProvider, item: item);
      } else {
        await foodProvider.addFood(userProvider: userProvider, item: item);
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_isEditing ? l10n.t('meal_updated') : l10n.t('meal_added'))),
      );
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('operation_failed', params: {'error': '$error'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final baseItem = _initialItem;
    if (baseItem == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.t('delete_meal_title')),
          content: Text(l10n.t('delete_meal_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.t('delete')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final userProvider = context.read<UserProvider>();
    final foodProvider = context.read<FoodProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      await foodProvider.deleteFood(userProvider: userProvider, item: baseItem);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.t('meal_deleted'))));
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('delete_failed', params: {'error': '$error'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int _parseInt(String raw) {
    return double.tryParse(raw.replaceAll(',', '.'))?.round() ?? 0;
  }

  double? _parseNullableDouble(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  double _parseDouble(String raw) {
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0;
  }

  void _handleGramChange(String raw) {
    final baseItem = _initialItem;
    if (baseItem == null || (baseItem.servingGrams ?? 0) <= 0) {
      return;
    }

    final grams = _parseNullableDouble(raw);
    if (grams == null || grams <= 0) {
      _applyNutritionValues(baseItem);
      return;
    }

    _applyNutritionValues(baseItem.scaleToGrams(grams));
  }

  void _applyNutritionValues(FoodItem item) {
    _caloriesController.text = item.calories.toString();
    _proteinController.text = _formatDecimal(item.protein);
    _carbsController.text = _formatDecimal(item.carbs);
    _fatController.text = _formatDecimal(item.fat);
  }

  String _formatDecimal(double value) {
    if (value == 0) {
      return '';
    }
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatOptionalAmount(double? value) {
    if (value == null || value <= 0) {
      return '';
    }
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.darkText = true});

  final String label;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.alpha(Colors.white, 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: darkText ? AppColors.textDark : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
    this.isRequired = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (!isRequired && (value == null || value.trim().isEmpty)) {
          return null;
        }
        return double.tryParse((value ?? '').replaceAll(',', '.')) != null
            ? null
            : l10n.t('invalid_value', params: {'field': label});
      },
    );
  }
}


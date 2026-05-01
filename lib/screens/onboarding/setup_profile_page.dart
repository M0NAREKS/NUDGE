import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_routes.dart';
import '../../utils/theme.dart';

class SetupProfilePage extends StatefulWidget {
  const SetupProfilePage({super.key});

  @override
  State<SetupProfilePage> createState() => _SetupProfilePageState();
}

class _SetupProfilePageState extends State<SetupProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = 'male';
  String _activity = 'light';
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void dispose() {
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final userProvider = context.read<UserProvider>();
    final healthProvider = context.read<HealthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      await userProvider.updateProfile(
        gender: _gender,
        birthDate: _birthDate,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        activity: _activity,
      );
      healthProvider.syncUser(userProvider);
      await healthProvider.saveProfile(userProvider);
      if (!mounted) return;
      navigator.pushReplacementNamed(AppRoutes.home);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 22, now.month, now.day),
      firstDate: DateTime(now.year - 100, 1, 1),
      lastDate: now,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthDate = DateTime(selected.year, selected.month, selected.day);
      _birthDateController.text = _formatBirthDate(selected);
    });
  }

  String _formatBirthDate(DateTime date) {
    return DateFormat.yMd(Localizations.localeOf(context).languageCode).format(
      date,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: palette.accentGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + viewInsets),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.t('setup_title'),
                          style: TextStyle(
                            color: palette.onPanel,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.t('setup_subtitle'),
                    style: TextStyle(color: palette.onPanelMuted),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _SegmentedSelector<String>(
                              title: l10n.t('gender'),
                              value: _gender,
                              onChanged: (value) => setState(() => _gender = value),
                              options: {
                                'male': l10n.t('male'),
                                'female': l10n.t('female'),
                              },
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isCompact = constraints.maxWidth < 360;
                                final fields = [
                                  _DateField(
                                    controller: _birthDateController,
                                    label: l10n.t('birth_date'),
                                    icon: Icons.cake_outlined,
                                    onTap: _pickBirthDate,
                                  ),
                                  _NumberField(
                                    controller: _heightController,
                                    label: l10n.t('height_cm'),
                                    icon: Icons.height,
                                  ),
                                ];

                                if (isCompact) {
                                  return Column(
                                    children: [
                                      fields[0],
                                      const SizedBox(height: 12),
                                      fields[1],
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: fields[0]),
                                    const SizedBox(width: 12),
                                    Expanded(child: fields[1]),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            _NumberField(
                              controller: _weightController,
                              label: l10n.t('weight_kg'),
                              icon: Icons.monitor_weight_outlined,
                            ),
                            const SizedBox(height: 12),
                            _SegmentedSelector<String>(
                              title: l10n.t('activity_level'),
                              value: _activity,
                              onChanged: (value) => setState(() => _activity = value),
                              options: {
                                'sedentary': l10n.t('activity_sedentary'),
                                'light': l10n.t('activity_light'),
                                'moderate': l10n.t('activity_moderate'),
                                'active': l10n.t('activity_active'),
                                'athlete': l10n.t('activity_athlete'),
                                'very_active': l10n.t('activity_very_active'),
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _saveProfile,
                                icon: const Icon(Icons.save_rounded),
                                label: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(l10n.t('continue_button')),
                              ),
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
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (value) => value != null && value.trim().isNotEmpty
          ? null
          : context.l10n.t(
              'field_required',
              params: {'field': label},
            ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      validator: (value) => value != null && value.trim().isNotEmpty
          ? null
          : context.l10n.t(
              'field_required',
              params: {'field': label},
            ),
    );
  }
}

class _SegmentedSelector<T> extends StatelessWidget {
  const _SegmentedSelector({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String title;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final selected = entry.key == value;
            return ChoiceChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onChanged(entry.key),
            );
          }).toList(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/health_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = 'male';
  String _activity = 'light';
  DateTime? _birthDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().profile;
    if (user != null) {
      _nameController.text = user.name;
      _birthDate = user.birthDate;
      if (_birthDate != null) {
        _birthDateController.text = _formatBirthDate(_birthDate!);
      }
      _heightController.text = user.height?.toString() ?? '';
      _weightController.text = user.weight?.toString() ?? '';
      _gender = user.gender ?? _gender;
      _activity = user.activity ?? _activity;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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

    setState(() => _saving = true);
    try {
      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        gender: _gender,
        birthDate: _birthDate,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        activity: _activity,
      );
      healthProvider.syncUser(userProvider);
      await healthProvider.saveProfile(userProvider);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('profile_update_failed', params: {'error': '$error'}),
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
    final palette = context.palette;
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(l10n.t('profile_edit')),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: palette.shellGradient),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: palette.heroGradient,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('profile_settings_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: palette.onPanel,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.t('profile_settings_desc'),
                        style: TextStyle(
                          color: palette.onPanelMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: palette.panelElevated,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: palette.border),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _ProfileField(
                          controller: _nameController,
                          label: l10n.t('full_name'),
                          icon: Icons.person_outline_rounded,
                          validator: (value) => value != null && value.trim().isNotEmpty
                              ? null
                              : l10n.t(
                                  'field_required',
                                  params: {'field': l10n.t('full_name')},
                                ),
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 360;
                            final fields = [
                              _DateProfileField(
                                controller: _birthDateController,
                                label: l10n.t('birth_date'),
                                icon: Icons.cake_outlined,
                                onTap: _pickBirthDate,
                              ),
                              _ProfileField(
                                controller: _heightController,
                                label: l10n.t('height_cm'),
                                icon: Icons.height,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        _ProfileField(
                          controller: _weightController,
                          label: l10n.t('weight_kg'),
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(title: l10n.t('gender')),
                        const SizedBox(height: 8),
                        _PillSelector<String>(
                          value: _gender,
                          options: {
                            'male': l10n.t('male'),
                            'female': l10n.t('female'),
                          },
                          onChanged: (value) => setState(() => _gender = value),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(title: l10n.t('activity_level')),
                        const SizedBox(height: 8),
                        _PillSelector<String>(
                          value: _activity,
                          options: {
                            'sedentary': l10n.t('activity_sedentary'),
                            'light': l10n.t('activity_light'),
                            'moderate': l10n.t('activity_moderate'),
                            'active': l10n.t('activity_active'),
                            'athlete': l10n.t('activity_athlete'),
                            'very_active': l10n.t('activity_very_active'),
                          },
                          onChanged: (value) => setState(() => _activity = value),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _saveProfile,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _saving ? l10n.t('saving') : l10n.t('save_changes'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: false),
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator ??
          (value) => value != null && value.trim().isNotEmpty
              ? null
              : l10n.t('field_required', params: {'field': label}),
      style: TextStyle(color: palette.onPanel, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.onPanelMuted),
        prefixIcon: Icon(icon, color: palette.onPanelMuted),
        filled: true,
        fillColor: palette.panelSoft,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: palette.onPanel,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DateProfileField extends StatelessWidget {
  const _DateProfileField({
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
    final palette = context.palette;
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: (value) => value != null && value.trim().isNotEmpty
          ? null
          : l10n.t('field_required', params: {'field': label}),
      style: TextStyle(color: palette.onPanel, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: palette.onPanelMuted),
        prefixIcon: Icon(icon, color: palette.onPanelMuted),
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          color: palette.onPanelMuted,
        ),
        filled: true,
        fillColor: palette.panelSoft,
      ),
    );
  }
}

class _PillSelector<T> extends StatelessWidget {
  const _PillSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final selected = entry.key == value;
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onChanged(entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.alpha(AppColors.secondary, 0.22)
                  : palette.panelSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? AppColors.alpha(AppColors.secondary, 0.32)
                    : palette.border,
              ),
            ),
            child: Text(
              entry.value,
              style: TextStyle(
                color: palette.onPanel,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

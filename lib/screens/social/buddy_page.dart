import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/buddy_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/models/buddy_connection.dart';
import '../../services/models/buddy_request.dart';
import '../../services/models/shared_daily_status.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class BuddyPage extends StatefulWidget {
  const BuddyPage({super.key});

  @override
  State<BuddyPage> createState() => _BuddyPageState();
}

class _BuddyPageState extends State<BuddyPage> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final user = context.watch<UserProvider>().profile;
    final buddyProvider = context.watch<BuddyProvider>();

    if (user == null) {
      return Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(title: Text(l10n.t('buddy_title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(l10n.t('buddy_title'))),
      body: Container(
        decoration: BoxDecoration(gradient: palette.shellGradient),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _BuddyHero(name: user.name),
              const SizedBox(height: 16),
              _InvitePanel(
                controller: _emailController,
                busy: buddyProvider.isBusy,
                onSend: () async {
                  final email = _emailController.text.trim();
                  if (email.isEmpty) return;
                  final provider = context.read<BuddyProvider>();
                  final userProvider = context.read<UserProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  final sentMessage = l10n.t('buddy_request_sent');
                  try {
                    await provider.sendRequest(
                          userProvider: userProvider,
                          buddyEmail: email,
                        );
                    if (!mounted) return;
                    _emailController.clear();
                    messenger.showSnackBar(
                      SnackBar(content: Text(sentMessage)),
                    );
                  } catch (error) {
                    if (!mounted) return;
                    final message = provider.errorMessage ?? '$error';
                    messenger.showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<BuddyRequest>>(
                stream: buddyProvider.incomingRequests(user.uid),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? const <BuddyRequest>[];
                  return _RequestsPanel(requests: requests);
                },
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<BuddyConnection>>(
                stream: buddyProvider.buddies(user.uid),
                builder: (context, snapshot) {
                  final buddies = snapshot.data ?? const <BuddyConnection>[];
                  return _BuddyListPanel(buddies: buddies);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuddyHero extends StatelessWidget {
  const _BuddyHero({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: palette.heroGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('buddy_small_title'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: palette.onPanelMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t(
              'buddy_greeting',
              params: {'name': name.split(' ').first},
            ),
            style: TextStyle(
              color: palette.onPanel,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('buddy_summary'),
            style: TextStyle(
              color: palette.onPanelMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitePanel extends StatelessWidget {
  const _InvitePanel({
    required this.controller,
    required this.busy,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('buddy_invite_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.onPanel,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.t('buddy_invite_desc'),
            style: TextStyle(color: palette.onPanelMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: l10n.t('buddy_email_hint'),
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onSend,
              icon: const Icon(Icons.person_add_alt_rounded),
              label: Text(l10n.t('buddy_send_request')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsPanel extends StatelessWidget {
  const _RequestsPanel({required this.requests});

  final List<BuddyRequest> requests;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('buddy_requests_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.onPanel,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (requests.isEmpty)
            Text(
              l10n.t('buddy_requests_empty'),
              style: TextStyle(color: palette.onPanelMuted),
            )
          else
            ...[
              for (final request in requests) ...[
                _RequestTile(request: request),
                if (request != requests.last) const SizedBox(height: 10),
              ],
            ],
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final BuddyRequest request;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.fromName,
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.fromEmail,
            style: TextStyle(color: palette.onPanelMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await context.read<BuddyProvider>().acceptRequest(
                          request: request,
                        );
                  },
                  child: Text(context.l10n.t('buddy_accept')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<BuddyProvider>().declineRequest(request);
                  },
                  child: Text(context.l10n.t('buddy_decline')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuddyListPanel extends StatelessWidget {
  const _BuddyListPanel({required this.buddies});

  final List<BuddyConnection> buddies;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('buddy_list_title'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.onPanel,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          if (buddies.isEmpty)
            Text(
              l10n.t('buddy_list_empty'),
              style: TextStyle(color: palette.onPanelMuted),
            )
          else
            ...[
              for (final buddy in buddies) ...[
                _BuddyTile(buddy: buddy),
                if (buddy != buddies.last) const SizedBox(height: 10),
              ],
            ],
        ],
      ),
    );
  }
}

class _BuddyTile extends StatelessWidget {
  const _BuddyTile({required this.buddy});

  final BuddyConnection buddy;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: StreamBuilder<SharedDailyStatus>(
        stream: context.read<BuddyProvider>().sharedStatusForToday(buddy.uid),
        builder: (context, snapshot) {
          final status = snapshot.data ?? SharedDailyStatus.empty();
          final liters = (status.waterMl / 1000).toStringAsFixed(2);
          final goalLiters = (status.waterGoalMl / 1000).toStringAsFixed(2);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.alpha(AppColors.info, 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buddy.name,
                          style: TextStyle(
                            color: palette.onPanel,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          buddy.email,
                          style: TextStyle(color: palette.onPanelMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _BuddyMetric(
                      label: context.l10n.t('hydration_consumed'),
                      value: '$liters L',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BuddyMetric(
                      label: context.l10n.t('hydration_goal'),
                      value: '$goalLiters L',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: status.progress,
                  minHeight: 10,
                  backgroundColor: AppColors.alpha(palette.onPanel, 0.12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('buddy_nudge_helper'),
                style: TextStyle(
                  color: palette.onPanelMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: context.watch<BuddyProvider>().isBusy
                      ? null
                      : () async {
                          final provider = context.read<BuddyProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final localeCode =
                              context.read<AppSettingsProvider>().localeCode;
                          try {
                            await provider.sendNudge(
                              buddy: buddy,
                              localeCode: localeCode,
                            );
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(l10n.t('buddy_nudge_sent')),
                              ),
                            );
                          } catch (error) {
                            if (!context.mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(provider.errorMessage ?? '$error'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: Text(l10n.t('buddy_nudge_action')),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BuddyMetric extends StatelessWidget {
  const _BuddyMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alpha(palette.onPanel, 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.alpha(palette.onPanel, 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: palette.onPanelMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: palette.onPanel,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

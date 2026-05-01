import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/app_analytics.dart';
import '../../services/groq_coach_service.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class CoachChatPage extends StatefulWidget {
  const CoachChatPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<CoachChatPage> createState() => _CoachChatPageState();
}

class _CoachChatPageState extends State<CoachChatPage> {
  final _messages = <_ChatMessage>[];
  final _controller = TextEditingController();
  late final GroqCoachService _service;
  bool _loading = false;
  String? _lastTrackedMode;

  @override
  void initState() {
    super.initState();
    _service = GroqCoachService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = context.watch<AppSettingsProvider>().coachMode;
    if (_lastTrackedMode == mode) return;
    _lastTrackedMode = mode;
    context.read<AppAnalytics>().logEvent(
      'coach_chat_opened',
      {'mode': mode},
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(String mode) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = context.read<UserProvider>().profile;
    final localeCode = context.read<AppSettingsProvider>().localeCode;
    if (user == null) return;

    setState(() {
      _messages.add(_ChatMessage(role: 'user', content: text));
      _controller.clear();
      _loading = true;
    });

    final reply = await _service.sendMessage(
      uid: user.uid,
      content: text,
      mode: mode,
      localeCode: localeCode,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(role: 'assistant', content: reply));
      _loading = false;
    });
    await context.read<AppAnalytics>().logEvent(
      'coach_reply_received',
      {
        'mode': mode,
        'reply_length': reply.length,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final mode = context.watch<AppSettingsProvider>().coachMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final navigationInset =
        widget.embedded ? MediaQuery.paddingOf(context).bottom + 92.0 : 0.0;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    final content = Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: palette.panelElevated,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: palette.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.alpha(palette.shadow, 0.6),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: _messages.isEmpty
                ? const _EmptyChatState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.role == 'user';
                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.alpha(AppColors.secondary, 0.18)
                                : palette.panelSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUser
                                  ? AppColors.alpha(AppColors.secondary, 0.28)
                                  : palette.border,
                            ),
                          ),
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: palette.onPanel,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            12 + bottomInset + navigationInset,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(
                    color: palette.onPanel,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.t('coach_input_hint'),
                    prefixIcon: Icon(
                      Icons.edit_outlined,
                      color: palette.onPanelMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : () => _send(mode),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(58, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(l10n.t('coach_title'))),
      body: SafeArea(child: content),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.ember,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t('coach_empty_state'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.onPanelMuted,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.role, required this.content});

  final String role;
  final String content;
}

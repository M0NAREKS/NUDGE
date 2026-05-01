import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/food_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/models/food_item.dart';
import '../../utils/app_page_route.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';
import 'food_editor_page.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onSearch(FoodProvider provider) async {
    FocusScope.of(context).unfocus();
    await provider.searchFood(_controller.text);
  }

  Future<void> _openEditor({FoodItem? item, String? initialQuery}) async {
    final saved = await Navigator.of(context).push<bool>(
      buildAppPageRoute(
        FoodEditorPage(
          initialItem: item,
          initialQuery: initialQuery,
        ),
      ),
    );

    if (saved == true && mounted && !widget.embedded) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodProvider = context.watch<FoodProvider>();
    final userProvider = context.watch<UserProvider>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = context.palette;
    final hasQuery = _controller.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final embeddedBottomSpacing =
        widget.embedded ? MediaQuery.paddingOf(context).bottom + 108.0 : 0.0;
    final quickQueries = l10n.isEnglish
        ? const [
            'apple',
            'boiled egg',
            'grilled chicken',
            'bowl of yogurt',
            'boiled rice',
          ]
        : const [
            'elma',
            'haşlanmış yumurta',
            'ızgara tavuk',
            'kase yoğurt',
            'haşlanmış pilav',
          ];

    final content = GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + bottomInset + embeddedBottomSpacing,
        ),
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: palette.heroGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.alpha(palette.onPanel, 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.restaurant_menu_rounded,
                    color: palette.onPanel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('search_food_or_manual'),
                        style: TextStyle(
                          color: palette.onPanel,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.t('search_food_desc'),
                        style: TextStyle(
                          color: palette.onPanelMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _onSearch(foodProvider),
                  decoration: InputDecoration(
                    hintText: l10n.t('search_hint'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: foodProvider.isLoading ? null : () => _onSearch(foodProvider),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(66, 58),
                ),
                child: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final query in quickQueries)
                ActionChip(
                  label: Text(query),
                  onPressed: () {
                    _controller.text = query;
                    _onSearch(foodProvider);
                  },
                  backgroundColor: palette.panelElevated,
                  side: BorderSide(color: palette.border),
                  labelStyle: TextStyle(
                    color: palette.onPanel,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openEditor(initialQuery: _controller.text.trim()),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l10n.t('manual_entry')),
                style: OutlinedButton.styleFrom(
                  backgroundColor: palette.panelElevated,
                  foregroundColor: palette.onPanel,
                  side: BorderSide(color: palette.border),
                ),
              ),
              if (hasQuery && userProvider.profile != null)
                TextButton.icon(
                  onPressed: () => _openEditor(initialQuery: _controller.text.trim()),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: Text(l10n.t('start_with_query')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ember,
                  ),
                ),
            ],
          ),
          if (foodProvider.helperMessage != null) ...[
            const SizedBox(height: 10),
            _MessageBanner(
              message: foodProvider.helperMessage!,
              color: AppColors.secondary,
            ),
          ],
          if (foodProvider.errorMessage != null) ...[
            const SizedBox(height: 10),
            _MessageBanner(
              message: foodProvider.errorMessage!,
              color: AppColors.danger,
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.t('results'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.onPanel,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (foodProvider.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (foodProvider.results.isEmpty)
            _EmptyState(
              hasQuery: hasQuery,
              onManualEntry: () => _openEditor(initialQuery: _controller.text.trim()),
            )
          else
            ...[
              for (final item in foodProvider.results) ...[
                _FoodTile(
                  item: item,
                  onAdd: () => _openEditor(item: item),
                ),
                const SizedBox(height: 8),
              ],
            ],
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('add_food_title'))),
      body: SafeArea(child: content),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.item, required this.onAdd});

  final FoodItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mutedStyle = Theme.of(context).textTheme.labelMedium;
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.alpha(AppColors.secondary, 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fastfood_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: palette.onPanel,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.t(
                            'food_source',
                            params: {'source': l10n.sourceLabel(item.source)},
                          ),
                          style: mutedStyle?.copyWith(
                            color: palette.onPanelMuted,
                          ),
                        ),
                        if (item.amountLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            l10n.t(
                              'food_portion',
                              params: {'portion': item.amountLabel!},
                            ),
                            style: mutedStyle?.copyWith(
                              color: palette.onPanelMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onAdd,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                    icon: const Icon(Icons.edit),
                    label: Text(l10n.t('edit')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _FoodMetaChip(label: '${item.calories} kcal'),
                  if (item.amountLabel != null) _FoodMetaChip(label: item.amountLabel!),
                  _FoodMetaChip(label: 'P ${item.protein.toStringAsFixed(1)}g'),
                  _FoodMetaChip(label: 'C ${item.carbs.toStringAsFixed(1)}g'),
                  _FoodMetaChip(label: 'F ${item.fat.toStringAsFixed(1)}g'),
                  if (item.isEstimated) _FoodMetaChip(label: l10n.t('estimated_tag')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery, required this.onManualEntry});

  final bool hasQuery;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.panelElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fastfood_outlined,
            size: 52,
            color: AppColors.ember,
          ),
          const SizedBox(height: 10),
          Text(
            hasQuery
                ? l10n.t('search_empty_with_query')
                : l10n.t('search_empty_without_query'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.onPanelMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onManualEntry,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(l10n.t('manual_entry_open')),
            style: OutlinedButton.styleFrom(
              backgroundColor: palette.panelSoft,
              foregroundColor: palette.onPanel,
              side: BorderSide(color: palette.border),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodMetaChip extends StatelessWidget {
  const _FoodMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Chip(
      label: Text(label),
      labelStyle: TextStyle(
        color: palette.onPanel,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: palette.panelSoft,
      side: BorderSide(color: palette.border),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alpha(color, 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.alpha(color, 0.2)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/loading_label.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/surface_card.dart';
import '../services/service_api.dart';
import '../services/service_categories_provider.dart';
import '../services/service_category.dart';
import 'auth_controller.dart';

/// Reached when `isValidToken` reports `IsServiceSelected: false`, i.e. the
/// partner is logged in but has not picked the services they offer yet.
class SelectServiceScreen extends ConsumerStatefulWidget {
  const SelectServiceScreen({super.key});

  @override
  ConsumerState<SelectServiceScreen> createState() =>
      _SelectServiceScreenState();
}

class _SelectServiceScreenState extends ConsumerState<SelectServiceScreen> {
  final Set<int> _selected = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Pre-tick anything already saved, so re-visiting edits instead of resets.
    _selected.addAll(ref.read(selectedCategoryIdsProvider));
  }

  void _toggle(int id, bool on) {
    setState(() => on ? _selected.add(id) : _selected.remove(id));
  }

  /// Saves the picks, then re-asks the server for `IsServiceSelected`. The
  /// router sends the partner to the dashboard as soon as that flips true.
  Future<void> _submit() async {
    if (_selected.isEmpty || _busy) return;
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);
    try {
      final token = ref.read(authProvider).user?.appToken ?? '';
      await ref
          .read(serviceApiProvider)
          .addCategories(
            appToken: token,
            categoryIds: _selected.toList()..sort(),
          );
      await ref.read(selectedCategoryIdsProvider.notifier).save({..._selected});
      await ref.read(authProvider.notifier).refreshStatus();

      if (!mounted) return;
      if (!ref.read(authProvider).serviceSelected) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Services saved, but setup is still pending.'),
          ),
        );
      }
    } on ApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recheck() async {
    setState(() => _busy = true);
    ref.invalidate(serviceCategoriesProvider);
    await ref.read(authProvider.notifier).refreshStatus();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupedServiceCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is ApiException
              ? error.message
              : 'Something went wrong. Please try again.',
          busy: _busy,
          onRetry: _recheck,
        ),
        data: (data) => data.isEmpty
            ? _EmptyView(busy: _busy, onRetry: _recheck)
            : _CategoryList(
                groups: data,
                selected: _selected,
                onToggle: _toggle,
              ),
      ),
      bottomNavigationBar: groups.hasValue && groups.requireValue.isNotEmpty
          ? _SelectionBar(
              count: _selected.length,
              busy: _busy,
              onRecheck: _recheck,
              onSubmit: _submit,
            )
          : null,
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({
    required this.groups,
    required this.selected,
    required this.onToggle,
  });

  final List<ServiceCategoryGroup> groups;
  final Set<int> selected;
  final void Function(int id, bool on) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = ref.watch(
      authProvider.select((state) => state.user?.fullName ?? ''),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.sm,
        AppSpacing.page,
        AppSpacing.xl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions_rounded,
                color: scheme.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Setup pending',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          name.isEmpty ? 'Almost there' : 'Almost there, $name',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pick every service you can take jobs for. You can change this '
          'later from your profile.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        for (final group in groups) ...[
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: group.group.label),
          const SizedBox(height: AppSpacing.sm),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final category in group.categories)
                  _CategoryRow(
                    category: category,
                    checked: selected.contains(category.id),
                    onChanged: (on) => onToggle(category.id, on),
                    last: category == group.categories.last,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.checked,
    required this.onChanged,
    required this.last,
  });

  final ServiceCategory category;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        CheckboxListTile(
          value: checked,
          onChanged: (value) => onChanged(value ?? false),
          controlAffinity: ListTileControlAffinity.trailing,
          secondary: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Icon(category.icon, size: 22, color: scheme.primary),
          ),
          title: Text(category.name, style: theme.textTheme.titleSmall),
          subtitle: category.subtitle.isEmpty
              ? null
              : Text(
                  category.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
        if (!last)
          Divider(
            height: 1,
            indent: AppSpacing.lg + 40 + AppSpacing.lg,
            color: scheme.outlineVariant,
          ),
      ],
    );
  }
}

/// Sticky footer: selection count, a refresh, and the (not yet wired) submit.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.busy,
    required this.onRecheck,
    required this.onSubmit,
  });

  final int count;
  final bool busy;
  final VoidCallback onRecheck;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    count == 0
                        ? 'Select the services you offer'
                        : '$count selected',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: busy ? null : onRecheck,
                  child: const Text('Check again'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: count == 0 || busy ? null : onSubmit,
              child: LoadingLabel(busy: busy, label: 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.busy, required this.onRetry});

  final bool busy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: EmptyState(
            icon: Icons.category_outlined,
            title: 'No services listed yet',
            message: 'The service list came back empty. Try again in a moment.',
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: FilledButton(
            onPressed: busy ? null : onRetry,
            child: const Text('Check again'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.busy,
    required this.onRetry,
  });

  final String message;
  final bool busy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load services',
            message: message,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: FilledButton(
            onPressed: busy ? null : onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}

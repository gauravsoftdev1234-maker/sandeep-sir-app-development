import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/surface_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Theme', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined, size: 18),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => ref
                      .read(themeModeProvider.notifier)
                      .setMode(selection.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Notifications'),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Column(
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  title: const Text('New job alerts'),
                  subtitle: const Text('Push when a job is assigned to you'),
                ),
                SwitchListTile(
                  value: false,
                  onChanged: (_) {},
                  title: const Text('Promotions'),
                  subtitle: const Text('Offers and product updates'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'About'),
          const SizedBox(height: AppSpacing.md),
          SurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SevaHub Partner',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text('Version 1.0.0', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

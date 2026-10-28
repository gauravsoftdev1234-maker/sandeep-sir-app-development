import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A metric card: a tinted icon circle beside the value and its label.
/// Pass [onTap] to make the whole card pressable, which also shows a
/// trailing chevron.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.value,
    required this.label,
    required this.icon,
    this.accent,
    this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = accent ?? scheme.primary;
    final radius = BorderRadius.circular(AppRadius.card);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: tint),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: Text(
                        value,
                        key: ValueKey(value),
                        style: theme.textTheme.titleLarge?.copyWith(
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

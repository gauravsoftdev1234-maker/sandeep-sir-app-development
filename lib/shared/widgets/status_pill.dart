import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

enum PillTone { neutral, positive, pending, info, negative }

/// Small labelled pill used for task and account status.
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (background, foreground) = switch (tone) {
      PillTone.positive => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      PillTone.pending => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      PillTone.info => (scheme.primaryContainer, scheme.onPrimaryContainer),
      PillTone.negative => (scheme.errorContainer, scheme.onErrorContainer),
      PillTone.neutral => (scheme.surfaceContainer, scheme.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// The app logo, rendered from the generated launcher artwork.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 60, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// Logo plus wordmark, used on the entry screens.
class BrandHeader extends StatelessWidget {
  const BrandHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const BrandMark(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

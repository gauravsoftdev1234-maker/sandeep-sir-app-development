import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Compact service tile: a tinted icon square with a caption, four to a row.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.icon,
    required this.label,
    required this.tint,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.field),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Icon(icon, color: tint, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

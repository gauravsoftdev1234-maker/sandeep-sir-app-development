import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// A padded card surface. Pass [onTap] to make the whole card pressable.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

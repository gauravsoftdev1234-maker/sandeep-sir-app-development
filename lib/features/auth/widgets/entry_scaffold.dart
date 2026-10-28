import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// Shared chrome for the entry screens. The wave, hero photo and the tinted
/// footer band all come from one full-bleed artwork
/// (`assets/images/entry_background.png`), so this widget only positions the
/// wordmark, the form and the service strip on top of it.
class EntryScaffold extends StatelessWidget {
  const EntryScaffold({
    required this.child,
    this.heroFactor = _artworkWaveFactor,
    super.key,
  });

  final Widget child;

  /// Where the white area of the artwork should start, as a share of screen
  /// height. Lowering it shifts the artwork up to make room for taller forms.
  final double heroFactor;

  /// The wave is a curve, not a straight edge: it first breaks into white
  /// here, and dips to [_artworkWaveFactor] at its lowest. Content lines up
  /// with the lowest point, or the first line of the form — the "Create
  /// Account" heading — lands inside the dip, on top of the photo.
  static const double _artworkWaveFactor = 0.321;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons over the blue artwork.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        // LayoutBuilder rather than MediaQuery: on the very first frame the
        // window metrics are still zero, which would give negative heights.
        body: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            // Pulling the artwork up by `shift` also stretches it to
            // `height + shift`, which carries the wave back down. Solving
            // wave * (height + shift) - shift == heroFactor * height keeps
            // the wave on the content edge whatever the hero factor is.
            final shift =
                (height *
                        (_artworkWaveFactor - heroFactor) /
                        (1 - _artworkWaveFactor))
                    .clamp(0.0, height);
            final heroHeight = (height * heroFactor).clamp(0.0, height);

            return Stack(
              children: [
                Positioned(
                  top: -shift,
                  left: 0,
                  right: 0,
                  height: height + shift,
                  child: Image.asset(
                    'assets/images/entry_background.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: heroHeight, child: const _BrandBlock()),
                    Expanded(child: child),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Logo, wordmark and tagline, laid over the blue part of the artwork.
class _BrandBlock extends StatelessWidget {
  const _BrandBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          0,
        ),
        // The hero box is a fixed slice of screen height, so on a short
        // screen — or at a large text scale — the mark, wordmark and tagline
        // together can run a hair taller than it. Scaling down beats an
        // overflow stripe.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LogoGlyph(),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'SevaHub ',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      TextSpan(
                        text: 'Partner',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.accent,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'All Services  |  One Platform',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The brand mark, on the white tile it is drawn for. The mark's house is a
/// cutout, so dropping it straight onto the dark artwork would let the
/// backdrop show through the roof.
class _LogoGlyph extends StatelessWidget {
  const _LogoGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Image.asset('assets/images/brand_mark.png', height: 40),
    );
  }
}

/// The five service shortcuts shown over the artwork's tinted footer band.
class ServiceStrip extends StatelessWidget {
  const ServiceStrip({super.key});

  static const _items = [
    (Icons.build_rounded, 'Home\nServices'),
    (Icons.delivery_dining_rounded, 'Delivery\nServices'),
    (Icons.directions_car_filled_rounded, 'Transport\nServices'),
    (Icons.shopping_bag_rounded, 'Shopping\nServices'),
    (Icons.grid_view_rounded, '& More'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (icon, label) in _items)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(icon, size: 23, color: AppColors.brand),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.brandDeep,
                            fontSize: 11,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Your Work   |   Our Support   |   Bigger Tomorrow',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.brand.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined white field styling used on the entry screens, matching the design.
class EntryFieldTheme extends StatelessWidget {
  const EntryFieldTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const border = Color(0xFFDDE3EC);

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );

    return Theme(
      data: theme.copyWith(
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          fillColor: Colors.white,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF9AA5B5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          prefixIconColor: AppColors.brand,
          suffixIconColor: const Color(0xFF9AA5B5),
          border: outline(border),
          enabledBorder: outline(border),
          focusedBorder: outline(AppColors.brand, 1.5),
        ),
      ),
      child: child,
    );
  }
}

/// Button label with the trailing arrow used on the mockup's primary actions.
class ArrowLabel extends StatelessWidget {
  const ArrowLabel(this.label, {this.busy = false, super.key});

  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        const SizedBox(width: AppSpacing.sm),
        const Icon(Icons.arrow_forward_rounded, size: 18),
      ],
    );
  }
}

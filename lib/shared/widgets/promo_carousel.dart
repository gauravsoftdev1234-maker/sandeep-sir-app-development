import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class PromoBanner {
  const PromoBanner({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  /// A banner whose artwork already has the title, subtitle and button
  /// baked in, so Flutter draws nothing on top of it.
  const PromoBanner.prebaked({required this.image})
    : title = '',
      subtitle = '',
      action = '';

  final String image;
  final String title;
  final String subtitle;
  final String action;

  bool get hasOverlay => title.isNotEmpty;
}

/// Swipeable promo strip, the compact banner row used on the home screen.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({required this.banners, super.key});

  final List<PromoBanner> banners;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  static const _interval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;

    _timer = Timer(_interval, () {
      if (!mounted) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        AspectRatio(
          // Matches the banner artwork's own 1584x672 canvas, so
          // BoxFit.cover never has to crop either edge to fill the row.
          aspectRatio: 1584 / 672,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (value) {
              // A manual swipe restarts the timer so autoplay never fights
              // the page the partner just chose.
              setState(() => _index = value);
              _scheduleNext();
            },
            // A full-width page with no peek at the next one (viewportFraction
            // is the 1.0 default), so every banner must get the same — zero —
            // padding. A trailing inset here doesn't open a gap between pages;
            // it just shrinks that one banner's card, which is why the last
            // banner used to look bigger than the other two.
            itemBuilder: (context, index) =>
                _BannerCard(banner: widget.banners[index]),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index
                      ? scheme.primary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(banner.image, fit: BoxFit.cover),
          if (banner.hasOverlay)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              // Keep copy clear of the artwork on the right.
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      banner.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner.action,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

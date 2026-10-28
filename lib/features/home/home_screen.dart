import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_service.dart';
import '../../core/push/push_service.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/header_skin.dart';
import '../../core/weather/weather_service.dart';
import '../../shared/widgets/fade_slide_in.dart';
import '../../shared/widgets/promo_carousel.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/stat_tile.dart';
import '../bookings/bookings_provider.dart';
import '../bookings/jobs_screen.dart';
import '../auth/auth_controller.dart';

const _banners = [
  // All three already have their copy and button drawn into the artwork.
  PromoBanner.prebaked(image: 'assets/images/banner_earnings.png'),
  PromoBanner.prebaked(image: 'assets/images/banner_referral.png'),
  PromoBanner.prebaked(image: 'assets/images/banner_training.png'),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final skin = ref.watch(headerSkinProvider);

    return Scaffold(
      // The header paints its own status bar area, so it can run the festive
      // gradient right to the top edge instead of stopping at a white strip.
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                name: user?.fullName ?? 'Partner',
                image: user?.profileImage,
                badge: ref.watch(badgeCountProvider),
                skin: skin,
                topInset: MediaQuery.paddingOf(context).top,
                onNotifications: () =>
                    ref.read(badgeCountProvider.notifier).clear(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  const FadeSlideIn(child: PromoCarousel(banners: _banners)),
                  const SizedBox(height: AppSpacing.lg),
                  const FadeSlideIn(index: 1, child: _HomeStats()),
                  const SizedBox(height: AppSpacing.lg),
                  FadeSlideIn(
                    index: 2,
                    child: SectionHeader(
                      title: 'Active jobs',
                      actionLabel: 'See all',
                      onAction: () => context.go(Routes.jobs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _ActiveJobs(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned header with the partner's area, avatar and a search field.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.name,
    required this.badge,
    required this.onNotifications,
    required this.topInset,
    this.image,
    this.skin,
  });

  final String name;
  final int badge;
  final VoidCallback onNotifications;
  final String? image;
  final HeaderSkin? skin;

  /// Status bar height, which the header covers itself.
  final double topInset;

  /// Tracks the content: 16 padding + 56 avatar row + 12 + ~28 location and
  /// weather row + 12 + 50 search field + 18 padding. Going much taller
  /// leaves a dead band under the search field, since the column packs to the
  /// top of a fixed extent.
  static const double _contentHeight = 202;

  double get _height => _contentHeight + topInset;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasImage = image != null && image!.isNotEmpty;
    // A skin repaints the header; without one it stays on the plain surface.
    final onHeader = skin?.onSkin ?? scheme.onSurface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark status bar icons on the plain header, light ones once a gradient
      // is running behind them.
      value: skin == null
          ? SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Container(
        decoration: BoxDecoration(
          color: skin == null ? scheme.surface : null,
          gradient: skin == null
              ? null
              : LinearGradient(
                  colors: skin!.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: Stack(
          children: [
            if (skin?.starfield ?? false)
              Positioned.fill(child: Starfield(color: onHeader)),
            if (skin?.celestial == Celestial.sun)
              const Positioned.fill(child: DaySky()),
            if (skin != null && skin!.celestial != Celestial.none)
              Positioned(
                top: topInset - 6,
                right: -10,
                child: skin!.celestial == Celestial.moon
                    ? const CrescentMoon(size: 104)
                    : const SunArt(size: 112),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.lg + topInset,
                AppSpacing.page,
                AppSpacing.lg,
              ),
              child: Column(
                // Without this, the location row (which shrink-wraps its
                // content) centers itself instead of hugging the left margin.
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: skin == null
                            ? scheme.primaryContainer
                            : Colors.white.withValues(alpha: 0.18),
                        foregroundImage: hasImage ? NetworkImage(image!) : null,
                        child: Text(
                          _initials(name),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: skin == null
                                ? scheme.onPrimaryContainer
                                : onHeader,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${greetingAt(DateTime.now()).toUpperCase()}'
                              ' · ${shortDate(DateTime.now())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: onHeader.withValues(alpha: 0.75),
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: onHeader,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _HeaderAction(
                        icon: Icons.notifications_none_rounded,
                        tint: onHeader,
                        filled: skin != null,
                        badge: badge,
                        tooltip: badge > 0
                            ? '$badge new notifications'
                            : 'Notifications',
                        onPressed: onNotifications,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _HeaderAction(
                        icon: Icons.settings_outlined,
                        tint: onHeader,
                        filled: skin != null,
                        tooltip: 'Settings',
                        onPressed: () => context.push(Routes.settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Flexible(child: _LocationLabel(tint: skin?.onSkin)),
                      const SizedBox(width: AppSpacing.sm),
                      _WeatherChip(tint: skin?.onSkin),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SearchField(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (value.trim().isEmpty) return 'P';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.name != name ||
      old.image != image ||
      old.badge != badge ||
      old.topInset != topInset ||
      old.skin?.gradient.first != skin?.gradient.first ||
      old.skin?.starfield != skin?.starfield ||
      old.skin?.celestial != skin?.celestial;
}

/// A round header button. On a dressed header it gets a translucent disc so
/// it stays legible over the gradient and the stars.
class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tint,
    required this.filled,
    required this.tooltip,
    required this.onPressed,
    this.badge = 0,
  });

  final IconData icon;
  final Color tint;
  final bool filled;
  final String tooltip;
  final VoidCallback onPressed;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: filled
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 42,
            width: 42,
            child: Center(
              child: Badge.count(
                count: badge,
                isLabelVisible: badge > 0,
                child: Icon(icon, size: 21, color: tint),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The reverse-geocoded "City, State" next to a pin; tap to retry after a
/// denied permission or a cold GPS fix. This is the header's headline row,
/// Blinkit-style — the pin sits with the location, not with the partner's
/// name.
class _LocationLabel extends ConsumerWidget {
  const _LocationLabel({this.tint});

  /// Set on festive days, when the header runs a gradient the usual primary
  /// blue would disappear into.
  final Color? tint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = tint ?? scheme.primary;
    final location = ref.watch(locationLabelProvider);

    final label = location.when(
      data: (value) => value ?? 'Set your location',
      loading: () => 'Locating...',
      error: (_, _) => 'Set your location',
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.field),
      onTap: () => ref.invalidate(locationLabelProvider),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_rounded, size: 19, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }
}

/// Live conditions for the partner's location — sun, rain, snow, storm or
/// night, each with its own icon and tint. Renders nothing while loading or
/// if the fix/forecast failed: a stale or spinner-y badge is worse than none.
class _WeatherChip extends ConsumerWidget {
  const _WeatherChip({this.tint});

  /// On a festive gradient the condition colours lose contrast, so the
  /// header hands down its own readable colour instead.
  final Color? tint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weather = ref.watch(weatherProvider).value;
    if (weather == null) return const SizedBox.shrink();

    final accent = tint ?? weather.accent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: tint == null ? 0.10 : 0.22),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(weather.icon, size: 14, color: accent),
          const SizedBox(width: 4),
          Text(
            weather.tempLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            weather.label,
            style: theme.textTheme.labelSmall?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Search jobs, customers, areas',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Container(width: 1, height: 20, color: scheme.outlineVariant),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.tune_rounded, size: 18, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Two job-count cards side by side, straight off the requests endpoint.
class _HomeStats extends ConsumerWidget {
  const _HomeStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(bookingFeedProvider).value;

    return Row(
      children: [
        Expanded(
          child: StatTile(
            value: feed?.upcomingCount.toString() ?? '--',
            label: 'Open jobs',
            icon: Icons.bolt_rounded,
            accent: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatTile(
            value: feed?.completedCount.toString() ?? '--',
            label: 'Completed',
            icon: Icons.check_circle_outline_rounded,
            accent: AppColors.success,
          ),
        ),
      ],
    );
  }
}

/// The newest open requests, or a short note while they load.
class _ActiveJobs extends ConsumerWidget {
  const _ActiveJobs();

  static const _maxRows = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(bookingFeedProvider);

    return feed.when(
      loading: () => const _JobsNote(child: CircularProgressIndicator()),
      error: (_, _) =>
          const _JobsNote(child: Text('Could not load your jobs.')),
      data: (value) {
        final bookings = value.bookings.take(_maxRows).toList();
        if (bookings.isEmpty) {
          return const _JobsNote(child: Text('No open requests right now.'));
        }

        return Column(
          children: [
            for (var i = 0; i < bookings.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm),
              FadeSlideIn(
                index: i + 3,
                key: ValueKey(bookings[i].id),
                child: BookingRow(booking: bookings[i]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _JobsNote extends StatelessWidget {
  const _JobsNote({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 72,
      child: Center(
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall ?? const TextStyle(),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/location/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../shared/widgets/fade_slide_in.dart';

/// Blocks the app until location is on and granted. Partners are matched to
/// jobs by where they are, so this is a wall rather than a dismissible nudge.
///
/// Re-checks on resume: the fix for every state here happens in the system
/// settings, so coming back is the moment to look again.
class LocationRequiredScreen extends ConsumerStatefulWidget {
  const LocationRequiredScreen({super.key});

  @override
  ConsumerState<LocationRequiredScreen> createState() =>
      _LocationRequiredScreenState();
}

class _LocationRequiredScreenState extends ConsumerState<LocationRequiredScreen>
    with WidgetsBindingObserver {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationGateProvider.notifier).refresh();
    }
  }

  Future<void> _act(LocationAccess access) async {
    setState(() => _busy = true);
    final gate = ref.read(locationGateProvider.notifier);
    // A plain "denied" can still be undone by the OS prompt; the other two
    // need the settings app.
    if (access == LocationAccess.denied) {
      await gate.request();
    } else {
      await gate.openSettings();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final access = ref.watch(locationGateProvider);

    final (title, message, action) = switch (access) {
      LocationAccess.serviceDisabled => (
        'Turn on location',
        'Location is switched off on this device. Switch it on to start '
            'receiving jobs around you.',
        'Open location settings',
      ),
      LocationAccess.deniedForever => (
        'Location is blocked',
        'Location permission is turned off for SevaHub Partner. Open '
            'settings and allow location to continue.',
        'Open app settings',
      ),
      _ => (
        'Allow location access',
        'We use your location to send you jobs nearby and to guide you to '
            'each customer.',
        'Allow location',
      ),
    };

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.lg,
              AppSpacing.page,
              AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              // IntrinsicHeight gives the Column a real height to divide, so
              // the spacers below work inside a scroll view instead of
              // throwing on unbounded constraints.
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    const FadeSlideIn(child: _LocationArt()),
                    const SizedBox(height: AppSpacing.xl),
                    FadeSlideIn(
                      index: 1,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(
                      index: 2,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const FadeSlideIn(index: 3, child: _Reasons()),
                    const Spacer(),
                    const SizedBox(height: AppSpacing.xl),
                    FadeSlideIn(
                      index: 4,
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _busy ? null : () => _act(access),
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(action),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FadeSlideIn(
                      index: 5,
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => ref
                                  .read(locationGateProvider.notifier)
                                  .refresh(),
                        child: const Text('I have already allowed it'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FadeSlideIn(
                      index: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Used only while you are working. Never shared.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The illustration with a radar pulse behind it, so the screen reads as
/// "searching for you" rather than as an error page.
class _LocationArt extends StatefulWidget {
  const _LocationArt();

  @override
  State<_LocationArt> createState() => _LocationArtState();
}

class _LocationArtState extends State<_LocationArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: const Size.square(230),
              painter: _PulsePainter(_controller.value),
            ),
          ),
          SvgPicture.asset(
            'assets/images/location_illustration.svg',
            height: 190,
          ),
        ],
      ),
    );
  }
}

/// Two rings expanding out of the centre, staggered half a cycle apart.
class _PulsePainter extends CustomPainter {
  const _PulsePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (var i = 0; i < 2; i++) {
      final t = (progress + i * 0.5) % 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        // Fades as it travels out, so the ring dissolves at the edge.
        ..color = AppColors.brand.withValues(alpha: (1 - t) * 0.35);
      canvas.drawCircle(centre, maxRadius * (0.45 + t * 0.55), paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}

/// Why the permission is worth granting, in the partner's own terms.
class _Reasons extends StatelessWidget {
  const _Reasons();

  static const _items = [
    (Icons.near_me_rounded, 'Jobs near you', 'Only work in your area'),
    (Icons.route_rounded, 'Clear directions', 'Reach every customer faster'),
    (Icons.verified_rounded, 'Fair matching', 'Be first in line close by'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        for (final (icon, title, subtitle) in _items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'fade_slide_in.dart';

/// Shown when a partner takes a job: a burst of confetti behind a short line
/// of praise.
Future<void> showCelebrationDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) =>
        _CelebrationDialog(title: title, message: message),
  );
}

/// Rotates so the same line does not come up twice in a row.
class Praise {
  const Praise._();

  static final _random = math.Random();
  static String? _last;

  static const lines = [
    'You did a great job!',
    'Shabash! Another one taken.',
    'Great work, partner.',
    'Well done — the customer is counting on you.',
    'Nice pickup! Keep it going.',
    'You are on a roll today.',
  ];

  static String next() {
    if (lines.length < 2) return lines.first;
    String line;
    do {
      line = lines[_random.nextInt(lines.length)];
    } while (line == _last);
    _last = line;
    return line;
  }
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xxl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sheet),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PopIn(
                  child: Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 38,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  index: 1,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FadeSlideIn(
                  index: 2,
                  child: Text(
                    Praise.next(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FadeSlideIn(
                  index: 3,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  index: 4,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Let\'s go'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Drawn over the card, but never in the way of the button.
          const Positioned.fill(child: IgnorePointer(child: ParticleBurst())),
        ],
      ),
    );
  }
}

/// A one-shot confetti burst from the top-centre of its box.
class ParticleBurst extends StatefulWidget {
  const ParticleBurst({this.count = 44, super.key});

  final int count;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  late final List<_Particle> _particles = _build(widget.count);

  static const _palette = [
    AppColors.brand,
    AppColors.accent,
    AppColors.success,
    AppColors.brandLight,
    Color(0xFFE94F8A),
  ];

  List<_Particle> _build(int count) {
    final random = math.Random();
    return [
      for (var i = 0; i < count; i++)
        _Particle(
          // Fan out across the full circle, biased upward.
          angle: -math.pi / 2 + (random.nextDouble() - 0.5) * math.pi * 1.6,
          speed: 90 + random.nextDouble() * 190,
          size: 5 + random.nextDouble() * 7,
          spin: (random.nextDouble() - 0.5) * 10,
          delay: random.nextDouble() * 0.18,
          color: _palette[random.nextInt(_palette.length)],
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _ParticlePainter(
          particles: _particles,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.delay,
    required this.color,
  });

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final double delay;
  final Color color;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({required this.particles, required this.progress});

  final List<_Particle> particles;
  final double progress;

  static const _gravity = 340.0;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.28);
    final paint = Paint();

    for (final particle in particles) {
      final t = ((progress - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      if (t == 0) continue;

      final dx = math.cos(particle.angle) * particle.speed * t;
      final dy =
          math.sin(particle.angle) * particle.speed * t + _gravity * t * t;
      // Hold full opacity for the first half, then fade out.
      final opacity = (1 - ((t - 0.5) / 0.5).clamp(0.0, 1.0));

      paint.color = particle.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(particle.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(1.5),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

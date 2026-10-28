import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../weather/weather_service.dart';
import 'festival_theme.dart';

/// How the home header dresses itself: a gradient plus the colour its text
/// and icons need to stay readable on top of it. A festival supplies one,
/// and otherwise the current sky does — night goes dark with a moon and
/// stars, rain goes slate, a clear day stays bright.
@immutable
class HeaderSkin {
  const HeaderSkin({
    required this.gradient,
    required this.onSkin,
    this.starfield = false,
    this.celestial = Celestial.none,
  });

  final List<Color> gradient;

  /// Text/icon colour with enough contrast against [gradient].
  final Color onSkin;

  /// Scatters stars behind the content, for the night sky.
  final bool starfield;

  /// What hangs in the corner behind the content.
  final Celestial celestial;
}

/// The body drawn in the header's top corner.
enum Celestial { none, sun, moon }

HeaderSkin skinForFestival(Festival festival) =>
    HeaderSkin(gradient: festival.gradient, onSkin: festival.onFestive);

/// Decides what the header wears, given the date, the sky and the clock.
///
/// A festival owns the header by day. After dark the night sky takes the
/// backdrop instead, since a bright festival gradient under a moon reads
/// wrong.
HeaderSkin? resolveHeaderSkin({
  Festival? festival,
  WeatherSnapshot? weather,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final sky = skinForWeather(weather, now: at);
  final festive = festival == null ? null : skinForFestival(festival);

  if (festive == null) return sky;
  if (sky == null || skyBandAt(at) != SkyBand.night) return festive;

  return sky;
}

/// What the home header is wearing right now. A provider so tests can pin
/// it — the daytime clouds animate forever, which nothing can settle on.
final headerSkinProvider = Provider<HeaderSkin?>(
  (ref) => resolveHeaderSkin(
    festival: ref.watch(festivalProvider),
    weather: ref.watch(weatherProvider).value,
  ),
);

/// Which part of the day the header dresses for. Driven by the clock rather
/// than the forecast's `is_day`, so the look turns over at the hours people
/// actually expect.
enum SkyBand {
  /// 05:00–16:00.
  day,

  /// 16:00–18:00, the low golden sun.
  evening,

  /// 18:00–05:00.
  night,
}

/// "Good evening", by the same clock the sky uses.
String greetingAt(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// "FRI, 02 OCT" — short enough to sit beside the greeting.
String shortDate(DateTime time) {
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  final day = time.day.toString().padLeft(2, '0');
  return '${days[time.weekday - 1]}, $day ${months[time.month - 1]}';
}

SkyBand skyBandAt(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 16) return SkyBand.day;
  if (hour >= 16 && hour < 18) return SkyBand.evening;
  return SkyBand.night;
}

/// Null when the sky should not tint the header — a plain bright day with
/// nothing notable in it, or no reading yet.
HeaderSkin? skinForWeather(WeatherSnapshot? weather, {DateTime? now}) {
  const white = Colors.white;
  final band = skyBandAt(now ?? DateTime.now());

  // Night owns the header whatever the forecast says: a dark sky reads
  // wrong in daylight and vice versa.
  if (band == SkyBand.night) {
    return HeaderSkin(
      gradient: const [Color(0xFF0B1437), Color(0xFF1B2A6B)],
      onSkin: white,
      starfield: true,
      celestial: Celestial.moon,
    );
  }

  // No reading yet: the hour alone still tells us whether it is day or dusk.
  return switch (weather?.code ?? -1) {
    // Drizzle, rain and showers.
    51 ||
    53 ||
    55 ||
    56 ||
    57 ||
    61 ||
    63 ||
    65 ||
    66 ||
    67 ||
    80 ||
    81 ||
    82 => HeaderSkin(
      gradient: const [Color(0xFF2B5876), Color(0xFF4E7C9E)],
      onSkin: white,
    ),
    // Thunderstorms.
    95 || 96 || 99 => HeaderSkin(
      gradient: const [Color(0xFF2C2A4A), Color(0xFF4A3F7A)],
      onSkin: white,
    ),
    // Snow.
    71 || 73 || 75 || 77 || 85 || 86 => HeaderSkin(
      gradient: const [Color(0xFF5C87B5), Color(0xFF8FB8DE)],
      onSkin: white,
    ),
    // Overcast and fog, in daylight.
    3 || 45 || 48 => HeaderSkin(
      gradient: const [Color(0xFF6B8CAE), Color(0xFF9DB4C8)],
      onSkin: white,
    ),
    // Nothing notable in the sky, so the hour decides.
    _ => switch (band) {
      SkyBand.evening => HeaderSkin(
        // The low golden sun.
        gradient: const [Color(0xFFE8803A), Color(0xFFF2B263)],
        onSkin: white,
        celestial: Celestial.sun,
      ),
      SkyBand.day => HeaderSkin(
        gradient: const [Color(0xFF0E4FA1), Color(0xFF3C8DD9)],
        onSkin: white,
        celestial: Celestial.sun,
      ),
      // Unreachable: night returned above.
      SkyBand.night => null,
    },
  };
}

/// Fixed scatter of stars, so the sky does not reshuffle on every rebuild.
class Starfield extends StatelessWidget {
  const Starfield({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _StarfieldPainter(color), size: Size.infinite);
}

/// Clouds drifting across the daytime header, with a few birds riding along.
/// Slow on purpose: this sits behind the greeting and the search field, so it
/// should register as movement, not as something to watch.
class DaySky extends StatefulWidget {
  const DaySky({super.key, this.birdColor = const Color(0xFF14356B)});

  final Color birdColor;

  @override
  State<DaySky> createState() => _DaySkyState();
}

class _DaySkyState extends State<DaySky> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 48),
  )..repeat();

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
        size: Size.infinite,
        painter: _DaySkyPainter(_controller.value, widget.birdColor),
      ),
    );
  }
}

class _DaySkyPainter extends CustomPainter {
  const _DaySkyPainter(this.progress, this.birdColor);

  final double progress;
  final Color birdColor;

  /// (relative y, scale, opacity, speed) — nearer clouds are bigger, more
  /// opaque and move faster, which reads as depth.
  static const _clouds = [
    (0.26, 1.00, 0.30, 1.00),
    (0.58, 0.72, 0.22, 0.72),
    (0.82, 0.86, 0.16, 1.28),
  ];

  static const _birds = [(0.30, 0.55), (0.38, 0.72), (0.24, 0.90)];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (y, scale, opacity, speed) in _clouds) {
      // Wrap a cloud's width past each edge so it never pops in or out.
      final span = size.width + 180;
      final x = ((progress * speed * span) % span) - 120;
      _cloud(
        canvas,
        Offset(x, size.height * y),
        34 * scale,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }

    final birdPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = birdColor.withValues(alpha: 0.55);

    for (final (y, speed) in _birds) {
      final span = size.width + 120;
      final x = ((progress * speed * span) % span) - 60;
      _bird(canvas, Offset(x, size.height * y), 7, birdPaint);
    }
  }

  void _cloud(Canvas canvas, Offset at, double r, Paint paint) {
    canvas.drawCircle(at, r * 0.62, paint);
    canvas.drawCircle(at.translate(r * 0.62, r * 0.12), r * 0.46, paint);
    canvas.drawCircle(at.translate(-r * 0.60, r * 0.16), r * 0.40, paint);
    canvas.drawOval(
      Rect.fromCenter(
        center: at.translate(0, r * 0.38),
        width: r * 2.3,
        height: r * 0.72,
      ),
      paint,
    );
  }

  /// A plain "V", the way a distant bird actually reads at this size.
  void _bird(Canvas canvas, Offset at, double w, Paint paint) {
    final path = Path()
      ..moveTo(at.dx - w, at.dy)
      ..quadraticBezierTo(at.dx - w * 0.5, at.dy - w * 0.6, at.dx, at.dy)
      ..quadraticBezierTo(at.dx + w * 0.5, at.dy - w * 0.6, at.dx + w, at.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DaySkyPainter old) => old.progress != progress;
}

/// The sun that hangs in the corner of the daytime header.
class SunArt extends StatelessWidget {
  const SunArt({super.key, this.size = 104});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _SunPainter());
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centre = Offset(r, r);

    // Two soft halos, so the sun sits in the sky rather than on top of it.
    canvas.drawCircle(
      centre,
      r * 0.95,
      Paint()
        ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
    canvas.drawCircle(
      centre,
      r * 0.70,
      Paint()
        ..color = const Color(0xFFFFE9A3).withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      centre,
      r * 0.46,
      Paint()..color = const Color(0xFFFFF0B0),
    );
  }

  @override
  bool shouldRepaint(_SunPainter oldDelegate) => false;
}

/// The crescent that hangs in the corner of the night header.
class CrescentMoon extends StatelessWidget {
  const CrescentMoon({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MoonPainter());
}

class _MoonPainter extends CustomPainter {
  /// Carved rather than drawn: a filled disc with a second disc punched out
  /// of it, which gives a true crescent at any size.
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centre = Offset(r, r);

    final glow = Paint()
      ..color = const Color(0xFFFFF2B8).withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(centre, r * 0.95, glow);

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(
      centre,
      r * 0.78,
      Paint()..color = const Color(0xFFF7E8A4),
    );
    canvas.drawCircle(
      Offset(r * 1.42, r * 0.66),
      r * 0.70,
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoonPainter oldDelegate) => false;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // A fixed seed keeps the same sky between frames.
    final random = Random(7);
    for (var i = 0; i < 44; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = 0.8 + random.nextDouble() * 1.6;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.3 + random.nextDouble() * 0.6);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.color != color;
}

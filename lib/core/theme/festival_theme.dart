import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A festive dress-up for the home header: its gradient and the colour that
/// stays readable on top.
@immutable
class Festival {
  const Festival({
    required this.name,
    required this.from,
    required this.to,
    required this.gradient,
    required this.onFestive,
    this.year,
  });

  final String name;

  /// Inclusive (month, day) window. With [year] null the window repeats every
  /// year, which only holds for fixed-date festivals — a lunar one has to
  /// name its year.
  final (int, int) from;
  final (int, int) to;
  final int? year;

  final List<Color> gradient;

  /// Text and icon colour that stays readable on [gradient].
  final Color onFestive;

  bool covers(DateTime day) {
    if (year != null && year != day.year) return false;

    final start = DateTime(day.year, from.$1, from.$2);
    var end = DateTime(day.year, to.$1, to.$2, 23, 59, 59);
    // A window like Dec 30 -> Jan 2 wraps past new year.
    if (end.isBefore(start)) {
      return !day.isBefore(start) || !day.isAfter(end);
    }
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

/// Fixed-date festivals, so these windows stay correct every year.
///
/// Lunar festivals (Diwali, Holi, Karwa Chauth, Eid, Navratri…) move every
/// year and must be added with an explicit [Festival.year], or the header
/// would celebrate on the wrong day.
const festivals = <Festival>[
  Festival(
    name: 'New Year',
    from: (12, 31),
    to: (1, 1),
    gradient: [Color(0xFF1A237E), Color(0xFF512DA8)],
    onFestive: Colors.white,
  ),
  Festival(
    name: 'Republic Day',
    from: (1, 26),
    to: (1, 26),
    gradient: [Color(0xFFFF9933), Color(0xFF138808)],
    onFestive: Colors.white,
  ),
  Festival(
    name: 'Independence Day',
    from: (8, 15),
    to: (8, 15),
    gradient: [Color(0xFFFF9933), Color(0xFF138808)],
    onFestive: Colors.white,
  ),
  Festival(
    name: 'Gandhi Jayanti',
    from: (10, 2),
    to: (10, 2),
    gradient: [Color(0xFF37474F), Color(0xFF00695C)],
    onFestive: Colors.white,
  ),
  Festival(
    name: 'Christmas',
    from: (12, 24),
    to: (12, 25),
    gradient: [Color(0xFFB71C1C), Color(0xFF1B5E20)],
    onFestive: Colors.white,
  ),
];

Festival? festivalFor(DateTime day) {
  for (final festival in festivals) {
    if (festival.covers(day)) return festival;
  }
  return null;
}

/// The festival the header should dress up for, or null on an ordinary day.
final festivalProvider = Provider<Festival?>(
  (ref) => festivalFor(DateTime.now()),
);

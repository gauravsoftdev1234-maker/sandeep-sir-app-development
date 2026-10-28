import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/core/theme/festival_theme.dart';

void main() {
  group('festivalFor', () {
    test('returns null on an ordinary day', () {
      expect(festivalFor(DateTime(2026, 9, 21)), isNull);
    });

    test('matches a single-day festival', () {
      expect(festivalFor(DateTime(2026, 8, 15))?.name, 'Independence Day');
      expect(festivalFor(DateTime(2026, 1, 26))?.name, 'Republic Day');
    });

    test('matches every year, since these dates are fixed', () {
      for (final year in [2026, 2027, 2030]) {
        expect(festivalFor(DateTime(year, 12, 25))?.name, 'Christmas');
      }
    });

    test('a window that wraps past new year covers both sides', () {
      expect(festivalFor(DateTime(2026, 12, 31))?.name, 'New Year');
      expect(festivalFor(DateTime(2027, 1, 1))?.name, 'New Year');
      // ...but not the days around it.
      expect(festivalFor(DateTime(2026, 12, 29)), isNull);
      expect(festivalFor(DateTime(2027, 1, 2)), isNull);
    });

    test('a festival pinned to a year does not fire in other years', () {
      const diwali2026 = Festival(
        name: 'Diwali',
        from: (11, 8),
        to: (11, 8),
        year: 2026,
        gradient: [],
        onFestive: Color(0xFFFFFFFF),
      );

      expect(diwali2026.covers(DateTime(2026, 11, 8)), isTrue);
      expect(diwali2026.covers(DateTime(2027, 11, 8)), isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/core/theme/festival_theme.dart';
import 'package:partner_app/core/theme/header_skin.dart';
import 'package:partner_app/core/weather/weather_service.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 10, 2, hour, 30);

  group('skyBandAt', () {
    test('05:00 to 16:00 is day', () {
      expect(skyBandAt(DateTime(2026, 10, 2, 5)), SkyBand.day);
      expect(skyBandAt(at(11)), SkyBand.day);
      expect(skyBandAt(DateTime(2026, 10, 2, 15, 59)), SkyBand.day);
    });

    test('16:00 to 18:00 is the evening sun', () {
      expect(skyBandAt(DateTime(2026, 10, 2, 16)), SkyBand.evening);
      expect(skyBandAt(DateTime(2026, 10, 2, 17, 59)), SkyBand.evening);
    });

    test('18:00 to 05:00 is night, across midnight', () {
      expect(skyBandAt(DateTime(2026, 10, 2, 18)), SkyBand.night);
      expect(skyBandAt(at(23)), SkyBand.night);
      expect(skyBandAt(DateTime(2026, 10, 2, 0, 5)), SkyBand.night);
      expect(skyBandAt(DateTime(2026, 10, 2, 4, 59)), SkyBand.night);
    });
  });

  group('skinForWeather', () {
    const clear = WeatherSnapshot(tempC: 26, code: 0, isDay: true);
    const rain = WeatherSnapshot(tempC: 22, code: 63, isDay: true);

    test('the clock dresses the header before any forecast arrives', () {
      // Weather can take a few seconds; the hour alone already tells us
      // whether to show a blue sky or a night sky.
      final day = skinForWeather(null, now: at(11))!;
      expect(day.celestial, Celestial.sun);
      expect(day.gradient.first.toARGB32(), 0xFF0E4FA1);

      final night = skinForWeather(null, now: at(22))!;
      expect(night.celestial, Celestial.moon);
      expect(night.starfield, isTrue);
    });

    test('daytime hangs a sun, night a moon', () {
      expect(skinForWeather(clear, now: at(9))!.celestial, Celestial.sun);
      expect(skinForWeather(clear, now: at(17))!.celestial, Celestial.sun);
      expect(skinForWeather(clear, now: at(2))!.celestial, Celestial.moon);
    });

    test('rain hides the sun rather than drawing one in a grey sky', () {
      expect(skinForWeather(rain, now: at(11))!.celestial, Celestial.none);
    });

    test('night brings the dark sky and stars, whatever the API said', () {
      // `isDay: true` on purpose: the clock wins, not the forecast flag.
      final skin = skinForWeather(clear, now: at(22))!;
      expect(skin.starfield, isTrue);
      expect(skin.gradient.first.toARGB32(), 0xFF0B1437);
    });

    test('a clear afternoon is the blue sky', () {
      final skin = skinForWeather(clear, now: at(11))!;
      expect(skin.starfield, isFalse);
      expect(skin.gradient.first.toARGB32(), 0xFF0E4FA1);
    });

    test('late afternoon turns golden', () {
      final skin = skinForWeather(clear, now: at(17))!;
      expect(skin.gradient.first.toARGB32(), 0xFFE8803A);
    });

    test('rain overrides the hour during the day', () {
      final skin = skinForWeather(rain, now: at(11))!;
      expect(skin.gradient.first.toARGB32(), 0xFF2B5876);
    });

    test('a festival owns the header by day', () {
      final skin = resolveHeaderSkin(
        festival: festivalFor(DateTime(2026, 10, 2))!,
        weather: clear,
        now: at(11),
      )!;
      // The festival's own teal, not the daytime blue sky.
      expect(skin.gradient.first.toARGB32(), 0xFF37474F);
      expect(skin.starfield, isFalse);
    });

    test('after dark the night sky takes over from the festival', () {
      final skin = resolveHeaderSkin(
        festival: festivalFor(DateTime(2026, 10, 2))!,
        weather: clear,
        now: at(22),
      )!;
      expect(skin.starfield, isTrue);
      expect(skin.gradient.first.toARGB32(), 0xFF0B1437);
    });

    test('rain at night still reads as night', () {
      final skin = skinForWeather(rain, now: at(22))!;
      expect(skin.starfield, isTrue);
      expect(skin.gradient.first.toARGB32(), 0xFF0B1437);
    });
  });
}

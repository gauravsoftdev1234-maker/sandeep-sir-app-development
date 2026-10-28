import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../location/location_service.dart';

/// What the header's weather chip draws: the reading plus how it should
/// look, since a sunny noon and a clear night share a WMO code but not an
/// icon.
@immutable
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.tempC,
    required this.code,
    required this.isDay,
  });

  final double tempC;

  /// WMO weather code, as Open-Meteo reports it.
  final int code;
  final bool isDay;

  String get tempLabel => '${tempC.round()}°C';

  /// Short enough to sit next to the temperature without wrapping.
  String get label => switch (code) {
    0 => isDay ? 'Sunny' : 'Clear',
    1 || 2 => isDay ? 'Partly sunny' : 'Partly clear',
    3 => 'Cloudy',
    45 || 48 => 'Foggy',
    51 || 53 || 55 || 56 || 57 => 'Drizzle',
    61 || 63 || 65 || 66 || 67 => 'Rainy',
    80 || 81 || 82 => 'Showers',
    71 || 73 || 75 || 77 || 85 || 86 => 'Snow',
    95 || 96 || 99 => 'Storm',
    _ => isDay ? 'Clear' : 'Night',
  };

  /// https://open-meteo.com/en/docs — WMO codes collapsed to what a partner
  /// heading out on a job actually needs to see at a glance.
  IconData get icon => switch (code) {
    0 => isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
    1 || 2 => isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded,
    3 => Icons.cloud_rounded,
    45 || 48 => Icons.foggy,
    51 || 53 || 55 || 56 || 57 => Icons.grain_rounded,
    61 || 63 || 65 || 66 || 67 || 80 || 81 || 82 => Icons.water_drop_rounded,
    71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit_rounded,
    95 || 96 || 99 => Icons.thunderstorm_rounded,
    _ => isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
  };

  /// Tints the chip so the condition reads before the text does.
  Color get accent => switch (code) {
    0 || 1 || 2 =>
      isDay
          ? const Color(0xFFF5A623) // sun amber
          : const Color(0xFF5C6BC0), // night indigo
    3 || 45 || 48 => const Color(0xFF78909C), // overcast blue-grey
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
    82 => const Color(0xFF2E86DE), // rain blue
    71 || 73 || 75 || 77 || 85 || 86 => const Color(0xFF4FC3F7), // snow ice
    95 || 96 || 99 => const Color(0xFF7E57C2), // storm violet
    _ => isDay ? const Color(0xFFF5A623) : const Color(0xFF5C6BC0),
  };
}

/// Open-Meteo needs no API key, so there is nothing to configure — just the
/// coordinates the location service already reads.
class WeatherService {
  const WeatherService(this._client);

  final http.Client _client;

  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  Future<WeatherSnapshot?> current(DeviceLocation location) async {
    if (!location.isKnown) return null;

    try {
      final uri = Uri.parse(_endpoint).replace(
        queryParameters: {
          'latitude': '${location.latitude}',
          'longitude': '${location.longitude}',
          'current': 'temperature_2m,weather_code,is_day',
        },
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      final temp = current?['temperature_2m'];
      final code = current?['weather_code'];
      if (temp is! num || code is! num) return null;

      return WeatherSnapshot(
        tempC: temp.toDouble(),
        code: code.toInt(),
        // Missing `is_day` shouldn't blank the chip; daytime is the safer
        // assumption for a working partner.
        isDay: current?['is_day'] is num
            ? (current!['is_day'] as num) == 1
            : true,
      );
    } catch (error) {
      // No network, no fix, a slow response — the chip just doesn't show.
      debugPrint('Weather unavailable: $error');
      return null;
    }
  }
}

final weatherServiceProvider = Provider<WeatherService>(
  (ref) => WeatherService(http.Client()),
);

/// Refetches whenever the device location changes, so the chip tracks the
/// partner as they move rather than freezing on the first fix.
final weatherProvider = FutureProvider.autoDispose<WeatherSnapshot?>((
  ref,
) async {
  final location = await ref.watch(deviceLocationProvider.future);
  return ref.watch(weatherServiceProvider).current(location);
});

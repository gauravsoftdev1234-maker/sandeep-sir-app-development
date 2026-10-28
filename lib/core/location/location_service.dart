import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// A coordinate pair, or [unknown] when the device could not give one.
@immutable
class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  /// What the API receives when there is no fix: it treats 0,0 as "not set".
  static const unknown = DeviceLocation(latitude: 0, longitude: 0);

  final double latitude;
  final double longitude;

  bool get isKnown => latitude != 0 || longitude != 0;

  @override
  bool operator ==(Object other) =>
      other is DeviceLocation &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Why the app may or may not proceed. Location is a hard requirement here:
/// jobs are matched to where the partner actually is, so a denied permission
/// blocks the app rather than quietly degrading it.
enum LocationAccess {
  /// The first check has not come back yet.
  checking,
  ready,

  /// Location is switched off for the whole device.
  serviceDisabled,

  /// Refused, but the OS will still show a prompt.
  denied,

  /// Refused for good — only the app settings page can undo it.
  deniedForever,
}

/// Reads the device position for the fields the API asks for.
class LocationService {
  const LocationService();

  /// Checks without prompting, so the gate can tell "not asked yet" from
  /// "refused for good" and offer the right button.
  Future<LocationAccess> access() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceDisabled;
      }
      return switch (await Geolocator.checkPermission()) {
        LocationPermission.denied => LocationAccess.denied,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.ready,
      };
    } catch (error) {
      debugPrint('Location access check failed: $error');
      return LocationAccess.denied;
    }
  }

  /// Shows the OS prompt, then reports where that left things.
  Future<LocationAccess> requestPermission() async {
    try {
      await Geolocator.requestPermission();
    } catch (error) {
      debugPrint('Location permission request failed: $error');
    }
    return access();
  }

  static const _settings = LocationSettings(
    // Street-level is plenty for matching a partner to a job.
    accuracy: LocationAccuracy.medium,
    timeLimit: Duration(seconds: 12),
  );

  /// Never throws and never blocks the caller for long: a refused permission,
  /// a disabled GPS or a timeout all come back as [DeviceLocation.unknown] so
  /// sign-up still goes through.
  Future<DeviceLocation> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return DeviceLocation.unknown;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return DeviceLocation.unknown;
      }

      // Last known first, deliberately. A fresh fix can take the full time
      // limit indoors, on a cold GPS, or on an emulator holding a static
      // location that never re-reports — and the header would sit on
      // "Locating..." that whole time. A slightly stale fix is street-level
      // accurate, which is all this is used for.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return DeviceLocation(
          latitude: last.latitude,
          longitude: last.longitude,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (error) {
      debugPrint('Location unavailable: $error');
      return DeviceLocation.unknown;
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);

/// Guards the whole app: nothing past the splash renders until location is
/// switched on and granted. The screen re-runs [refresh] when the app comes
/// back from the system settings, so returning with it enabled lets the
/// partner straight through.
class LocationGate extends Notifier<LocationAccess> {
  @override
  LocationAccess build() {
    unawaited(refresh());
    return LocationAccess.checking;
  }

  Future<void> refresh() async {
    state = await ref.read(locationServiceProvider).access();
  }

  Future<void> request() async {
    state = await ref.read(locationServiceProvider).requestPermission();
  }

  /// Sends the partner to the right settings page for whatever is wrong.
  Future<void> openSettings() async {
    try {
      if (state == LocationAccess.serviceDisabled) {
        await Geolocator.openLocationSettings();
      } else {
        await Geolocator.openAppSettings();
      }
    } catch (error) {
      debugPrint('Could not open location settings: $error');
    }
  }
}

final locationGateProvider = NotifierProvider<LocationGate, LocationAccess>(
  LocationGate.new,
);

/// The raw fix, shared by anything that needs coordinates rather than a
/// place name — the weather chip, say. A single read backs every watcher.
final deviceLocationProvider = FutureProvider.autoDispose<DeviceLocation>(
  (ref) => ref.watch(locationServiceProvider).current(),
);

String? _firstNonEmpty(List<String?> candidates) {
  for (final value in candidates) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// "City, State" for the pin next to the dashboard search bar. `null` means
/// the device would not give a fix or a placemark; the header falls back to
/// a neutral label rather than showing that.
final locationLabelProvider = FutureProvider.autoDispose<String?>((ref) async {
  final location = await ref.watch(deviceLocationProvider.future);
  if (!location.isKnown) return null;

  try {
    final placemarks = await Geocoding().placemarkFromCoordinates(
      location.latitude,
      location.longitude,
    );
    if (placemarks.isEmpty) {
      debugPrint('Reverse geocoding returned no placemark');
      return null;
    }

    final place = placemarks.first;
    // Which fields the geocoder fills varies by region and by device — on
    // some, `locality` comes back empty while the sub-fields are populated.
    // Taking the first that has anything beats showing "Set your location"
    // next to a perfectly good fix.
    final town = _firstNonEmpty([
      place.locality,
      place.subLocality,
      place.subAdministrativeArea,
    ]);
    final region = _firstNonEmpty([place.administrativeArea, place.country]);

    final parts = [town, region].whereType<String>().toSet().toList();
    if (parts.isEmpty) {
      debugPrint('Reverse geocoding gave a placemark with no usable name');
      return null;
    }
    return parts.join(', ');
  } catch (error) {
    debugPrint('Reverse geocoding failed: $error');
    return null;
  }
});

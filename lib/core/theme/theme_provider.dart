import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shared_preferences_provider.dart';

/// Holds the selected [ThemeMode] and persists it across launches.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _prefsKey = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, mode.name);
  }

  Future<void> toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

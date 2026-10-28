import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/shared_preferences_provider.dart';
import 'auth_models.dart';

/// Persists the logged-in user so the app can resume a session on launch.
class SessionStore {
  const SessionStore(this._prefs);

  static const _key = 'auth_session';

  final SharedPreferences _prefs;

  AuthUser? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // Stored payload is from an older build; drop it and start clean.
      _prefs.remove(_key);
      return null;
    }
  }

  Future<void> write(AuthUser user) =>
      _prefs.setString(_key, jsonEncode(user.toJson()));

  Future<void> clear() => _prefs.remove(_key);
}

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SessionStore(ref.watch(sharedPreferencesProvider)),
);

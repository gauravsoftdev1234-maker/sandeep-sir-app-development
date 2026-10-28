import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'core/push/push_service.dart';
import 'features/auth/auth_models.dart';
import 'features/auth/session_store.dart';

/// Debug-only shortcut for previewing the signed-in screens without typing
/// credentials:
///
///   `flutter run --dart-define=DEV_SESSION=<appToken>`
///
/// The token is still validated against the API, so an invalid one lands back
/// on the login screen.
const _devSessionToken = String.fromEnvironment('DEV_SESSION');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (kDebugMode && _devSessionToken.isNotEmpty) {
    await SessionStore(prefs).write(
      AuthUser(id: 0, fullName: 'Dev Partner', appToken: _devSessionToken),
    );
  }

  // Built here rather than inside a ProviderScope so push callbacks, which
  // fire outside the widget tree, can reach the same providers.
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  // Not awaited: the Android 13 permission prompt would otherwise hold up
  // the first frame.
  unawaited(PushService.initialize(container));

  runApp(
    UncontrolledProviderScope(container: container, child: const PartnerApp()),
  );
}

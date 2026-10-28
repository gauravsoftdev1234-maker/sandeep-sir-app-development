import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner_app/core/providers/shared_preferences_provider.dart';
import 'package:partner_app/core/push/push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('starts at whatever is stored', () async {
    final container = await containerWith({badgeCountKey: 3});
    addTearDown(container.dispose);

    expect(container.read(badgeCountProvider), 3);
  });

  test('starts at zero on a fresh install', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    expect(container.read(badgeCountProvider), 0);
  });

  test('each notification increments, opening clears', () async {
    final container = await containerWith({});
    addTearDown(container.dispose);

    final badge = container.read(badgeCountProvider.notifier);
    await badge.increment();
    await badge.increment();

    expect(container.read(badgeCountProvider), 2);
    // Written through, so the background isolate and the UI agree.
    expect(container.read(sharedPreferencesProvider).getInt(badgeCountKey), 2);

    await badge.clear();

    expect(container.read(badgeCountProvider), 0);
  });
}

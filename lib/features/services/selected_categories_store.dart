import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/shared_preferences_provider.dart';

/// Remembers which categories a partner picked during onboarding.
///
/// The API has no "my categories" endpoint yet, so the ids are cached locally
/// per user id after a successful save and the dashboard reads them back.
class SelectedCategoriesStore {
  const SelectedCategoriesStore(this._prefs);

  static const _prefix = 'selected_categories_';

  final SharedPreferences _prefs;

  Set<int> read(int userId) {
    final raw = _prefs.getStringList('$_prefix$userId') ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> write(int userId, Set<int> ids) =>
      _prefs.setStringList('$_prefix$userId', ids.map((id) => '$id').toList());
}

final selectedCategoriesStoreProvider = Provider<SelectedCategoriesStore>(
  (ref) => SelectedCategoriesStore(ref.watch(sharedPreferencesProvider)),
);

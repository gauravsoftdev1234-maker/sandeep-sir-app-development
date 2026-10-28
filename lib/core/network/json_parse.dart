/// The API is inconsistent about booleans: `isValidToken` answers `true` for a
/// valid token but `0` for an invalid one, so every flag is read leniently.
bool asBool(Object? value) {
  return switch (value) {
    bool flag => flag,
    num number => number != 0,
    String text => text.toLowerCase() == 'true' || text == '1',
    _ => false,
  };
}

String asString(Object? value) => value is String ? value : '';

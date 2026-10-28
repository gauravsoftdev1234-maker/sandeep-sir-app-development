/// Spacing and radius scale. Screens use these instead of loose numbers so
/// rhythm stays consistent as the app grows.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;

  /// Standard horizontal page inset.
  static const double page = 16;
}

class AppRadius {
  const AppRadius._();

  static const double field = 14;
  static const double button = 14;
  static const double card = 20;
  static const double pill = 999;
  static const double sheet = 28;
}

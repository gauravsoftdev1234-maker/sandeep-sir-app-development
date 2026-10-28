import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the brand splash stays up on every launch. Tests override this
/// with [Duration.zero].
final splashMinimumDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1600),
);

/// True while the splash should be held on screen, so a fast session check
/// does not make the brand screen flicker past.
class SplashGate extends Notifier<bool> {
  @override
  bool build() {
    final minimum = ref.read(splashMinimumDurationProvider);
    if (minimum == Duration.zero) return false;

    Future<void>.delayed(minimum, () => state = false);
    return true;
  }
}

final splashGateProvider = NotifierProvider<SplashGate, bool>(SplashGate.new);

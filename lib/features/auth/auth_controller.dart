import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/push/push_service.dart';
import 'auth_api.dart';
import 'auth_models.dart';
import 'session_store.dart';

enum AuthStatus {
  /// A stored token is being validated; show a splash instead of routing.
  checking,
  unauthenticated,
  authenticated,
}

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.serviceSelected = false,
  });

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  final AuthStatus status;
  final AuthUser? user;
  final bool serviceSelected;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool? serviceSelected,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    serviceSelected: serviceSelected ?? this.serviceSelected,
  );
}

/// Owns the session: restores it on launch, and handles login, registration
/// and logout. Methods return `null` on success or a message to show.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final stored = ref.read(sessionStoreProvider).read();
    if (stored == null) return const AuthState.unauthenticated();

    // Trust the stored token just long enough to confirm it with the server.
    Future.microtask(_validateStoredToken);
    return AuthState(status: AuthStatus.checking, user: stored);
  }

  Future<String?> login({
    required String mobileNumber,
    required String password,
    String fcmToken = '',
  }) async {
    try {
      // The API wants the device's FCM token; fall back to whatever the
      // caller passed when messaging is unavailable.
      final token = fcmToken.isEmpty
          ? await ref.read(pushTokensProvider).read()
          : fcmToken;

      final result = await ref
          .read(authApiProvider)
          .login(
            mobileNumber: mobileNumber,
            password: password,
            fcmToken: token,
          );

      final user = result.data;
      if (!result.isSuccess || user == null || user.appToken.isEmpty) {
        return result.message.isEmpty ? 'Login failed.' : result.message;
      }

      await ref.read(sessionStoreProvider).write(user);
      state = AuthState(status: AuthStatus.authenticated, user: user);

      // The login response does not say whether onboarding is done, so ask.
      await _refreshServiceSelection(user.appToken);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> register({
    required String userName,
    required String mobileNumber,
    required String emailId,
    required String password,
    required String confirmPassword,
    double latitude = 0,
    double longitude = 0,
  }) async {
    try {
      final result = await ref
          .read(authApiProvider)
          .register(
            userName: userName,
            mobileNumber: mobileNumber,
            emailId: emailId,
            password: password,
            confirmPassword: confirmPassword,
            latitude: latitude,
            longitude: longitude,
          );

      if (!result.isSuccess) {
        return result.message.isEmpty ? 'Registration failed.' : result.message;
      }
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  /// Re-checks the stored token, e.g. after onboarding was completed
  /// elsewhere. Also refreshes `IsServiceSelected`.
  Future<void> refreshStatus() async {
    final token = state.user?.appToken;
    if (token == null || token.isEmpty) return;
    await _refreshServiceSelection(token);
  }

  Future<void> logout() async {
    await ref.read(sessionStoreProvider).clear();
    state = const AuthState.unauthenticated();
  }

  Future<void> _validateStoredToken() async {
    final token = state.user?.appToken;
    if (token == null || token.isEmpty) {
      await logout();
      return;
    }

    try {
      final status = await ref.read(authApiProvider).validateToken(token);
      if (!status.isValid) {
        await logout();
        return;
      }
      state = state.copyWith(
        status: AuthStatus.authenticated,
        serviceSelected: status.isServiceSelected,
      );
    } on ApiException {
      // Offline or server down: keep the stored session rather than signing
      // the user out, and let the next request surface the real error.
      state = state.copyWith(status: AuthStatus.authenticated);
    }
  }

  Future<void> _refreshServiceSelection(String token) async {
    try {
      final status = await ref.read(authApiProvider).validateToken(token);
      state = state.copyWith(serviceSelected: status.isServiceSelected);
    } on ApiException {
      // Not fatal; the user stays signed in with onboarding unresolved.
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

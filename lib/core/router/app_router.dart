import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../location/location_service.dart';
import '../providers/splash_gate.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/select_service_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/location/location_required_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/bookings/job_detail_screen.dart';
import '../../features/bookings/jobs_screen.dart';
import '../../shared/widgets/scaffold_with_nav_bar.dart';

/// All route paths in one place so screens never hardcode strings.
class Routes {
  const Routes._();

  static const splash = '/splash';
  static const locationRequired = '/location-required';
  static const login = '/login';
  static const register = '/register';
  static const selectService = '/select-service';

  static const home = '/';
  static const jobs = '/jobs';
  static const profile = '/profile';
  static const settings = '/settings';

  static String jobDetail(String id) => '/jobs/$id';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // go_router needs a Listenable to re-run `redirect` when auth changes.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.listen(splashGateProvider, (_, _) => refresh.value++);
  ref.listen(locationGateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final isAuthRoute =
          location == Routes.login || location == Routes.register;

      // Hold the brand splash for its minimum time on every launch.
      if (ref.read(splashGateProvider)) {
        return location == Routes.splash ? null : Routes.splash;
      }

      // Location is mandatory: without it nothing past the splash opens,
      // not even the login screen.
      switch (ref.read(locationGateProvider)) {
        case LocationAccess.checking:
          return location == Routes.splash ? null : Routes.splash;
        case LocationAccess.ready:
          // Granted after being blocked: fall through to the auth routing
          // below, which decides where they actually belong.
          if (location == Routes.locationRequired) return Routes.splash;
        case LocationAccess.serviceDisabled:
        case LocationAccess.denied:
        case LocationAccess.deniedForever:
          return location == Routes.locationRequired
              ? null
              : Routes.locationRequired;
      }

      switch (auth.status) {
        case AuthStatus.checking:
          return location == Routes.splash ? null : Routes.splash;

        case AuthStatus.unauthenticated:
          return isAuthRoute ? null : Routes.login;

        case AuthStatus.authenticated:
          if (!auth.serviceSelected) {
            return location == Routes.selectService
                ? null
                : Routes.selectService;
          }
          // Signed in and onboarded: keep them out of the entry screens.
          if (isAuthRoute ||
              location == Routes.splash ||
              location == Routes.selectService) {
            return Routes.home;
          }
          return null;
      }
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.locationRequired,
        builder: (context, state) => const LocationRequiredScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.selectService,
        builder: (context, state) => const SelectServiceScreen(),
      ),
      // Settings sits above the shell, so it covers the bottom nav bar.
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.jobs,
                builder: (context, state) => const JobsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        JobDetailScreen(bookingId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Wraps the branch routes so the bottom navigation bar stays put while the
/// body swaps between the top-level destinations.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.assignment_outlined),
      selectedIcon: Icon(Icons.assignment_rounded),
      label: 'Jobs',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // The entry screens ask for light status bar icons; restore the pairing
      // that matches the app's own background.
      value: scheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            destinations: _destinations,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              // Tapping the current tab again pops back to its root.
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Swaps a button label for a spinner while an action is in flight, keeping
/// the button's size stable.
class LoadingLabel extends StatelessWidget {
  const LoadingLabel({required this.busy, required this.label, super.key});

  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!busy) return Text(label);

    return SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}

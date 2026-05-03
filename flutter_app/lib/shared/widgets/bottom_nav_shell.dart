import 'package:flutter/material.dart';

/// Shell wrapper for ShellRoute — screens manage their own SalamaBottomNav,
/// so this is a transparent pass-through with no duplicate nav bar.
class BottomNavShell extends StatelessWidget {
  final Widget child;
  const BottomNavShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

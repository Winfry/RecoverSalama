import 'package:flutter/material.dart';

import '../../../core/constants/colors.dart';

/// Settings screen — language toggle, notifications, privacy, logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text('Settings — coming in Phase 2'),
      ),
    );
  }
}

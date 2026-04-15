import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/cache_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _language = 'en';
  bool _isLoggingOut = false;

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    if (value) {
      await NotificationService.scheduleDailyCheckInReminder();
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await CacheService.clear();
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      context.go(AppRoutes.landing);
    } catch (e) {
      setState(() => _isLoggingOut = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: AppColors.emergency,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // ── Notifications ──────────────────────────────────
          _sectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Daily Check-In Reminder'),
            subtitle: const Text('9 AM reminder to do your daily check-in'),
            value: _notificationsEnabled,
            activeColor: AppColors.primary,
            onChanged: _toggleNotifications,
          ),

          // ── Language ───────────────────────────────────────
          _sectionHeader('Language'),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: _language,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _language = v!),
          ),
          RadioListTile<String>(
            title: const Text('Kiswahili'),
            value: 'sw',
            groupValue: _language,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _language = v!),
          ),

          // ── Account ────────────────────────────────────────
          _sectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.emergency),
            title: const Text('Log Out',
                style: TextStyle(color: AppColors.emergency)),
            onTap: _isLoggingOut ? null : _logout,
            trailing: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.emergency),
                  )
                : null,
          ),

          // ── About ──────────────────────────────────────────
          _sectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.primary),
            title: Text('SalamaRecover'),
            subtitle: Text('Version 2.0.0 · AI-powered surgical recovery'),
          ),
          const ListTile(
            leading: Icon(Icons.phone, color: AppColors.primary),
            title: Text('Emergency'),
            subtitle: Text('999 · 0800 723 253 (Ambulance) · 020-2726300 (KNH)'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

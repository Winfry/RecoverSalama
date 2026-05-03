import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/cache_service.dart';
import '../../profile/providers/profile_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _language = 'English';
  bool _isLoggingOut = false;

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    if (value) {
      await NotificationService.scheduleDailyCheckInReminder();
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) launchUrl(uri);
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
    final profile = ref.watch(profileProvider);
    final name = profile.name.isNotEmpty ? profile.name : 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: const Text('Settings',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Profile card ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                              child: Text('👤',
                                  style: TextStyle(fontSize: 24))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              const Text('View profile',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textHint),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Preferences ──
                  _sectionLabel('Preferences'),
                  const SizedBox(height: 8),
                  _settingsCard([
                    _switchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Daily Reminder',
                      subtitle: '9:00 AM',
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                    ),
                    _divider(),
                    _navTile(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      value: _language,
                      onTap: () => _pickLanguage(),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Support ──
                  _sectionLabel('Support'),
                  const SizedBox(height: 8),
                  _settingsCard([
                    _navTile(
                      icon: Icons.phone_outlined,
                      title: 'Emergency Numbers',
                      value: '',
                      onTap: () {},
                    ),
                    _divider(),
                    _navTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About Pona Salama',
                      value: 'v1.0.0',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Account ──
                  _sectionLabel('Account'),
                  const SizedBox(height: 8),
                  _settingsCard([
                    ListTile(
                      leading: const Icon(Icons.logout_rounded,
                          color: AppColors.emergency, size: 20),
                      title: const Text('Log Out',
                          style: TextStyle(
                              color: AppColors.emergency,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      trailing: _isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.emergency))
                          : null,
                      onTap: _isLoggingOut ? null : _logout,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Emergency quick access ──
                  _sectionLabel('Emergency Quick Access'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _emergencyBtn('🚔', '999\nPolice', '999'),
                      const SizedBox(width: 8),
                      _emergencyBtn('🚑', 'Ambulance', '0800723253'),
                      const SizedBox(width: 8),
                      _emergencyBtn('🏥', 'KNH\n24/7', '0202726300'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text('Pona Salama · App Version 1.0.0',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 11)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textHint,
            letterSpacing: 1.2),
      );

  Widget _settingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Divider(
        height: 1, indent: 52, endIndent: 16,
        color: AppColors.divider,
      );

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) =>
      ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );

  Widget _navTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) =>
      ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.isNotEmpty)
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 18),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );

  Widget _emergencyBtn(String icon, String label, String number) =>
      Expanded(
        child: GestureDetector(
          onTap: () => _call(number),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ),
      );

  void _pickLanguage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Language',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['English', 'Kiswahili'].map((lang) => ListTile(
                  title: Text(lang),
                  trailing: _language == lang
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _language = lang);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 09: Hospital & Doctor Connect
// Connects patients to nearby hospitals. Emergency banner at top
// when risk = HIGH/EMERGENCY. Call Now dials immediately.
// Real Nairobi hospitals with ratings and specialties.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/salama_widgets.dart';
import '../../recovery/providers/recovery_provider.dart';
import '../providers/hospital_provider.dart';

class HospitalConnectScreen extends ConsumerStatefulWidget {
  const HospitalConnectScreen({super.key});

  @override
  ConsumerState<HospitalConnectScreen> createState() =>
      _HospitalConnectScreenState();
}

class _HospitalConnectScreenState
    extends ConsumerState<HospitalConnectScreen> {
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hospitalProvider.notifier).load();
    });
  }

  List<Hospital> _filtered(List<Hospital> all) {
    return switch (_filter) {
      'Emergency' => all.where((h) => h.type == 'emergency').toList(),
      'Private'   => all.where((h) => h.type == 'private').toList(),
      'Public'    => all.where((h) => h.type == 'public').toList(),
      _           => all,
    };
  }

  /// Dial a phone number immediately
  Future<void> _callHospital(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hospitalState = ref.watch(hospitalProvider);
    final recovery = ref.watch(recoveryProvider);
    final filtered = _filtered(hospitalState.hospitals);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Emergency banner — only shown when risk is HIGH/EMERGENCY ──
          if (recovery.hasWarning)
            EmergencyBanner(
              message: recovery.riskLevel == 'EMERGENCY'
                  ? 'EMERGENCY: Go to the nearest hospital immediately.'
                  : 'AI Alert: Your symptoms need medical attention. Contact a hospital.',
              onCall: () => _callHospital('999'),
            ),

          // ── Blue header with search bar ──
          Container(
            color: AppColors.primary,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hospital & Doctor Connect',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const Text('Find care near you in Nairobi',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),

                    // Search bar (visual — functional in Phase 5)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Text('🔍',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white60)),
                          SizedBox(width: 8),
                          Text('Search hospitals or specialties…',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter chips ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: ['All', 'Emergency', 'Private', 'Public']
                  .map((f) {
                final active = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(f,
                        style: TextStyle(
                          fontSize: 11,
                          color: active
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Hospital list — loading / error / data ──
          Expanded(
            child: hospitalState.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Loading hospitals...',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13)),
                      ],
                    ),
                  )
                : hospitalState.errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⚠️',
                                  style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 12),
                              Text(hospitalState.errorMessage,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                              const SizedBox(height: 20),
                              SalamaButton(
                                label: 'Try Again',
                                onTap: () {
                                  ref
                                      .read(hospitalProvider.notifier)
                                      .clearError();
                                  ref
                                      .read(hospitalProvider.notifier)
                                      .load();
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final h = filtered[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: h.hasEmergency
                                    ? AppColors.emergency
                                        .withOpacity(0.3)
                                    : AppColors.border,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                // Emergency badge
                                if (h.hasEmergency)
                                  Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.emergency
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                        '🚑 EMERGENCY SERVICES',
                                        style: TextStyle(
                                            color: AppColors.emergency,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                  ),

                                // Name + type label
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(h.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              color:
                                                  AppColors.textPrimary)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(h.typeLabel,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.primary,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Address
                                if (h.address.isNotEmpty)
                                  Text('📍 ${h.address}',
                                      style: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 12)),
                                const SizedBox(height: 10),

                                // Call button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: h.phone.isNotEmpty
                                        ? () => _callHospital(h.phone)
                                        : null,
                                    icon: const Text('📞',
                                        style: TextStyle(fontSize: 14)),
                                    label: Text(h.phone.isNotEmpty
                                        ? 'Call ${h.phone}'
                                        : 'No phone available'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // ── Bottom nav — active on Doctor (index 4) ──
          SalamaBottomNav(
            currentIndex: 4,
            onTap: (i) {
              final routes = [
                AppRoutes.dashboard,
                AppRoutes.checkIn,
                AppRoutes.aiChat,
                AppRoutes.diet,
                AppRoutes.hospital,
              ];
              if (i < routes.length) context.go(routes[i]);
            },
          ),
        ],
      ),
    );
  }
}

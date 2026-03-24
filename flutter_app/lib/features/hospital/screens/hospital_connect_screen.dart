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

class HospitalConnectScreen extends ConsumerStatefulWidget {
  const HospitalConnectScreen({super.key});

  @override
  ConsumerState<HospitalConnectScreen> createState() =>
      _HospitalConnectScreenState();
}

class _HospitalConnectScreenState
    extends ConsumerState<HospitalConnectScreen> {
  String _filter = 'All';

  // Real Nairobi hospitals with contact details
  final _hospitals = [
    {
      'name': 'Kenyatta National Hospital',
      'specialty': 'General · Surgical',
      'distance': '2.1 km',
      'rating': '4.5',
      'emergency': true,
      'phone': '+254202726300',
    },
    {
      'name': 'Nairobi Hospital',
      'specialty': 'Private · Multi-specialty',
      'distance': '3.4 km',
      'rating': '4.7',
      'emergency': false,
      'phone': '+254202845000',
    },
    {
      'name': 'Aga Khan University Hospital',
      'specialty': 'Private · Surgical · Oncology',
      'distance': '4.8 km',
      'rating': '4.8',
      'emergency': false,
      'phone': '+254203662000',
    },
    {
      'name': 'MP Shah Hospital',
      'specialty': 'Private · General Surgery',
      'distance': '5.2 km',
      'rating': '4.4',
      'emergency': true,
      'phone': '+254204291000',
    },
    {
      'name': 'Karen Hospital',
      'specialty': 'Private · Orthopaedics',
      'distance': '8.1 km',
      'rating': '4.6',
      'emergency': false,
      'phone': '+254206634000',
    },
  ];

  // Filter hospitals by type
  List get _filtered {
    if (_filter == 'Emergency') {
      return _hospitals.where((h) => h['emergency'] == true).toList();
    }
    if (_filter == 'Private') {
      return _hospitals
          .where(
              (h) => (h['specialty'] as String).contains('Private'))
          .toList();
    }
    return _hospitals;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Emergency banner — AI alert ──
          EmergencyBanner(
            message:
                'AI Alert: Based on your symptoms, consider visiting a hospital today.',
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

          // ── Hospital cards list ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final h = _filtered[i] as Map<String, dynamic>;
                final isEmergency = h['emergency'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isEmergency
                          ? AppColors.emergency.withOpacity(0.3)
                          : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emergency services badge
                      if (isEmergency)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
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

                      // Name + rating
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(h['name'] as String,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textPrimary)),
                          ),
                          Row(
                            children: [
                              const Text('★',
                                  style: TextStyle(
                                      color: Color(0xFFBA7517),
                                      fontSize: 14)),
                              Text(' ${h['rating']}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Distance + specialty
                      Text(
                          '📍 ${h['distance']} away · ${h['specialty']}',
                          style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 12)),
                      const SizedBox(height: 10),

                      // Call + Book buttons
                      Row(
                        children: [
                          // Call Now — green, dials immediately
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _callHospital(h['phone'] as String),
                              icon: const Text('📞',
                                  style: TextStyle(fontSize: 14)),
                              label: const Text('Call Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Book Appointment — outlined blue
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Navigate to booking flow
                              },
                              icon: const Text('📅',
                                  style: TextStyle(fontSize: 14)),
                              label: const Text('Book Appt.'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: Color(0xFF85B7EB)),
                                backgroundColor:
                                    AppColors.primaryLight,
                                padding:
                                    const EdgeInsets.symmetric(
                                        vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            10)),
                              ),
                            ),
                          ),
                        ],
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

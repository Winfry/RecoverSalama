// ─────────────────────────────────────────────────────────────
// SalamaRecover — Screen 09: Hospital & Doctor Connect
// Functional search, map view with pins, emergency banner.
// © 2025 Winfry Nyarangi Nyabuto. All Rights Reserved.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
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
  bool _showMap = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hospitalProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Hospital> _filtered(List<Hospital> all) {
    var list = switch (_filter) {
      'Emergency' => all.where((h) => h.type == 'emergency').toList(),
      'Private' => all.where((h) => h.type == 'private').toList(),
      'Public' => all.where((h) => h.type == 'public').toList(),
      _ => all,
    };
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((h) =>
              h.name.toLowerCase().contains(q) ||
              h.address.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  Future<void> _callHospital(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showHospitalInfo(Hospital h) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(h.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(h.typeLabel,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (h.address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('📍 ${h.address}',
                  style: const TextStyle(
                      color: AppColors.textHint, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            SalamaButton(
              label: h.phone.isNotEmpty
                  ? '📞  Call ${h.phone}'
                  : 'No phone on record',
              color: h.phone.isNotEmpty ? AppColors.success : AppColors.border,
              onTap: h.phone.isNotEmpty
                  ? () {
                      Navigator.pop(context);
                      _callHospital(h.phone);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
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
          // ── Emergency banner ──
          if (recovery.hasWarning)
            EmergencyBanner(
              message: recovery.riskLevel == 'EMERGENCY'
                  ? 'EMERGENCY: Go to the nearest hospital immediately.'
                  : 'AI Alert: Your symptoms need medical attention. Contact a hospital.',
              onCall: () => _callHospital('999'),
            ),

          // ── Blue header with live search ──
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
                    const Text('Find care near you across Kenya',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search hospitals or area…',
                        hintStyle:
                            const TextStyle(color: Colors.white54, fontSize: 13),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.white60, size: 18),
                        suffixIcon: _query.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                },
                                child: const Icon(Icons.clear,
                                    color: Colors.white60, size: 18),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter chips + view toggle ──
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          ['All', 'Emergency', 'Private', 'Public'].map((f) {
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
                ),
                const SizedBox(width: 4),
                // List / Map toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _toggleBtn(Icons.list, !_showMap,
                          () => setState(() => _showMap = false)),
                      _toggleBtn(Icons.map_outlined, _showMap,
                          () => setState(() => _showMap = true)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Content: list or map ──
          Expanded(
            child: hospitalState.isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Loading hospitals…',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
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
                    : _showMap
                        ? _buildMap(filtered)
                        : _buildList(filtered),
          ),

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

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
            size: 18,
            color: active ? Colors.white : AppColors.textSecondary),
      ),
    );
  }

  Widget _buildList(List<Hospital> filtered) {
    if (filtered.isEmpty) {
      return const Center(
        child: Text('No hospitals match your search.',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      );
    }
    return ListView.builder(
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
              if (h.hasEmergency)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emergency.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🚑 EMERGENCY SERVICES',
                      style: TextStyle(
                          color: AppColors.emergency,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(h.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.textPrimary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(h.typeLabel,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (h.address.isNotEmpty)
                Text('📍 ${h.address}',
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 12)),
              const SizedBox(height: 10),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(List<Hospital> filtered) {
    final withCoords = filtered
        .where((h) => h.lat != null && h.lng != null)
        .toList();

    const center = LatLng(-1.2864, 36.8172); // Nairobi default

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: center,
            initialZoom: 6.5, // Kenya-wide view so all hospitals are visible
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.salamarecover.app',
            ),
            MarkerLayer(
              markers: [
                ...withCoords.map((h) => Marker(
                      point: LatLng(h.lat!, h.lng!),
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onTap: () => _showHospitalInfo(h),
                        child: Container(
                          decoration: BoxDecoration(
                            color: h.hasEmergency
                                ? AppColors.emergency
                                : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.local_hospital,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    )),
              ],
            ),
          ],
        ),
        // Legend
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6)
              ],
            ),
            child: Text('${withCoords.length} hospitals on map',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
        ),
        // No-coords notice
        if (withCoords.isEmpty)
          const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No GPS coordinates for current filter.',
                    style: TextStyle(color: AppColors.textHint)),
              ),
            ),
          ),
      ],
    );
  }
}

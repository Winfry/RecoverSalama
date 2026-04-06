import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/api_service.dart';
import '../../recovery/providers/recovery_provider.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────

class Hospital {
  final String id;
  final String name;
  final String type;     // "public" | "private" | "mission" | "emergency"
  final String address;
  final String phone;
  final double? lat;
  final double? lng;

  const Hospital({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    this.lat,
    this.lng,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) => Hospital(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown Hospital',
        type: json['type'] as String? ?? 'public',
        address: json['address'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );

  /// True when the hospital type is "emergency"
  bool get hasEmergency => type == 'emergency';

  /// Human-readable type label with emoji
  String get typeLabel => switch (type) {
        'public'    => '🏥 Public',
        'private'   => '🏨 Private',
        'mission'   => '✝️ Mission',
        'emergency' => '🚑 Emergency',
        _           => type,
      };
}

// ─────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────

class HospitalState {
  final List<Hospital> hospitals;
  final bool isLoading;
  final String errorMessage;

  const HospitalState({
    this.hospitals = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  HospitalState copyWith({
    List<Hospital>? hospitals,
    bool? isLoading,
    String? errorMessage,
  }) =>
      HospitalState(
        hospitals: hospitals ?? this.hospitals,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

// ─────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────

class HospitalNotifier extends StateNotifier<HospitalState> {
  final ApiService _api;

  HospitalNotifier(this._api) : super(const HospitalState());

  /// Fetch real hospitals from Supabase via FastAPI.
  /// These are the 18 hospitals seeded in migration 004_seed_hospitals.sql.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final response = await _api.getHospitals();
      final data = (response.data as List<dynamic>)
          .cast<Map<String, dynamic>>();

      state = state.copyWith(
        isLoading: false,
        hospitals: data.map(Hospital.fromJson).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(e),
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: '');

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet. Check your network and try again.';
    }
    return 'Could not load hospitals. Please try again.';
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final hospitalProvider =
    StateNotifierProvider<HospitalNotifier, HospitalState>((ref) {
  return HospitalNotifier(ref.watch(apiServiceProvider));
});

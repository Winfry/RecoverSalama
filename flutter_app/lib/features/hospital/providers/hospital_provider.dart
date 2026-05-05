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
      // On timeout or error, show cached/fallback hospitals so the screen
      // is never empty — Render free tier can take 50s to cold start
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().contains('timeout') || e.toString().contains('SocketException')
            ? 'Could not reach server. Showing cached hospitals.'
            : _friendlyError(e),
        hospitals: state.hospitals.isNotEmpty ? state.hospitals : _fallbackHospitals(),
      );
    }
  }

  /// Fallback hospitals shown when the API is unreachable (Render cold start)
  List<Hospital> _fallbackHospitals() => [
    const Hospital(id: '1', name: 'Kenyatta National Hospital', type: 'public', address: 'Hospital Rd, Upper Hill, Nairobi', phone: '+254202726300', lat: -1.3011, lng: 36.8073),
    const Hospital(id: '2', name: 'Nairobi Hospital', type: 'private', address: 'Argwings Kodhek Rd, Nairobi', phone: '+254202845000', lat: -1.2964, lng: 36.8100),
    const Hospital(id: '3', name: 'Aga Khan University Hospital', type: 'private', address: '3rd Parklands Ave, Nairobi', phone: '+254203662000', lat: -1.2614, lng: 36.8175),
    const Hospital(id: '4', name: 'MP Shah Hospital', type: 'private', address: 'Shivachi Rd, Parklands', phone: '+254204291000', lat: -1.2611, lng: 36.8136),
    const Hospital(id: '5', name: 'Mater Misericordiae Hospital', type: 'mission', address: 'Dunga Rd, South B, Nairobi', phone: '+254206903000', lat: -1.3100, lng: 36.8300),
    const Hospital(id: '6', name: 'Mama Lucy Kibaki Hospital', type: 'public', address: 'Kangundo Rd, Embakasi', phone: '+254202019100', lat: -1.2964, lng: 36.8978),
    const Hospital(id: '7', name: 'Mbagathi County Hospital', type: 'public', address: 'Mbagathi Way, Nairobi', phone: '+254202725200', lat: -1.3175, lng: 36.7950),
    const Hospital(id: '8', name: 'Coast General Hospital', type: 'public', address: 'Moi Ave, Mombasa', phone: '+254412314201', lat: -4.0435, lng: 39.6682),
    const Hospital(id: '9', name: 'Jaramogi Oginga Odinga Hospital', type: 'public', address: 'Kisumu', phone: '+254572021501', lat: -0.1022, lng: 34.7617),
    const Hospital(id: '10', name: 'Moi Teaching and Referral Hospital', type: 'public', address: 'Nandi Rd, Eldoret', phone: '+254532033000', lat: 0.5167, lng: 35.2833),
  ];

  void clearError() => state = state.copyWith(errorMessage: '');

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('connection')) {
      return 'No internet. Check your network and try again.';
    }
    if (msg.contains('timeout') || msg.contains('Timeout')) {
      return 'Server is starting up — please wait a moment and try again.';
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../../recovery/providers/recovery_provider.dart';

/// Patient profile data model
class PatientProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String surgeryType;
  final DateTime? surgeryDate;
  final String hospital;
  final String surgeon;
  final double weight;
  final String bloodType;
  final List<String> allergies;
  final String otherAllergies;
  final String phone;
  final String caregiverPhone;
  final bool isLoaded;
  final String errorMessage;

  const PatientProfile({
    this.id = '',
    this.name = '',
    this.age = 0,
    this.gender = '',
    this.surgeryType = '',
    this.surgeryDate,
    this.hospital = '',
    this.surgeon = '',
    this.weight = 0,
    this.bloodType = '',
    this.allergies = const [],
    this.otherAllergies = '',
    this.phone = '',
    this.caregiverPhone = '',
    this.isLoaded = false,
    this.errorMessage = '',
  });

  /// Days since surgery — calculated from surgeryDate, never hardcoded.
  int get daysSinceSurgery {
    if (surgeryDate == null) return 0;
    return DateTime.now().difference(surgeryDate!).inDays;
  }

  PatientProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? surgeryType,
    DateTime? surgeryDate,
    String? hospital,
    String? surgeon,
    double? weight,
    String? bloodType,
    List<String>? allergies,
    String? otherAllergies,
    String? phone,
    String? caregiverPhone,
    bool? isLoaded,
    String? errorMessage,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      surgeryType: surgeryType ?? this.surgeryType,
      surgeryDate: surgeryDate ?? this.surgeryDate,
      hospital: hospital ?? this.hospital,
      surgeon: surgeon ?? this.surgeon,
      weight: weight ?? this.weight,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      otherAllergies: otherAllergies ?? this.otherAllergies,
      phone: phone ?? this.phone,
      caregiverPhone: caregiverPhone ?? this.caregiverPhone,
      isLoaded: isLoaded ?? this.isLoaded,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<PatientProfile> {
  final ApiService _api;

  ProfileNotifier(this._api) : super(const PatientProfile());

  /// Load the patient's profile from the backend.
  /// Called once after login and after profile setup completes.
  Future<void> loadProfile() async {
    try {
      final response = await _api.getMyProfile();
      final data = response.data as Map<String, dynamic>;

      DateTime? surgeryDate;
      final rawDate = data['surgery_date'];
      if (rawDate != null && rawDate.toString().isNotEmpty) {
        try {
          surgeryDate = DateTime.parse(rawDate.toString().substring(0, 10));
        } catch (_) {
          surgeryDate = null;
        }
      }

      state = PatientProfile(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        age: (data['age'] as num?)?.toInt() ?? 0,
        gender: data['gender']?.toString() ?? '',
        surgeryType: data['surgery_type']?.toString() ?? '',
        surgeryDate: surgeryDate,
        hospital: data['hospital']?.toString() ?? '',
        surgeon: data['surgeon']?.toString() ?? '',
        weight: (data['weight'] as num?)?.toDouble() ?? 0,
        bloodType: data['blood_type']?.toString() ?? '',
        allergies: List<String>.from(data['allergies'] ?? []),
        otherAllergies: data['other_allergies']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        caregiverPhone: data['caregiver_phone']?.toString() ?? '',
        isLoaded: true,
        errorMessage: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoaded: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update profile in state after setup wizard completes.
  void setFromSetup(Map<String, dynamic> data) {
    DateTime? surgeryDate;
    final rawDate = data['surgery_date'];
    if (rawDate is DateTime) {
      surgeryDate = rawDate;
    } else if (rawDate != null) {
      try {
        surgeryDate = DateTime.parse(rawDate.toString().substring(0, 10));
      } catch (_) {}
    }

    state = PatientProfile(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      gender: data['gender']?.toString() ?? '',
      surgeryType: data['surgery_type']?.toString() ?? '',
      surgeryDate: surgeryDate,
      hospital: data['hospital']?.toString() ?? '',
      surgeon: data['surgeon']?.toString() ?? '',
      weight: (data['weight'] as num?)?.toDouble() ?? 0,
      bloodType: data['blood_type']?.toString() ?? '',
      allergies: List<String>.from(data['allergies'] ?? []),
      otherAllergies: data['other_allergies']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      caregiverPhone: data['caregiver_phone']?.toString() ?? '',
      isLoaded: true,
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, PatientProfile>((ref) {
  return ProfileNotifier(ref.watch(apiServiceProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Patient profile data model
class PatientProfile {
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

  const PatientProfile({
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
  });

  /// Days since surgery
  int get daysSinceSurgery {
    if (surgeryDate == null) return 0;
    return DateTime.now().difference(surgeryDate!).inDays;
  }

  PatientProfile copyWith({
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
  }) {
    return PatientProfile(
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
    );
  }
}

/// Profile state notifier
class ProfileNotifier extends StateNotifier<PatientProfile> {
  ProfileNotifier() : super(const PatientProfile());

  void saveProfile({
    required String name,
    required int age,
    required String gender,
    required String surgeryType,
    required DateTime? surgeryDate,
    required String hospital,
    required String surgeon,
    required double weight,
    required String bloodType,
    required List<String> allergies,
    required String otherAllergies,
  }) {
    state = PatientProfile(
      name: name,
      age: age,
      gender: gender,
      surgeryType: surgeryType,
      surgeryDate: surgeryDate,
      hospital: hospital,
      surgeon: surgeon,
      weight: weight,
      bloodType: bloodType,
      allergies: allergies,
      otherAllergies: otherAllergies,
    );
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, PatientProfile>((ref) {
  return ProfileNotifier();
});

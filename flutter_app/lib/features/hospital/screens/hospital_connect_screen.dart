import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/colors.dart';

/// Screen 09 — Hospital Connect
/// Search hospitals, filter by type (All, Emergency, Private),
/// toggle list/map view. Each hospital card has Call and Book buttons.
/// AI alert banner at top when symptoms warrant a visit.
class HospitalConnectScreen extends ConsumerStatefulWidget {
  const HospitalConnectScreen({super.key});

  @override
  ConsumerState<HospitalConnectScreen> createState() =>
      _HospitalConnectScreenState();
}

class _HospitalConnectScreenState extends ConsumerState<HospitalConnectScreen> {
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();

  final _filters = ['All', 'Emergency', 'Private', 'Public'];

  // Sample hospitals — will be fetched from backend
  final _hospitals = [
    _Hospital(
      name: 'Kenyatta National Hospital',
      type: 'Emergency',
      distance: '2.1km',
      category: 'General',
      rating: 4.5,
      phone: '+254202726300',
    ),
    _Hospital(
      name: 'Nairobi Hospital',
      type: 'Private',
      distance: '3.4km',
      category: 'Private',
      rating: 4.7,
      phone: '+254203846000',
    ),
    _Hospital(
      name: 'Mbagathi Hospital',
      type: 'Public',
      distance: '4.2km',
      category: 'County',
      rating: 3.8,
      phone: '+254202725272',
    ),
    _Hospital(
      name: 'Aga Khan University Hospital',
      type: 'Private',
      distance: '5.1km',
      category: 'Private',
      rating: 4.8,
      phone: '+254203662000',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_Hospital> get _filteredHospitals {
    return _hospitals.where((h) {
      if (_selectedFilter != 'All' && h.type != _selectedFilter) return false;
      if (_searchController.text.isNotEmpty) {
        return h.name
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // AI Alert banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.emergencyLight,
              child: Row(
                children: [
                  const Text('🚨', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Alert: Consider visiting hospital',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.emergency,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final uri = Uri(scheme: 'tel', path: '999');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    child: const Text(
                      'Call',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emergency,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hospital & Doctor Connect',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Find care near you in Nairobi',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search hospitals...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color:
                            isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Hospital cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredHospitals.length,
                itemBuilder: (context, index) {
                  final hospital = _filteredHospitals[index];
                  return _HospitalCard(hospital: hospital);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hospital {
  final String name;
  final String type;
  final String distance;
  final String category;
  final double rating;
  final String phone;

  const _Hospital({
    required this.name,
    required this.type,
    required this.distance,
    required this.category,
    required this.rating,
    required this.phone,
  });
}

class _HospitalCard extends StatelessWidget {
  final _Hospital hospital;

  const _HospitalCard({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hospital.type == 'Emergency'
                      ? AppColors.emergencyLight
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hospital.type == 'Emergency'
                      ? '🚑 EMERGENCY'
                      : hospital.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hospital.type == 'Emergency'
                        ? AppColors.emergency
                        : AppColors.primary,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.warning),
                  const SizedBox(width: 2),
                  Text(
                    hospital.rating.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hospital name
          Text(
            hospital.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Distance + category
          Text(
            '📍 ${hospital.distance} · ${hospital.category}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri(scheme: 'tel', path: hospital.phone);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to booking flow
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

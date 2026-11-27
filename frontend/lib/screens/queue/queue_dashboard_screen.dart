import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/triage_provider.dart';
import '../detail/patient_detail_screen.dart';
import '../profile/nurse_profile_screen.dart';
import 'patient_queue_card.dart';
import 'public_tv_screen.dart';

class QueueDashboardScreen extends StatelessWidget {
  final TriageProvider provider;

  const QueueDashboardScreen({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final patients = provider.filteredPatients;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildMonitorTvBanner(context)),
                SliverToBoxAdapter(child: _buildSectionTitle()),
                SliverToBoxAdapter(child: _buildFilterChips()),
                if (patients.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final patient = patients[index];
                          return PatientQueueCard(
                            patient: patient,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PatientDetailScreen(
                                    provider: provider,
                                    patientId: patient.id,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        childCount: patients.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_vita.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'V.I.T.A. TRIAGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  'Antrean Triase',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: provider.connectionMode.label,
            onPressed: () {
              provider.toggleConnectionMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mode diubah ke: ${provider.connectionMode.label}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(
              provider.isOnline
                  ? Icons.notifications_none_rounded
                  : Icons.cloud_off_rounded,
              color: AppColors.navyDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NurseProfileScreen(provider: provider),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: ClipOval(
              child: Image.asset(
                'assets/images/profil.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorTvBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monitor TV Ruang Tunggu IGD • Aktif',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Transparansi ruang tunggu pasien (Privasi aman)',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PublicTvScreen(provider: provider),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat TV',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          const Text(
            'Antrean Triase',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.totalActiveCount} Aktif',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'name': 'Semua', 'count': provider.totalActiveCount, 'hasDot': false},
      {'name': 'Merah', 'count': provider.redCount, 'hasDot': true},
      {'name': 'Kuning', 'count': provider.yellowCount, 'hasDot': true},
      {'name': 'Hijau', 'count': provider.greenCount, 'hasDot': true},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((item) {
          final name = item['name'] as String;
          final count = item['count'] as int;
          final hasDot = item['hasDot'] as bool;
          final isSelected = provider.selectedFilter == name;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => provider.setFilter(name),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryDeep : AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDot) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Text(
                      '$name  ($count)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.navyDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textSubtle),
          SizedBox(height: 10),
          Text(
            'Tidak ada pasien pada filter ini',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

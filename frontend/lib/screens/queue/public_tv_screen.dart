import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/triage_enums.dart';
import '../../providers/triage_provider.dart';

class PublicTvScreen extends StatelessWidget {
  final TriageProvider provider;

  const PublicTvScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final p1List = provider.activePatients
            .where((p) => p.priority == TriagePriority.red)
            .toList();
        final p2List = provider.activePatients
            .where((p) => p.priority == TriagePriority.yellow)
            .toList();
        final p3List = provider.activePatients
            .where((p) => p.priority == TriagePriority.green)
            .toList();

        final p1Title = p1List.isNotEmpty
            ? 'Antrean ${p1List.first.queueNumber}'
            : 'Antrean #042';
        final p2Title = p2List.isNotEmpty
            ? 'Antrean ${p2List.first.queueNumber}  •  +${p2List.length > 1 ? p2List.length - 1 : 0} Pasien Lainnya'
            : 'Antrean #041  •  +0 Pasien Lainnya';
        final p3Nums = p3List.take(3).map((e) => e.queueNumber).join(', ');
        final p3Title = p3List.isNotEmpty
            ? 'Antrean $p3Nums  •  Total ${p3List.length} Pasien'
            : 'Belum ada antrean non-kritis';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Dark Navy Header (matching Layar Antrean Publik IGD.png)
              Container(
                color: AppColors.navyHeader,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded,
                                    size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Mode Perawat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Text(
                          'TV Ruang Tunggu IGD • Live',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Privacy Notice Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryBorder),
                        ),
                        child: const Text(
                          'Pasien dengan kondisi kritis (Prioritas 1) ditangani lebih dulu demi keselamatan nyawa. Data medis pribadi tetap dirahasiakan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.navyDark,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Priority 1 Card
                      _buildTvPriorityCard(
                        badgeText: 'PRIORITAS 1 • DITANGANI SEGERA (RESUSITASI)',
                        headline: p1Title,
                        statusLine: '⚡ SEDANG DITANGANI TIM MEDIS (0 Menit)',
                        roomLine: 'Ruang Resusitasi • Bed 01–02 • Dokter & Perawat Siaga',
                        footerLine: 'Diperbarui otomatis via V.I.T.A. Voice Triage • 13:42 WIB',
                      ),
                      const SizedBox(height: 14),
                      // Priority 2 Card
                      _buildTvPriorityCard(
                        badgeText: 'PRIORITAS 2 • OBSERVASI DARURAT',
                        headline: p2Title,
                        statusLine: '⏳ Estimasi Waktu Tunggu: < 10–15 Menit',
                        roomLine: 'Zona Observasi Darurat • Bed 03–07',
                        footerLine: 'Tanda vital terpantau sistem • Menunggu giliran dokter IGD',
                      ),
                      const SizedBox(height: 14),
                      // Priority 3 Card
                      _buildTvPriorityCard(
                        badgeText: 'PRIORITAS 3 • TINDAKAN NON-KRITIS (STABIL)',
                        headline: p3Title,
                        statusLine: '🕒 Estimasi Waktu Tunggu: ± 25–35 Menit',
                        roomLine: 'Zona Triase Hijau / Tindakan Minor',
                        footerLine: 'Kondisi tanda vital stabil • Dipanggil berurutan sesuai nomor',
                      ),
                      const SizedBox(height: 16),
                      // Privacy Compliance Card + Back Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔒 Kepatuhan Privasi Pasien (UU PDP & Kemenkes)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Hanya menampilkan Nomor Antrean, Kategori Prioritas IITT, dan Estimasi Waktu Tunggu. Nama & keluhan medis hanya di perangkat perawat.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                label: const Text('Kembali ke Antrean Perawat'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTvPriorityCard({
    required String badgeText,
    required String headline,
    required String statusLine,
    required String roomLine,
    required String footerLine,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTintSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryBorder, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.navyDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusLine,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            roomLine,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            footerLine,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

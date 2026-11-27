import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/audio_memo_player.dart';
import '../../widgets/transcript_accordion.dart';
import '../../widgets/vita_step_app_bar.dart';
import '../../widgets/vital_history_section.dart';
import '../profile/nurse_profile_screen.dart';
import '../satusehat/satusehat_fhir_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final TriageProvider provider;
  final String patientId;

  const PatientDetailScreen({
    super.key,
    required this.provider,
    required this.patientId,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  bool _statusMenuOpen = false;

  static const List<Map<String, String>> _statusItems = [
    {
      'status': 'Menunggu Dokter',
      'bed': 'TERISI (Menunggu Dokter Jaga)',
      'tv': 'Menunggu Dokter',
    },
    {
      'status': 'Sedang Ditangani Dokter',
      'bed': 'TERISI (Tindakan Resusitasi Aktif)',
      'tv': 'Sedang Ditangani',
    },
    {
      'status': 'Observasi & Stabilisasi',
      'bed': 'TERISI (Pemantauan Monitor Vital)',
      'tv': 'Observasi Stabil',
    },
    {
      'status': 'Selesai / Pindah Ruang (ICU)',
      'bed': 'KOSONG (Siap untuk Pasien Baru)',
      'tv': 'Pindah ke Ruang ICU',
    },
  ];

  Map<String, String> _metaForStatus(String status) {
    return _statusItems.firstWhere(
      (e) => e['status'] == status,
      orElse: () => _statusItems.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final patient = widget.provider.findById(widget.patientId);
        if (patient == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Pasien')),
            body: const Center(child: Text('Data pasien tidak ditemukan.')),
          );
        }

        final meta = _metaForStatus(patient.handlingStatus);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: VitaStepAppBar(
            title: 'Detail Pasien ${patient.queueNumber}',
            centerTitle: true,
            onProfileTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NurseProfileScreen(provider: widget.provider),
                ),
              );
            },
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '•  ${patient.priority.detailBadge}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '✳  ${patient.priority.categoryText}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${patient.gender}, ${patient.ageYears} Tahun',
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '(${patient.ageGroup.shortLabel})',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_outlined,
                                      size: 15, color: AppColors.navyDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${patient.queueNumber} • NIK Terverifikasi Dukcapil',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined,
                                    size: 15, color: AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Diverifikasi Perawat ${patient.verifiedBy} • ${patient.verifiedAt}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(
                                height: 22, color: AppColors.borderLight),
                            const Text(
                              'Status Penanganan IGD',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Custom Interactive Status Selector (matching Status Penanganan IGD _ Interactive.png)
                            InkWell(
                              onTap: () => setState(
                                  () => _statusMenuOpen = !_statusMenuOpen),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                  color: _statusMenuOpen
                                      ? AppColors.primaryTintSoft
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _statusMenuOpen
                                        ? AppColors.primaryBlue
                                        : AppColors.border,
                                    width: _statusMenuOpen ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _statusMenuOpen
                                            ? 'Pilih Status Penanganan IGD...'
                                            : 'Status: ${patient.handlingStatus}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _statusMenuOpen
                                              ? AppColors.primaryDeep
                                              : AppColors.navyDark,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _statusMenuOpen
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_statusMenuOpen) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.primaryBlue),
                                ),
                                child: Column(
                                  children: _statusItems.map((item) {
                                    final isSelected =
                                        item['status'] == patient.handlingStatus;
                                    return InkWell(
                                      onTap: () {
                                        final newStatus = item['status']!;
                                        widget.provider.updatePatient(
                                          patient.copyWith(
                                            handlingStatus: newStatus,
                                            isCompleted: newStatus
                                                .startsWith('Selesai'),
                                          ),
                                        );
                                        setState(() => _statusMenuOpen = false);
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryTintSoft
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• Status: ${item['status']}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected
                                                    ? AppColors.primaryDeep
                                                    : AppColors.navyDark,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10, top: 2),
                                              child: Text(
                                                '${patient.bedLabel}: ${item['bed']}',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ] else ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '• ${patient.bedLabel}: ${meta['bed']}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryDeep,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '• TV Ruang Tunggu: "Pasien ${patient.queueNumber} — ${meta['tv']}"',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Audio Memo Player & Collapsible Original Transcript
                      AudioMemoPlayer(
                        fileLabel: 'Audio Triase ${patient.queueNumber}.wav',
                        totalSeconds: patient.audioDurationSeconds,
                      ),
                      const SizedBox(height: 10),
                      TranscriptAccordion(
                        transcript: patient.originalTranscript,
                      ),
                      const SizedBox(height: 20),
                      // Section: INTEROPERABILITAS (KEMENKES SATUSEHAT)
                      const Row(
                        children: [
                          Icon(Icons.fact_check_outlined,
                              size: 18, color: AppColors.primaryDeep),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'INTEROPERABILITAS (KEMENKES SATUSEHAT)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDark,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: AppColors.primaryBlue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              patient.satusehatSynced
                                                  ? 'Terkirim ke SATUSEHAT'
                                                  : 'Siap Kirim ke SATUSEHAT',
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.navyDark,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryTint,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              patient.satusehatSynced
                                                  ? 'HTTP 201 Created ✓'
                                                  : 'Validasi Sukses (FHIR R4)',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        '3 Resource FHIR terbentuk (Patient, Encounter, Observation)',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _resourceTag('Patient/${patient.id}'),
                                _resourceTag('Encounter/IGD-202505'),
                                _resourceTag('Observation/Vitals-6'),
                              ],
                            ),
                            const Divider(
                                height: 24, color: AppColors.borderLight),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SatusehatFhirScreen(
                                          provider: widget.provider,
                                          patient: patient,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Lihat JSON SATUSEHAT',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: AppColors.primaryBlue),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'HL7 FHIR Release 4',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Toggleable Vital Signs & Periodic Measurement History
                      VitalHistorySection(patient: patient),
                    ],
                  ),
                ),
              ),
              // Bottom Action Button
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            widget.provider.markHandledByDoctor(patient.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Pasien ${patient.queueNumber} ditandai sudah ditangani dokter.'),
                                backgroundColor: AppColors.primaryDeep,
                              ),
                            );
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.medical_services_outlined,
                              size: 20),
                          label: const Text('Tandai Sudah Ditangani Dokter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Otomatis memperbarui daftar antrean IGD.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
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

  Widget _resourceTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Courier',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.navyDark,
        ),
      ),
    );
  }
}

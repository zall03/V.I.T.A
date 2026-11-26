import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../providers/triage_provider.dart';
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
  static const List<String> _statusOptions = [
    'Menunggu Dokter',
    'Sedang Ditangani Dokter',
    'Observasi IGD',
    'Sudah Ditangani Dokter',
  ];

  PatientTriage? _findPatient() {
    for (final p in widget.provider.activePatients) {
      if (p.id == widget.patientId) return p;
    }
    for (final p in widget.provider.historyPatients) {
      if (p.id == widget.patientId) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final patient = _findPatient();
        if (patient == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Pasien')),
            body: const Center(child: Text('Data pasien tidak ditemukan.')),
          );
        }

        final currentStatus = _statusOptions.contains(patient.handlingStatus)
            ? patient.handlingStatus
            : _statusOptions.first;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
            ),
            title: Text(
              'Detail Pasien ${patient.queueNumber}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Summary Card (matching halaman hasil kesimpulan.png)
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
                            const Divider(height: 22, color: AppColors.borderLight),
                            const Text(
                              'Status Penanganan IGD',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentStatus,
                                  isExpanded: true,
                                  icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.textSecondary),
                                  items: _statusOptions
                                      .map((st) => DropdownMenuItem(
                                            value: st,
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
                                                Text(
                                                  'Status: $st',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.navyDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      widget.provider.updatePatient(
                                        patient.copyWith(
                                          handlingStatus: val,
                                          isCompleted:
                                              val == 'Sudah Ditangani Dokter',
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                            child: const Text(
                                              'Validasi Sukses (FHIR R4)',
                                              style: TextStyle(
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
                            const Divider(height: 24, color: AppColors.borderLight),
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
                                          size: 16, color: AppColors.primaryBlue),
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
                      // Section: TANDA VITAL TERVALIDASI
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.monitor_heart_outlined,
                                  size: 18, color: AppColors.primaryDeep),
                              SizedBox(width: 8),
                              Text(
                                'TANDA VITAL\nTERVALIDASI',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Riwayat\nPengukuran',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 16, color: AppColors.primaryBlue),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _vitalTile('Tekanan Darah (TD)',
                                '${patient.vitals.bpValue} mmHg', patient.vitals.bpStatus),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _vitalTile('Frekuensi Nadi',
                                '${patient.vitals.heartRate} x/mnt', patient.vitals.hrStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _vitalTile('Saturasi O2 (SpO2)',
                                '${patient.vitals.spo2}%', patient.vitals.spo2Status),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _vitalTile('Laju Napas (RR)',
                                '${patient.vitals.respiratoryRate} x/mnt', patient.vitals.rrStatus),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Action Button (matching halaman hasil kesimpulan.png)
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

  Widget _vitalTile(String title, String value, String status) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

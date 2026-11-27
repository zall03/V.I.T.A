import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../models/triage_enums.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';
import '../profile/nurse_profile_screen.dart';

class TriageStep4ResultScreen extends StatefulWidget {
  final TriageProvider provider;
  final PatientTriage patient;

  const TriageStep4ResultScreen({
    super.key,
    required this.provider,
    required this.patient,
  });

  @override
  State<TriageStep4ResultScreen> createState() =>
      _TriageStep4ResultScreenState();
}

class _TriageStep4ResultScreenState extends State<TriageStep4ResultScreen> {
  late PatientTriage _patient;

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
  }

  void _showOverrideDialog() {
    TriagePriority selected = _patient.priority;
    final reasonController =
        TextEditingController(text: _patient.overrideReason ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Ubah Prioritas (Dengan Alasan Klinis)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...TriagePriority.values.map(
                (p) => RadioListTile<TriagePriority>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.queueLabel,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  value: p,
                  groupValue: selected,
                  activeColor: AppColors.primaryDeep,
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selected = val);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Alasan Klinis (Wajib)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _patient = _patient.copyWith(
                    priority: selected,
                    manualOverride: true,
                    overrideReason: reasonController.text.trim(),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveToQueue() {
    widget.provider.addPatient(_patient);
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pasien ${_patient.queueNumber} (${_patient.priority.label}) berhasil disimpan ke Antrean IGD.',
        ),
        backgroundColor: AppColors.primaryDeep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _patient;
    final pr = p.priority;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VitaStepAppBar(
        title: 'Rekam Suara Triase',
        stepText: 'Langkah 4/4',
        progress: 1.0,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Info Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 18, color: AppColors.primaryDeep),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Pasien ${p.queueNumber}  •  ${p.gender}, ${p.ageYears} th',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 13, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              'Selesai: Baru saja',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Hero Priority Result Card (matching halaman hasil pendataan.png)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTintSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '✳  ${pr.badgeTitle}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pr.levelText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          pr.headline,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              _heroInfoRow(
                                Icons.meeting_room_outlined,
                                'Rekomendasi Ruang',
                                pr.recommendedRoom,
                              ),
                              const Divider(height: 18, color: AppColors.borderLight),
                              _heroInfoRow(
                                Icons.timer_outlined,
                                'Waktu Tunggu Maksimal',
                                pr.waitTime,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Clinical Rationale Card (WHO Deterministic Rules)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryPillBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: AppColors.primaryDeep,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pr.rationaleTitle,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                  const Text(
                                    'Otomatis dihitung dari tanda vital pasien:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...p.objectiveTriggers.asMap().entries.map((entry) {
                          final isFirst = entry.key == 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isFirst
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isFirst
                                          ? AppColors.primaryBlue
                                          : AppColors.textPrimary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (p.manualOverride &&
                            (p.overrideReason?.isNotEmpty ?? false)) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Override Perawat: ${p.overrideReason}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.fact_check_outlined,
                                  size: 16, color: AppColors.navyDark),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aturan Deterministik WHO IITT — Transparan & patuh audit Kemenkes RI.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Validated Vitals Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.monitor_heart_outlined,
                                    size: 18, color: AppColors.primaryDeep),
                                SizedBox(width: 8),
                                Text(
                                  'RINGKASAN TANDA VITAL\nTERVALIDASI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyDark,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '✓ Terverifikasi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _miniVitalBox(
                                'Saturasi O2 (SpO2)',
                                '${p.vitals.spo2}%',
                                '(Kritis)',
                                tintBg: true,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _miniVitalBox(
                                'Frekuensi Nadi',
                                '${p.vitals.heartRate}',
                                'bpm',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Bottom Actions
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  TextButton.icon(
                    onPressed: _showOverrideDialog,
                    icon: const Icon(Icons.tune_rounded,
                        size: 18, color: AppColors.navyDark),
                    label: const Text(
                      'Ubah Prioritas (Dengan Alasan Klinis)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saveToQueue,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Simpan ke Antrean',
                            style: TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data otomatis tersinkronisasi ke SIMRS / SATUSEHAT',
                    style: TextStyle(
                      fontSize: 11.5,
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
  }

  Widget _heroInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.navyDark),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniVitalBox(String title, String val, String suffix,
      {bool tintBg = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tintBg ? AppColors.primaryTintSoft : AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                suffix,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

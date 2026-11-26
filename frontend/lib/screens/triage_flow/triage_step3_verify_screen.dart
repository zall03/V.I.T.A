import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../models/triage_enums.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';
import 'triage_step4_result_screen.dart';

class TriageStep3VerifyScreen extends StatefulWidget {
  final TriageProvider provider;
  final PatientTriage draftPatient;

  const TriageStep3VerifyScreen({
    super.key,
    required this.provider,
    required this.draftPatient,
  });

  @override
  State<TriageStep3VerifyScreen> createState() => _TriageStep3VerifyScreenState();
}

class _TriageStep3VerifyScreenState extends State<TriageStep3VerifyScreen> {
  late String _complaint;
  late String _avpu;
  late VitalsData _vitals;
  int? _painScale;

  static const List<String> _avpuOptions = [
    'Sadar Penuh (Alert / A)',
    'Merespon Suara (Voice / V)',
    'Merespon Nyeri (Pain / P)',
    'Tidak Merespon (Unresponsive / U)',
  ];

  @override
  void initState() {
    super.initState();
    _complaint = widget.draftPatient.chiefComplaint;
    _avpu = widget.draftPatient.vitals.avpu;
    _vitals = widget.draftPatient.vitals.copyWith();
    _painScale = widget.draftPatient.painScaleNrs;
  }

  void _editComplaint() {
    final controller = TextEditingController(text: _complaint);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Keluhan Utama',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() => _complaint = controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _openPainScaleSheet() {
    double current = (_painScale ?? 8).toDouble();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final score = current.round();
          final desc = score >= 7
              ? 'Nyeri Berat (VAS)'
              : score >= 4
                  ? 'Nyeri Sedang (VAS)'
                  : score >= 1
                      ? 'Nyeri Ringan (VAS)'
                      : 'Tidak Nyeri';
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Skala Nyeri Pasien (NRS / VAS 0–10)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '$score / 10',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: current,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: AppColors.primaryBlue,
                    label: '$score',
                    onChanged: (v) => setModalState(() => current = v),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _painScale = score);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Simpan Skala Nyeri'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _editVitalDialog(String title, String initial, ValueChanged<String> onSave) {
    final controller = TextEditingController(text: initial);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _verifyAndCalculateIitt() {
    final pain = _painScale ?? 8;
    TriagePriority priority = TriagePriority.green;
    final triggers = <String>[];

    if (_vitals.spo2 < 90 || _avpu.contains('Unresponsive')) {
      priority = TriagePriority.red;
      triggers.add('SpO2 ${_vitals.spo2}% (Oksigen kritis di bawah 90%)');
      triggers.add('Nyeri dada berat & sesak napas (Risiko kardiorespirasi tinggi)');
      triggers.add(
        'RR ${_vitals.respiratoryRate} x/mnt & Nadi ${_vitals.heartRate} x/mnt di atas ambang takikardia/takipnea',
      );
    } else if (_vitals.spo2 < 95 ||
        _vitals.heartRate > 100 ||
        _vitals.respiratoryRate > 24 ||
        pain >= 7) {
      priority = TriagePriority.yellow;
      triggers.add('Parameter TTV di luar ambang normal atau nyeri NRS $pain/10');
    } else {
      triggers.add('Seluruh tanda vital dalam rentang stabil');
    }

    final verified = widget.draftPatient.copyWith(
      chiefComplaint: _complaint,
      vitals: _vitals.copyWith(avpu: _avpu),
      painScaleNrs: pain,
      priority: priority,
      objectiveTriggers: triggers,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TriageStep4ResultScreen(
          provider: widget.provider,
          patient: verified,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.draftPatient;
    final hasPain = _painScale != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const VitaStepAppBar(
        title: 'Rekam Suara Triase',
        stepText: 'Langkah 3/4',
        progress: 0.75,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.badge_outlined,
                                  size: 18, color: AppColors.primaryDeep),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Pasien ${p.queueNumber} • ${p.gender}, ${p.ageYears} th',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 15, color: AppColors.navyDark),
                              SizedBox(width: 4),
                              Text(
                                'AI Siap',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Section 1: KELUHAN & KESADARAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '1. KELUHAN & KESADARAN',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPillBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Transkrip Suara',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Chief Complaint Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Keluhan Utama',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            InkWell(
                              onTap: _editComplaint,
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_outlined,
                                      size: 14, color: AppColors.primaryBlue),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _complaint,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // AVPU Dropdown Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tingkat Kesadaran (AVPU)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _avpuOptions.contains(_avpu)
                                ? _avpu
                                : _avpuOptions.first,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary),
                            items: _avpuOptions
                                .map((opt) => DropdownMenuItem(
                                      value: opt,
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
                                          Flexible(
                                            child: Text(
                                              opt,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.navyDark,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _avpu = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Section 2: TANDA VITAL (6 Parameter Klinis)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '2. TANDA VITAL',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        '6 Parameter Klinis',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 1: TD & Nadi
                  Row(
                    children: [
                      Expanded(
                        child: _vitalCard(
                          label: 'Tekanan Darah',
                          value: _vitals.bpValue,
                          unit: 'mmHg',
                          status: _vitals.bpStatus,
                          onTap: () => _editVitalDialog(
                            'Tekanan Darah (Sistolik/Diastolik)',
                            _vitals.bpValue,
                            (val) {
                              final parts = val.split('/');
                              if (parts.length == 2) {
                                final s = int.tryParse(parts[0].trim());
                                final d = int.tryParse(parts[1].trim());
                                if (s != null && d != null) {
                                  setState(() => _vitals = _vitals.copyWith(
                                      systolicBp: s, diastolicBp: d));
                                }
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _vitalCard(
                          label: 'Frekuensi Nadi',
                          value: '${_vitals.heartRate}',
                          unit: 'x/mnt',
                          status: _vitals.hrStatus,
                          statusBlue: true,
                          trailingDot: true,
                          onTap: () => _editVitalDialog(
                            'Frekuensi Nadi (x/mnt)',
                            '${_vitals.heartRate}',
                            (val) {
                              final n = int.tryParse(val);
                              if (n != null) {
                                setState(() =>
                                    _vitals = _vitals.copyWith(heartRate: n));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2: RR & SpO2
                  Row(
                    children: [
                      Expanded(
                        child: _vitalCard(
                          label: 'Pernapasan (RR)',
                          value: '${_vitals.respiratoryRate}',
                          unit: 'x/mnt',
                          status: _vitals.rrStatus,
                          statusBlue: true,
                          onTap: () => _editVitalDialog(
                            'Pernapasan RR (x/mnt)',
                            '${_vitals.respiratoryRate}',
                            (val) {
                              final n = int.tryParse(val);
                              if (n != null) {
                                setState(() => _vitals =
                                    _vitals.copyWith(respiratoryRate: n));
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _vitalCard(
                          label: 'Saturasi O2 (SpO2)',
                          value: '${_vitals.spo2}%',
                          unit: '',
                          status: _vitals.spo2Status,
                          highlightedBg: true,
                          valueBlue: true,
                          statusBlue: true,
                          trailingExclamation: true,
                          onTap: () => _editVitalDialog(
                            'Saturasi SpO2 (%)',
                            '${_vitals.spo2}',
                            (val) {
                              final n = int.tryParse(val);
                              if (n != null) {
                                setState(
                                    () => _vitals = _vitals.copyWith(spo2: n));
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 3: Suhu Tubuh & Skala Nyeri (0-10) *
                  Row(
                    children: [
                      Expanded(
                        child: _vitalCard(
                          label: 'Suhu Tubuh',
                          value: _vitals.tempComma,
                          unit: '°C',
                          status: _vitals.tempStatus,
                          boldStatus: true,
                          onTap: () => _editVitalDialog(
                            'Suhu Tubuh (°C)',
                            _vitals.temperatureC.toStringAsFixed(1),
                            (val) {
                              final n = double.tryParse(val.replaceAll(',', '.'));
                              if (n != null) {
                                setState(() => _vitals =
                                    _vitals.copyWith(temperatureC: n));
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: _openPainScaleSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTintSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: hasPain
                                    ? AppColors.primaryBlue
                                    : AppColors.primaryBorder,
                                width: hasPain ? 1.4 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Skala Nyeri (0-10) *',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryBlue,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.info_outline_rounded,
                                        size: 16, color: AppColors.primaryBlue),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (!hasPain) ...[
                                  const Text(
                                    'Sentuh Isi Skala',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryBlue,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Wajib Diisi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '$_painScale / 10',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.navyDark,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '✓ ${_painScale! >= 7 ? "Nyeri Berat (VAS)" : _painScale! >= 4 ? "Nyeri Sedang (VAS)" : "Nyeri Ringan (VAS)"}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Sticky Bottom Button
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
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _verifyAndCalculateIitt,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Verifikasi & Hitung IITT',
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
                    'Data tersimpan otomatis ke rekam medis IGD lokal (Sinkron)',
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

  Widget _vitalCard({
    required String label,
    required String value,
    required String unit,
    required String status,
    required VoidCallback onTap,
    bool highlightedBg = false,
    bool valueBlue = false,
    bool statusBlue = false,
    bool boldStatus = false,
    bool trailingDot = false,
    bool trailingExclamation = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlightedBg ? AppColors.primaryTintSoft : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlightedBg ? AppColors.primaryTint : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: highlightedBg
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingDot)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (trailingExclamation)
                  const Text(
                    '!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: valueBlue ? AppColors.primaryBlue : AppColors.navyDark,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: (statusBlue || boldStatus)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: statusBlue
                    ? AppColors.primaryBlue
                    : boldStatus
                        ? AppColors.navyDark
                        : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

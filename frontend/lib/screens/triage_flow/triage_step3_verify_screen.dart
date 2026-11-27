import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../models/triage_enums.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';
import '../profile/nurse_profile_screen.dart';
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
  State<TriageStep3VerifyScreen> createState() =>
      _TriageStep3VerifyScreenState();
}

class _TriageStep3VerifyScreenState extends State<TriageStep3VerifyScreen> {
  late String _complaint;
  late String _avpu;
  bool _avpuOpen = false;
  late VitalsData _vitals;
  int? _painScale;

  // Which vital card is currently in inline `- / +` edit mode ('td', 'hr', 'rr', 'spo2', 'temp', 'pain', or null)
  String? _editingCard;

  static const List<Map<String, String>> _avpuOptions = [
    {
      'title': 'Sadar Penuh (Alert / A)',
      'desc': 'Sadar penuh, bicara normal',
    },
    {
      'title': 'Respon Suara (Voice / V)',
      'desc': 'Merespons saat dipanggil suara',
    },
    {
      'title': 'Respon Nyeri (Pain / P)',
      'desc': 'Merespons hanya dengan rangsang nyeri',
    },
    {
      'title': 'Tidak Sadar (Unresponsive / U)',
      'desc': 'Pingsan / tidak ada respons (Kritis)',
    },
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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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

  void _verifyAndCalculateIitt() {
    final pain = _painScale ?? 8;
    TriagePriority priority = TriagePriority.green;
    final triggers = <String>[];

    if (_vitals.spo2 < 90 || _avpu.contains('Unresponsive')) {
      priority = TriagePriority.red;
      triggers.add('SpO2 ${_vitals.spo2}% (Oksigen kritis di bawah 90%)');
      triggers.add(
          'Nyeri dada berat & sesak napas (Risiko kardiorespirasi tinggi)');
      triggers.add(
        'RR ${_vitals.respiratoryRate} x/mnt & Nadi ${_vitals.heartRate} x/mnt di atas ambang takikardia/takipnea',
      );
    } else if (_vitals.spo2 < 95 ||
        _vitals.heartRate > 100 ||
        _vitals.respiratoryRate > 24 ||
        pain >= 7) {
      priority = TriagePriority.yellow;
      triggers
          .add('Parameter TTV di luar ambang normal atau nyeri NRS $pain/10');
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

  String _painDesc(int? score) {
    if (score == null) return '! Wajib Diisi Manual';
    if (score >= 9) return '✓ Nyeri Sangat Berat';
    if (score >= 7) return '✓ Nyeri Berat (VAS)';
    if (score >= 5) return '✓ Nyeri Sedang (VAS)';
    if (score >= 3) return '✓ Nyeri Ringan-Sedang';
    return '✓ Nyeri Ringan (VAS)';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.draftPatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VitaStepAppBar(
        title: 'Rekam Suara Triase',
        stepText: 'Langkah 3/4',
        progress: 0.75,
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                  // Custom AVPU Dropdown Card (matching Tingkat Kesadaran AVPU _ Interactive.png)
                  InkWell(
                    onTap: () => setState(() => _avpuOpen = !_avpuOpen),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _avpuOpen
                              ? AppColors.primaryBlue
                              : AppColors.borderLight,
                          width: _avpuOpen ? 1.6 : 1,
                        ),
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
                          const SizedBox(height: 6),
                          Row(
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
                                  _avpu,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ),
                              Icon(
                                _avpuOpen
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_avpuOpen) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primaryBlue),
                      ),
                      child: Column(
                        children: _avpuOptions.map((opt) {
                          final isSelected = opt['title'] == _avpu;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _avpu = opt['title']!;
                                _avpuOpen = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryTintSoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primaryDeep
                                              : AppColors.navyDark,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        opt['title']!,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? AppColors.primaryDeep
                                              : AppColors.navyDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 16, top: 2),
                                    child: Text(
                                      opt['desc']!,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
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
                  ],
                  const SizedBox(height: 18),
                  // Section 2: TANDA VITAL (6 Parameter Klinis with Inline - / + Stepper)
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
                        child: _interactiveVitalCard(
                          cardKey: 'td',
                          label: 'Tekanan Darah',
                          value: _vitals.bpValue,
                          unit: 'mmHg',
                          status: _vitals.bpStatus,
                          onDecrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  systolicBp:
                                      (_vitals.systolicBp - 5).clamp(60, 240),
                                  diastolicBp:
                                      (_vitals.diastolicBp - 5).clamp(40, 140))),
                          onIncrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  systolicBp:
                                      (_vitals.systolicBp + 5).clamp(60, 240),
                                  diastolicBp:
                                      (_vitals.diastolicBp + 5).clamp(40, 140))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _interactiveVitalCard(
                          cardKey: 'hr',
                          label: 'Frekuensi Nadi',
                          value: '${_vitals.heartRate}',
                          unit: 'x/mnt',
                          status: _vitals.hrStatus,
                          statusBlue: true,
                          onDecrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  heartRate:
                                      (_vitals.heartRate - 2).clamp(30, 220))),
                          onIncrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  heartRate:
                                      (_vitals.heartRate + 2).clamp(30, 220))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2: RR & SpO2
                  Row(
                    children: [
                      Expanded(
                        child: _interactiveVitalCard(
                          cardKey: 'rr',
                          label: 'Pernapasan (RR)',
                          value: '${_vitals.respiratoryRate}',
                          unit: 'x/mnt',
                          status: _vitals.rrStatus,
                          statusBlue: true,
                          onDecrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  respiratoryRate:
                                      (_vitals.respiratoryRate - 1)
                                          .clamp(8, 60))),
                          onIncrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  respiratoryRate:
                                      (_vitals.respiratoryRate + 1)
                                          .clamp(8, 60))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _interactiveVitalCard(
                          cardKey: 'spo2',
                          label: 'Saturasi O2 (SpO2)',
                          value: '${_vitals.spo2}%',
                          unit: '',
                          status: _vitals.spo2Status,
                          highlightedBg: true,
                          valueBlue: true,
                          statusBlue: true,
                          onDecrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  spo2: (_vitals.spo2 - 1).clamp(70, 100))),
                          onIncrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  spo2: (_vitals.spo2 + 1).clamp(70, 100))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 3: Suhu Tubuh & Skala Nyeri (0-10) *
                  Row(
                    children: [
                      Expanded(
                        child: _interactiveVitalCard(
                          cardKey: 'temp',
                          label: 'Suhu Tubuh',
                          value: _vitals.tempComma,
                          unit: '°C',
                          status: _vitals.tempStatus,
                          onDecrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  temperatureC: ((_vitals.temperatureC - 0.1)
                                      .clamp(34.0, 42.0)))),
                          onIncrement: () => setState(() => _vitals = _vitals
                              .copyWith(
                                  temperatureC: ((_vitals.temperatureC + 0.1)
                                      .clamp(34.0, 42.0)))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _interactiveVitalCard(
                          cardKey: 'pain',
                          label: 'Skala Nyeri (0-10) *',
                          value: _painScale == null
                              ? 'Sentuh Isi Skala'
                              : '$_painScale / 10',
                          unit: '',
                          status: _painDesc(_painScale),
                          highlightedBg: true,
                          valueBlue: true,
                          statusBlue: true,
                          compactValue: _painScale == null,
                          onStartEdit: () {
                            setState(() {
                              _painScale ??= 8;
                              _editingCard = 'pain';
                            });
                          },
                          onDecrement: () => setState(() => _painScale =
                              ((_painScale ?? 8) - 2).clamp(0, 10)),
                          onIncrement: () => setState(() => _painScale =
                              ((_painScale ?? 8) + 2).clamp(0, 10)),
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

  Widget _interactiveVitalCard({
    required String cardKey,
    required String label,
    required String value,
    required String unit,
    required String status,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    VoidCallback? onStartEdit,
    bool highlightedBg = false,
    bool valueBlue = false,
    bool statusBlue = false,
    bool compactValue = false,
  }) {
    final isEditing = _editingCard == cardKey;

    return InkWell(
      onTap: isEditing
          ? null
          : (onStartEdit ?? () => setState(() => _editingCard = cardKey)),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (highlightedBg || isEditing)
              ? AppColors.primaryTintSoft
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: (highlightedBg || isEditing)
                ? AppColors.primaryBlue
                : AppColors.borderLight,
            width: isEditing ? 1.8 : 1.1,
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
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: (highlightedBg || isEditing)
                          ? AppColors.primaryDeep
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    if (isEditing) {
                      setState(() => _editingCard = null);
                    } else if (onStartEdit != null) {
                      onStartEdit();
                    } else {
                      setState(() => _editingCard = cardKey);
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isEditing ? AppColors.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isEditing
                            ? AppColors.primaryBlue
                            : AppColors.primaryBorder,
                      ),
                    ),
                    child: Icon(
                      isEditing ? Icons.check_rounded : Icons.edit_outlined,
                      size: 14,
                      color: isEditing ? Colors.white : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isEditing)
              Row(
                children: [
                  _stepperBtn('−', onDecrement),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.navyDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  _stepperBtn('+', onIncrement),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: compactValue ? 15 : 20,
                        fontWeight: FontWeight.w900,
                        color: valueBlue
                            ? AppColors.primaryDeep
                            : AppColors.navyDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 6),
            Text(
              status,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: statusBlue ? FontWeight.w700 : FontWeight.w500,
                color: statusBlue
                    ? AppColors.primaryBlue
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

  Widget _stepperBtn(String symbol, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryBlue, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Text(
          symbol,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryDeep,
          ),
        ),
      ),
    );
  }
}

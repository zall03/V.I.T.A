import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/triage_enums.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';
import '../profile/nurse_profile_screen.dart';
import 'triage_step2_voice_screen.dart';

class TriageStep1InfoScreen extends StatefulWidget {
  final TriageProvider provider;

  const TriageStep1InfoScreen({super.key, required this.provider});

  @override
  State<TriageStep1InfoScreen> createState() => _TriageStep1InfoScreenState();
}

class _TriageStep1InfoScreenState extends State<TriageStep1InfoScreen> {
  final _nameController = TextEditingController();
  String _gender = 'Laki-laki';
  IITTAgeGroup _ageGroup = IITTAgeGroup.adult;
  String _incidentCategory = 'Non-Trauma';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _proceedToVoice() {
    final queueNum = widget.provider.nextQueueNumber;
    final age = _ageGroup == IITTAgeGroup.adult ? 45 : 8;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TriageStep2VoiceScreen(
          provider: widget.provider,
          queueNumber: queueNum,
          patientName: _nameController.text.trim().isEmpty
              ? 'Pasien $queueNum'
              : _nameController.text.trim(),
          gender: _gender,
          ageYears: age,
          ageGroup: _ageGroup,
          caseType: _incidentCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueNum = widget.provider.nextQueueNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VitaStepAppBar(
        title: 'Triase Baru',
        stepText: 'LANGKAH 1/4',
        uppercaseStep: true,
        progress: 0.25,
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LANGKAH 1 DARI 4 (25%)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDeep,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Sistem Siap',
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
                  const SizedBox(height: 8),
                  const Text(
                    'Informasi Awal Pasien',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih kategori usia pasien lalu tekan tombol rekam suara.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ID DARURAT OTOMATIS
                  const Text(
                    'ID DARURAT OTOMATIS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTintSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            color: AppColors.primaryDeep, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Pasien $queueNum',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Text(
                              'Otomatis dibuat oleh sistem',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // NAMA / NIK (OPSIONAL)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NAMA / NIK (OPSIONAL)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Bisa Menyusul',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Kosongkan jika kondisi darurat',
                      hintStyle: const TextStyle(
                          color: AppColors.textSubtle, fontSize: 14),
                      suffixIcon: const Icon(Icons.emergency_outlined,
                          size: 18, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          size: 15, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bisa diisi belakangan oleh petugas admisi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // JENIS KELAMIN (Segmented Control matching halaman tambah triase - Laki-laki & Pediatrik.png)
                  const Text(
                    'JENIS KELAMIN',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child:
                                _genderSegment('Laki-laki', Icons.male_rounded)),
                        const SizedBox(width: 4),
                        Expanded(
                            child: _genderSegment(
                                'Perempuan', Icons.female_rounded)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // KELOMPOK USIA (PROTOKOL IITT) *
                  const Text(
                    'KELOMPOK USIA (PROTOKOL IITT) *',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ageGroupCard(
                          group: IITTAgeGroup.adult,
                          title: 'DEWASA',
                          range: '≥ 12 Tahun',
                          desc: 'Protokol Dewasa',
                          scoreLabel: 'Skor MEWS / ATS\nDewasa',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ageGroupCard(
                          group: IITTAgeGroup.pediatric,
                          title: 'ANAK',
                          range: '< 12 Tahun',
                          desc: 'Protokol Anak',
                          scoreLabel: 'Skor PEWS Anak',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // KATEGORI INSIDEN CEPAT (OPSIONAL) (matching Kategori Insiden Cepat _ Interactive.png)
                  const Text(
                    'KATEGORI INSIDEN CEPAT (OPSIONAL)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _incidentChip(
                          'Trauma Berat', Icons.personal_injury_outlined),
                      _incidentChip(
                          'Non-Trauma', Icons.monitor_heart_outlined),
                      _incidentChip(
                          'Rujukan Luar', Icons.local_hospital_outlined),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Sticky Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _proceedToVoice,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic_none_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Lanjut ke Rekam Suara',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderSegment(String label, IconData icon) {
    final isSelected = _gender == label;
    return InkWell(
      onTap: () => setState(() => _gender = label),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.navyDark,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.navyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ageGroupCard({
    required IITTAgeGroup group,
    required String title,
    required String range,
    required String desc,
    required String scoreLabel,
  }) {
    final isSelected = _ageGroup == group;
    return InkWell(
      onTap: () => setState(() => _ageGroup = group),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTintSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryDeep : AppColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColors.primaryDeep
                        : AppColors.textSecondary,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 20,
                  color:
                      isSelected ? AppColors.primaryDeep : AppColors.border,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              range,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color:
                    isSelected ? AppColors.primaryDeep : AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const Divider(height: 20, color: AppColors.borderLight),
            Text(
              scoreLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primaryDeep
                    : AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incidentChip(String label, IconData icon) {
    final isSelected = _incidentCategory == label;
    return InkWell(
      onTap: () => setState(() => _incidentCategory = label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDeep : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryDeep : AppColors.navyDark,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.primaryBlue,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.navyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

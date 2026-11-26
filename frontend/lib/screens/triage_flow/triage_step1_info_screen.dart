import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/triage_enums.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';
import 'triage_step2_voice_screen.dart';

class TriageStep1InfoScreen extends StatefulWidget {
  final TriageProvider provider;

  const TriageStep1InfoScreen({super.key, required this.provider});

  @override
  State<TriageStep1InfoScreen> createState() => _TriageStep1InfoScreenState();
}

class _TriageStep1InfoScreenState extends State<TriageStep1InfoScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '45');
  String _gender = 'Laki-laki';
  IITTAgeGroup _ageGroup = IITTAgeGroup.adult;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _proceedToVoice() {
    final queueNum = widget.provider.nextQueueNumber;
    final age = int.tryParse(_ageController.text.trim()) ??
        (_ageGroup == IITTAgeGroup.adult ? 45 : 8);

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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueNum = widget.provider.nextQueueNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const VitaStepAppBar(
        title: 'Triase Baru',
        stepText: 'LANGKAH 1/4',
        uppercaseStep: true,
        progress: 0.25,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Header Row
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
                          horizontal: 10,
                          vertical: 5,
                        ),
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
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: 18),
                  // Automatic Emergency ID Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTintSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.primaryDeep,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ID DARURAT OTOMATIS',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pasien $queueNum',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              const Text(
                                'Otomatis dibuat oleh sistem',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Kelompok Usia (Protokol IITT)
                  const Row(
                    children: [
                      Text(
                        'KELOMPOK USIA (PROTOKOL IITT)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ageGroupCard(
                          group: IITTAgeGroup.pediatric,
                          title: 'ANAK',
                          range: '< 12 Tahun',
                          desc: 'Protokol Pediatrik',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Jenis Kelamin
                  const Text(
                    'JENIS KELAMIN',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _genderButton('Laki-laki', Icons.male_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _genderButton('Perempuan', Icons.female_rounded)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Nama / NIK (Opsional) + Usia
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'NAMA / NIK (OPSIONAL)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bisa Menyusul',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Kosongkan jika kondisi darurat',
                      hintStyle: const TextStyle(color: AppColors.textSubtle, fontSize: 13.5),
                      filled: true,
                      fillColor: AppColors.inputFill,
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
                        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Perkiraan Usia (Tahun)',
                      filled: true,
                      fillColor: AppColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sticky Bottom Button (matching halaman tambah triase.png)
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
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

  Widget _ageGroupCard({
    required IITTAgeGroup group,
    required String title,
    required String range,
    required String desc,
  }) {
    final isSelected = _ageGroup == group;
    return InkWell(
      onTap: () {
        setState(() {
          _ageGroup = group;
          _ageController.text = group == IITTAgeGroup.adult ? '45' : '8';
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border,
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppColors.primaryDeep : AppColors.textSecondary,
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 18,
                  color: isSelected ? AppColors.primaryBlue : AppColors.textSubtle,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              range,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderButton(String label, IconData icon) {
    final isSelected = _gender == label;
    return InkWell(
      onTap: () => setState(() => _gender = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTint : AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primaryDeep : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.navyDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

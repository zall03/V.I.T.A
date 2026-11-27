import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../models/triage_enums.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';
import '../../widgets/waveform_visualizer.dart';
import '../profile/nurse_profile_screen.dart';
import 'triage_step3_verify_screen.dart';

class TriageStep2VoiceScreen extends StatefulWidget {
  final TriageProvider provider;
  final String queueNumber;
  final String patientName;
  final String gender;
  final int ageYears;
  final IITTAgeGroup ageGroup;
  final String caseType;

  const TriageStep2VoiceScreen({
    super.key,
    required this.provider,
    required this.queueNumber,
    required this.patientName,
    required this.gender,
    required this.ageYears,
    required this.ageGroup,
    this.caseType = 'Non-Trauma',
  });

  @override
  State<TriageStep2VoiceScreen> createState() => _TriageStep2VoiceScreenState();
}

class _TriageStep2VoiceScreenState extends State<TriageStep2VoiceScreen> {
  bool _isRecording = false;
  bool _isEditMode = false;
  int _elapsedSeconds = 24;
  Timer? _timer;

  late final TextEditingController _transcriptController;

  static const String _partialRecordingTranscript =
      '“Pasien laki-laki 45 tahun, keluhan nyeri dada berat menjalar ke lengan kiri dan sesak napas sejak 30 menit lalu...”';

  @override
  void initState() {
    super.initState();
    _transcriptController = TextEditingController(
      text:
          '“Pasien laki-laki 45 tahun, keluhan nyeri dada berat menjalar ke lengan kiri dan sesak napas sejak 30 menit lalu. Tensi 150 per 95, nadi 118, RR 28, saturasi oksigen 89 persen, suhu 36,8, kesadaran sadar penuh.”',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _transcriptController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    if (_isEditMode) {
      setState(() => _isEditMode = false);
      _startRecording();
      return;
    }
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _startRecording() {
    _timer?.cancel();
    setState(() {
      _isEditMode = false;
      _isRecording = true;
      _elapsedSeconds = 9;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      if (_elapsedSeconds < 12) _elapsedSeconds = 24;
    });
  }

  void _toggleInlineEditMode() {
    if (_isRecording) _stopRecording();
    setState(() {
      _isEditMode = !_isEditMode;
    });
    if (!_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan teks transkripsi disimpan.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _extractToForm() {
    final draft = PatientTriage(
      id: widget.queueNumber.replaceAll('#', ''),
      queueNumber: widget.queueNumber,
      name: widget.patientName,
      ageYears: widget.ageYears,
      gender: widget.gender,
      ageGroup: widget.ageGroup,
      caseType: widget.caseType,
      arrivalTime: 'Baru saja',
      priority: TriagePriority.red,
      chiefComplaint:
          'Nyeri dada berat menjalar ke lengan kiri & sesak napas (30 mnt)',
      painScaleNrs: null,
      isOfflineArchive: !widget.provider.isOnline,
      originalTranscript: _transcriptController.text.trim(),
      objectiveTriggers: const [
        'SpO2 89% (Oksigen kritis di bawah 90%)',
        'Nyeri dada berat & sesak napas (Risiko kardiorespirasi tinggi)',
        'RR 28 x/mnt & Nadi 118 x/mnt di atas ambang takikardia/takipnea',
      ],
      vitals: VitalsData(
        systolicBp: 150,
        diastolicBp: 95,
        heartRate: 118,
        respiratoryRate: 28,
        spo2: 89,
        temperatureC: 36.8,
        avpu: 'Sadar Penuh (Alert / A)',
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TriageStep3VerifyScreen(
          provider: widget.provider,
          draftPatient: draft,
        ),
      ),
    );
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VitaStepAppBar(
        title: 'Rekam Suara Triase',
        stepText: 'Langkah 2/4',
        progress: 0.50,
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
          // Top Offline STT + Gemini NER status bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(
                  child: Text(
                    '🎙 Offline STT (Noise Filter IGD)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording
                      ? '🎙 Sedang Merekam Suara...'
                      : '✨ Google Gemini NER (4/4)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Patient Info Card
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
                            Row(
                              children: [
                                const Icon(Icons.badge_outlined,
                                    size: 18, color: AppColors.primaryDeep),
                                const SizedBox(width: 6),
                                Text(
                                  'Pasien ${widget.queueNumber}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isEditMode
                                    ? '✓ Rekaman Selesai'
                                    : 'Menunggu Ekstraksi',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.gender}, ${widget.ageGroup.label}  •  Kasus Darurat ${widget.caseType}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Real-time Transcription Card (supports Inline Edit Mode matching Mode Edit Teks.png)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isEditMode
                          ? AppColors.primaryTintSoft
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isEditMode
                            ? AppColors.primaryBlue
                            : AppColors.borderLight,
                        width: _isEditMode ? 1.8 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.record_voice_over_outlined,
                                      size: 19, color: AppColors.primaryDeep),
                                  SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Transkripsi Suara (Real-time)',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.navyDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _isEditMode
                                    ? AppColors.primaryDeep
                                    : AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isEditMode
                                    ? '• ✎ MODE EDIT TEKS'
                                    : _isRecording
                                        ? '• REC ${_formatTime(_elapsedSeconds)}'
                                        : '• SELESAI ${_formatTime(_elapsedSeconds)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_isEditMode)
                          TextField(
                            controller: _transcriptController,
                            autofocus: true,
                            maxLines: 6,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        else
                          InkWell(
                            onTap: _toggleInlineEditMode,
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isRecording
                                      ? _partialRecordingTranscript
                                      : _transcriptController.text,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                                if (_isRecording) ...[
                                  const SizedBox(height: 14),
                                  const Text(
                                    '[Sebutkan Tensi, Nadi, RR, SpO2, Suhu...]',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ENTITAS KLINIS TERDETEKSI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.4,
                              ),
                            ),
                            Text(
                              _isRecording
                                  ? 'Mengekstrak via Gemini AI...'
                                  : '4 Kriteria',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _entityChip(Icons.monitor_heart_outlined,
                                'Nyeri Dada Menjalar',
                                dimmed: false),
                            _entityChip(Icons.warning_amber_rounded,
                                'SpO2 89% (Hipoksia)',
                                dimmed: _isRecording),
                            _entityChip(Icons.speed_rounded, 'TD 150/95',
                                dimmed: _isRecording),
                            _entityChip(
                                Icons.show_chart_rounded, 'Nadi 118 bpm',
                                dimmed: _isRecording),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: _isEditMode
                                  ? AppColors.primaryDeep
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _isEditMode
                                    ? '✓ Teks transkripsi sedang diedit • Klik \'Simpan Teks\' di bawah.'
                                    : 'Ketuk teks di atas jika ada kata yang ingin diperbaiki.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _isEditMode
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: _isEditMode
                                      ? AppColors.primaryDeep
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          // Bottom PTT Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (_isEditMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        15,
                        (_) => Container(
                          width: 4,
                          height: 10,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    )
                  else
                    WaveformVisualizer(
                      animate: _isRecording,
                      barCount: 15,
                      maxHeight: 34,
                      barWidth: 4,
                      spacing: 4,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditMode
                        ? '⏸ ${_formatTime(_elapsedSeconds)} • Mikrofon Nonaktif (Rekaman Selesai)'
                        : '${_formatTime(_elapsedSeconds)} • Sensitivitas Mikrofon Optimal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    onTap: _toggleRecording,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 78 : 72,
                      height: _isRecording ? 78 : 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isEditMode
                            ? Colors.white
                            : AppColors.primaryDeep,
                        border: _isEditMode
                            ? Border.all(
                                color: AppColors.primaryDeep, width: 2.2)
                            : null,
                        boxShadow: _isEditMode
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(
                                    alpha: _isRecording ? 0.45 : 0.22,
                                  ),
                                  blurRadius: _isRecording ? 20 : 12,
                                  spreadRadius: _isRecording ? 4 : 0,
                                ),
                              ],
                      ),
                      child: Icon(
                        Icons.mic_none_rounded,
                        color: _isEditMode
                            ? AppColors.primaryDeep
                            : Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isEditMode
                        ? 'Mikrofon Nonaktif (Ketuk untuk Rekam Ulang)'
                        : _isRecording
                            ? 'Sedang Merekam Suara Perawat...'
                            : 'Tahan untuk Bicara',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  if (!_isEditMode) ...[
                    const SizedBox(height: 2),
                    Text(
                      _isRecording
                          ? 'Ketuk Mikrofon jika Selesai Bicara'
                          : 'Lepas untuk menyelesaikan audio',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _isEditMode
                            ? SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.primaryTintSoft,
                                    side: const BorderSide(
                                        color: AppColors.primaryBlue,
                                        width: 1.5),
                                  ),
                                  onPressed: _toggleInlineEditMode,
                                  icon: const Icon(Icons.edit_note_rounded,
                                      size: 20, color: AppColors.navyDark),
                                  label: const Text(
                                    '✓ Simpan Teks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                                ),
                              )
                            : TextButton.icon(
                                onPressed: _toggleInlineEditMode,
                                icon: const Icon(Icons.edit_note_rounded,
                                    color: AppColors.navyDark, size: 20),
                                label: const Text(
                                  'Edit Teks',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDeep,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _extractToForm,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Ekstrak ke Form',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(Icons.arrow_forward_rounded, size: 18),
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
        ],
      ),
    );
  }

  Widget _entityChip(IconData icon, String label, {bool dimmed = false}) {
    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.primaryDeep),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

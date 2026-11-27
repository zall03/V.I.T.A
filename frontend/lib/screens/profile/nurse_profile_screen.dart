import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/triage_provider.dart';
import '../auth/login_screen.dart';

class NurseProfileScreen extends StatefulWidget {
  final TriageProvider provider;

  const NurseProfileScreen({super.key, required this.provider});

  @override
  State<NurseProfileScreen> createState() => _NurseProfileScreenState();
}

class _NurseProfileScreenState extends State<NurseProfileScreen> {
  bool _isEditMode = false;
  late String _draftShift;
  late String _draftZone;
  late String _draftMic;

  @override
  void initState() {
    super.initState();
    _draftShift = widget.provider.selectedShift;
    _draftZone = widget.provider.assignedZone;
    _draftMic = widget.provider.phoneAndMic;
  }

  void _cycleOption(List<String> list, String current, ValueChanged<String> onSet) {
    final idx = list.indexOf(current);
    final next = list[(idx + 1) % list.length];
    setState(() => onSet(next));
  }

  void _saveChanges() {
    widget.provider.updateNurseProfile(
      shift: _draftShift,
      zone: _draftZone,
      phoneAndMic: _draftMic,
    );
    setState(() => _isEditMode = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil & Tugas IGD berhasil diperbarui.'),
        backgroundColor: AppColors.primaryDeep,
      ),
    );
  }

  void _endShift() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(provider: widget.provider),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.provider,
      builder: (context, _) {
        final p = widget.provider;

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
            title: const Text(
              'Profil Perawat IGD',
              style: TextStyle(
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Top Nurse Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isEditMode
                                ? AppColors.primaryBlue
                                : AppColors.border,
                            width: _isEditMode ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    ClipOval(
                                      child: Image.asset(
                                        'assets/images/profil.png',
                                        width: 68,
                                        height: 68,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 2,
                                      bottom: 2,
                                      child: Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.nurseFullName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p.nurseRole,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryTintSoft,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color:
                                                      AppColors.primaryBorder),
                                            ),
                                            child: Text(
                                              'ID: ${p.nurseId}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primaryDeep,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceSubtle,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: AppColors.border),
                                            ),
                                            child: const Text(
                                              '✓ STR & SIP Aktif',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primaryBlue,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 26, color: AppColors.borderLight),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _metricCol(
                                      '${p.totalActiveCount + 11} Pasien',
                                      'Triase Shift Ini'),
                                ),
                                Expanded(
                                  child:
                                      _metricCol('34 Detik', 'Rata-rata Triase'),
                                ),
                                Expanded(
                                  child:
                                      _metricCol('100% Valid', 'Kepatuhan IITT'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Data Tugas & Perangkat IGD Card (matching Kartu Profil Perawat _ Interactive.png)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _isEditMode
                                ? AppColors.primaryBlue
                                : AppColors.border,
                            width: _isEditMode ? 1.6 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _isEditMode
                                        ? '✎ MODE EDIT PROFIL & TUGAS IGD'
                                        : p.profileUpdated
                                            ? '✓ PROFIL & TUGAS IGD (DIPERBARUI)'
                                            : '📋 DATA TUGAS & PERANGKAT IGD',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: (_isEditMode || p.profileUpdated)
                                          ? AppColors.primaryDeep
                                          : AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_isEditMode)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 34),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: _saveChanges,
                                    child: const Text(
                                      '✓ Simpan',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  )
                                else
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 34),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _draftShift = p.selectedShift;
                                        _draftZone = p.assignedZone;
                                        _draftMic = p.phoneAndMic;
                                        _isEditMode = true;
                                      });
                                    },
                                    child: const Text(
                                      '✎ Edit Data',
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _fieldBox(
                              label: 'NAMA LENGKAP & GELAR KLINIS',
                              value: '${p.nurseFullName} (${p.nurseId})',
                              editable: false,
                            ),
                            const SizedBox(height: 14),
                            _fieldBox(
                              label: 'SHIFT JAGA IGD AKTIF',
                              value: _isEditMode ? _draftShift : p.selectedShift,
                              editable: _isEditMode,
                              onTap: _isEditMode
                                  ? () => _cycleOption(
                                        TriageProvider.shiftOptions,
                                        _draftShift,
                                        (v) => _draftShift = v,
                                      )
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _fieldBox(
                              label: 'ZONA PENUGASAN TRIASE IGD',
                              value: _isEditMode ? _draftZone : p.assignedZone,
                              editable: _isEditMode,
                              onTap: _isEditMode
                                  ? () => _cycleOption(
                                        TriageProvider.zoneOptions,
                                        _draftZone,
                                        (v) => _draftZone = v,
                                      )
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _fieldBox(
                              label: 'NOMOR TELEPON DARURAT IGD & AI MIC',
                              value: _isEditMode ? _draftMic : p.phoneAndMic,
                              editable: _isEditMode,
                              onTap: _isEditMode
                                  ? () => _cycleOption(
                                        TriageProvider.micOptions,
                                        _draftMic,
                                        (v) => _draftMic = v,
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Action Buttons
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
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_rounded,
                                    size: 18),
                                label: const Text('Antrean IGD'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: _endShift,
                                child: const Text('Akhiri Shift (Keluar)'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sesi Perawat Terenkripsi • V.I.T.A. Clinical OS v2.4',
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
      },
    );
  }

  Widget _metricCol(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDeep,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _fieldBox({
    required String label,
    required String value,
    required bool editable,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: editable ? AppColors.primaryTintSoft : AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: editable ? AppColors.primaryBlue : AppColors.border,
                width: editable ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: editable ? AppColors.primaryDeep : AppColors.navyDark,
                    ),
                  ),
                ),
                if (editable) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

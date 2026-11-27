import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';
import '../profile/nurse_profile_screen.dart';

class SatusehatFhirScreen extends StatefulWidget {
  final TriageProvider provider;
  final PatientTriage patient;

  const SatusehatFhirScreen({
    super.key,
    required this.provider,
    required this.patient,
  });

  @override
  State<SatusehatFhirScreen> createState() => _SatusehatFhirScreenState();
}

class _SatusehatFhirScreenState extends State<SatusehatFhirScreen> {
  int _selectedTab = 0; // 0: Paket (3), 1: Pasien, 2: Kunjungan, 3: Tanda Vital (6)
  late bool _isSentSuccess;

  @override
  void initState() {
    super.initState();
    _isSentSuccess = widget.patient.satusehatSynced;
  }

  String _titleForTab(int tab) {
    final p = widget.patient;
    switch (tab) {
      case 0:
        return 'Paket Gabungan (Bundle IGD ${p.queueNumber})';
      case 1:
        return 'Data Identitas Pasien (Patient)';
      case 2:
        return 'Kunjungan IGD (Encounter)';
      default:
        return 'Hasil Tanda Vital (Observation)';
    }
  }

  String _subtitleForTab(int tab) {
    final p = widget.patient;
    switch (tab) {
      case 0:
        return '🕒 Selesai: ${p.verifiedAt}  •  ✓ Gabungan 3 Data Medis • Validasi 100%';
      case 1:
        return '🕒 Tercatat: ${p.verifiedAt}  •  ✓ NIK Terverifikasi Dukcapil';
      case 2:
        return '🕒 Tercatat: ${p.verifiedAt}  •  ✓ ${p.bedLabel} • ${p.priority.levelText}';
      default:
        return '🕒 Selesai: ${p.verifiedAt}  •  ✓ 6 Parameter Fisik • Standar Kemenkes';
    }
  }

  String _buildJsonForTab(int tab) {
    final p = widget.patient;
    late final Map<String, dynamic> payload;

    switch (tab) {
      case 0:
        payload = {
          "jenisDokumen": "PaketPengiriman (Bundle)",
          "idPaket": "paket-triase-igd-${p.id}",
          "waktuKirim": "2026-11-26 ${p.verifiedAt}",
          "isiPaket": [
            {
              "dokumen_1": "Data Pasien (Patient)",
              "id": "Pasien/${p.id} – ${p.name} (${p.ageYears} th)"
            },
            {
              "dokumen_2": "Kunjungan IGD (Encounter)",
              "id": "Kunjungan/IGD-${p.id} – ${p.bedLabel}"
            },
            {
              "dokumen_3": "Tanda Vital (Observation)",
              "id": "TandaVital/${p.id} – 6 Pemeriksaan Fisik"
            }
          ],
          "tujuanServer": "SATUSEHAT Kemenkes RI"
        };
        break;
      case 1:
        payload = {
          "resourceType": "Patient",
          "id": p.id,
          "identifier": [
            {
              "system": "https://fhir.kemkes.go.id/id/nik",
              "value": "3209150408810002"
            }
          ],
          "name": [
            {"text": p.name}
          ],
          "gender": p.gender.contains('Perempuan') ? 'female' : 'male',
          "ageGroupIITT": p.ageGroup.code,
        };
        break;
      case 2:
        payload = {
          "resourceType": "Encounter",
          "id": "IGD-2026${p.id}",
          "status": p.isCompleted ? "finished" : "in-progress",
          "class": {"code": "EMER", "display": "emergency"},
          "subject": {"reference": "Patient/${p.id}"},
          "location": p.bedLabel,
          "priority": {"text": p.priority.detailBadge},
        };
        break;
      default:
        payload = {
          "jenisDokumen": "HasilTandaVital (Observation)",
          "idPemeriksaan": "vital-igd-${p.id}",
          "idPasien": "Pasien/${p.id} (${p.gender}, ${p.ageYears} th)",
          "statusValidasi": "Terverifikasi Perawat & Dokter IGD",
          "hasilPengukuran": {
            "saturasiOksigen_SpO2": "${p.vitals.spo2}% (${p.vitals.spo2Status})",
            "tekananDarah_TD": "${p.vitals.bpValue} mmHg (${p.vitals.bpStatus})",
            "frekuensiNadi_HR": "${p.vitals.heartRate} x/mnt (${p.vitals.hrStatus})",
            "lajuPernapasan_RR": "${p.vitals.respiratoryRate} x/mnt (${p.vitals.rrStatus})",
            "suhuTubuh": "${p.vitals.tempComma} °C (${p.vitals.tempStatus})",
            "tingkatKesadaran_AVPU": p.vitals.avpu,
          }
        };
    }
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  void _copyJson() {
    Clipboard.setData(ClipboardData(text: _buildJsonForTab(_selectedTab)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payload JSON FHIR R4 berhasil disalin ke clipboard.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _sendToSandbox() {
    widget.provider.markSatusehatSynced(widget.patient.id);
    setState(() => _isSentSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final jsonString = _buildJsonForTab(_selectedTab);
    final byteSize = utf8.encode(jsonString).length;
    final sizeLabel = byteSize >= 1024
        ? '${(byteSize / 1024).toStringAsFixed(2)} KB'
        : '$byteSize BYTES';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VitaStepAppBar(
        title: 'Payload Satusehat Fhir',
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
          // Patient Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.badge_outlined,
                            size: 18, color: AppColors.navyDark),
                      ),
                      const SizedBox(width: 10),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '• ${p.sandboxId}',
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryTintSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data pasien siap dikirim otomatis ke server SATUSEHAT',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Modern Pill Resource Tabs (matching FHIR Resource Viewer _ Interactive_*.png)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _pillTab(0, 'Paket (3)'),
                const SizedBox(width: 8),
                _pillTab(1, 'Pasien'),
                const SizedBox(width: 8),
                _pillTab(2, 'Kunjungan'),
                const SizedBox(width: 8),
                _pillTab(3, 'Tanda Vital (6)'),
              ],
            ),
          ),
          const Divider(height: 12, color: AppColors.borderLight),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSentSuccess) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTintSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primaryBlue, width: 1.4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✓ Berhasil Terkirim ke SATUSEHAT Kemenkes RI',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bundle ID: BND-IGD-${p.id} • Respons: 184 ms • 3/3 Resource Valid\nBebas ketik ulang (Zero Double-Entry) • Antrean IGD diperbarui.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: const Text(
                          '✓ Selesai • Kembali ke Antrean Triase IGD →',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navyDark,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _copyJson,
                              icon: const Icon(Icons.copy_rounded, size: 17),
                              label: const Text('Salin JSON'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _sendToSandbox,
                              icon: const Icon(Icons.cloud_upload_outlined,
                                  size: 18),
                              label: const Text('Kirim Sandbox'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        '• api-satusehat-stg.kemkes.go.id/fhir-r4/v1',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  // Resource Summary Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _titleForTab(_selectedTab),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTintSoft,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: AppColors.primaryBorder),
                              ),
                              child: const Text(
                                'Standar FHIR R4',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16, color: AppColors.borderLight),
                        Text(
                          _subtitleForTab(_selectedTab),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Dark Terminal JSON Code Viewer
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A192F),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF112240),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              _termDot(),
                              const SizedBox(width: 5),
                              _termDot(),
                              const SizedBox(width: 5),
                              _termDot(),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'JSON • UTF-8 • $sizeLabel',
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: _copyJson,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A5F),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy_rounded,
                                          size: 13, color: Color(0xFF38BDF8)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Salin',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF38BDF8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: SelectableText(
                            jsonString,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11.5,
                              color: Color(0xFF93C5FD),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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

  Widget _pillTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTintSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color:
                isSelected ? AppColors.primaryDeep : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _termDot() {
    return Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: Color(0xFF475569),
        shape: BoxShape.circle,
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/vita_step_app_bar.dart';

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
  int _selectedTab = 3; // Default: Observation (matching template)
  late bool _isSentSuccess;

  @override
  void initState() {
    super.initState();
    _isSentSuccess = widget.patient.satusehatSynced;
  }

  String _buildJsonForTab(int tab) {
    final p = widget.patient;
    late final Map<String, dynamic> payload;

    switch (tab) {
      case 0: // Bundle (3)
        payload = {
          "resourceType": "Bundle",
          "id": "BND-IGD-${p.id}",
          "type": "transaction",
          "total": 3,
          "entry": [
            {"fullUrl": "Patient/${p.id}", "resourceType": "Patient"},
            {"fullUrl": "Encounter/IGD-202505", "resourceType": "Encounter"},
            {"fullUrl": "Observation/obs-spo2-${p.id}", "resourceType": "Observation"},
          ]
        };
        break;
      case 1: // Patient
        payload = {
          "resourceType": "Patient",
          "id": p.id,
          "identifier": [
            {"system": "https://fhir.kemkes.go.id/id/nik", "value": "3209150408810002"}
          ],
          "name": [
            {"text": p.name}
          ],
          "gender": p.gender == 'Laki-laki' ? 'male' : 'female',
        };
        break;
      case 2: // Encounter
        payload = {
          "resourceType": "Encounter",
          "id": "IGD-202505",
          "status": "in-progress",
          "class": {"code": "EMER", "display": "emergency"},
          "subject": {"reference": "Patient/${p.id}"},
          "priority": {"text": p.priority.detailBadge},
        };
        break;
      default: // Observation
        payload = {
          "resourceType": "Observation",
          "id": "obs-spo2-${p.id}",
          "status": "final",
          "category": [
            {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                  "code": "vital-signs",
                  "display": "Vital Signs"
                }
              ]
            }
          ],
          "code": {
            "coding": [
              {
                "system": "http://loinc.org",
                "code": "2708-6",
                "display": "Oxygen saturation in Arterial blood"
              }
            ],
            "text": "Saturasi Oksigen (SpO2)"
          },
          "subject": {
            "reference": "Patient/${p.id}",
            "display": "Tn. Pasien ${p.id}"
          },
          "valueQuantity": {
            "value": p.vitals.spo2,
            "unit": "%",
            "system": "http://unitsofmeasure.org",
            "code": "%"
          },
          "interpretation": [
            {
              "coding": [
                {
                  "system": "http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation",
                  "code": "L",
                  "display": "Low"
                }
              ],
              "text": p.vitals.spo2Status
            }
          ]
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const VitaStepAppBar(
        title: 'Payload Satusehat Fhir',
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
          // Resource Tabs (Bundle, Patient, Encounter, Observation)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _resourceTab(0, 'Bundle (3)'),
                _resourceTab(1, 'Patient'),
                _resourceTab(2, 'Encounter'),
                _resourceTab(3, 'Observation', badge: '4 Tanda Vital'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isSentSuccess) ...[
                    // 201 Created Success Card (matching Sandbox 201 Created (Sukses).png)
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
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        child: const Text(
                          '✓ Selesai • Kembali ke Antrean Triase IGD →',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ] else ...[
                    // Idle State Buttons: Salin JSON & Kirim Sandbox
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navyDark,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _copyJson,
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Salin JSON'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
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
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 16),
                  ],
                  // JSON Preview Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFF1E293B)),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HL7 FHIR R4 Ready',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF38BDF8),
                                ),
                              ),
                              Text(
                                'JSON • UTF-8 • Validasi 100%',
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
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
                              color: Color(0xFFE2E8F0),
                              height: 1.45,
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

  Widget _resourceTab(int index, String label, {String? badge}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

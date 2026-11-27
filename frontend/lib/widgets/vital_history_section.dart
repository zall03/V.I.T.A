import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/patient_triage.dart';

class VitalHistorySection extends StatefulWidget {
  final PatientTriage patient;

  const VitalHistorySection({super.key, required this.patient});

  @override
  State<VitalHistorySection> createState() => _VitalHistorySectionState();
}

class _VitalHistorySectionState extends State<VitalHistorySection> {
  bool _showTimeline = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;
    final history = p.vitalHistory.isNotEmpty
        ? p.vitalHistory
        : [
            VitalHistoryEntry(
              timeLabel: '${p.verifiedAt} • Triase Awal Masuk IGD',
              sourceBadge: '🎙 Suara AI VITA',
              vitalsLine:
                  'SpO2: ${p.vitals.spo2}%  •  TD: ${p.vitals.bpValue}  •  Nadi: ${p.vitals.heartRate} x/mnt',
              note: p.chiefComplaint,
              isLatest: true,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    _showTimeline
                        ? Icons.history_toggle_off_rounded
                        : Icons.monitor_heart_outlined,
                    size: 18,
                    color: AppColors.primaryDeep,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _showTimeline
                          ? 'RIWAYAT PENGUKURAN BERKALA'
                          : 'TANDA VITAL TERVALIDASI',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => setState(() => _showTimeline = !_showTimeline),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _showTimeline
                      ? AppColors.primaryBlue
                      : AppColors.primaryTintSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Text(
                  _showTimeline ? '← Angka Terkini' : 'Riwayat Pengukuran →',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _showTimeline ? Colors.white : AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_showTimeline) ...[
          Row(
            children: [
              Expanded(
                child: _vitalTile('Tekanan Darah (TD)', p.vitals.bpValue, 'mmHg',
                    '• ${p.vitals.bpStatus}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _vitalTile('Frekuensi Nadi', '${p.vitals.heartRate}',
                    'x/mnt', '• ${p.vitals.hrStatus}'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _vitalTile('Laju Napas (RR)', '${p.vitals.respiratoryRate}',
                    'x/mnt', '• ${p.vitals.rrStatus}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _vitalTile(
                  'Saturasi O2 (SpO2)',
                  '${p.vitals.spo2}%',
                  'SpO2',
                  '• ${p.vitals.spo2Status}',
                  highlight: p.vitals.spo2 < 94,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _vitalTile('Suhu Tubuh', p.vitals.tempComma, '°C',
                    '• ${p.vitals.tempStatus}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _vitalTile(
                  'Kesadaran (AVPU)',
                  p.vitals.avpu.contains('Alert') ? 'Alert (A)' : 'Terpantau',
                  '',
                  '• ${p.vitals.avpu.split('(').first.trim()}',
                ),
              ),
            ],
          ),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBlue, width: 1.4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTintSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '📈 Pemantauan Berkala Tanda Vital IGD — Pasien ${p.queueNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ...history.map((entry) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: entry.isLatest
                            ? AppColors.primaryTintSoft
                            : AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: entry.isLatest
                              ? AppColors.primaryBlue
                              : AppColors.border,
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
                                  entry.timeLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                entry.sourceBadge,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.vitalsLine,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            entry.note,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _vitalTile(
    String title,
    String value,
    String unit,
    String status, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primaryTintSoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppColors.primaryBlue : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? AppColors.navyDark : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: highlight ? AppColors.primaryBlue : AppColors.navyDark,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            status,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
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

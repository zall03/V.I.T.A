import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/patient_triage.dart';
import '../../models/triage_enums.dart';

class PatientQueueCard extends StatelessWidget {
  final PatientTriage patient;
  final VoidCallback onTap;

  const PatientQueueCard({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left Vertical Blue Accent Bar (matching beranda antrian triase.png)
                Container(
                  width: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(6),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: #042 • Laki-laki, 45 th   🕒 2 mnt lalu
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    patient.queueNumber,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navyDark,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        color: AppColors.textSubtle,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${patient.gender}, ${patient.ageYears} th',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.navyDark,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  patient.arrivalTime,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Chief Complaint
                        Text(
                          patient.chiefComplaint,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Vitals Summary Row
                        _buildVitalsRow(),
                        const SizedBox(height: 14),
                        // Bottom Row: Priority Pill + Chevron
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryTint,
                                borderRadius: BorderRadius.circular(8),
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
                                  const SizedBox(width: 7),
                                  Text(
                                    patient.priority.queueLabel,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVitalsRow() {
    final v = patient.vitals;
    if (patient.priority == TriagePriority.yellow && v.temperatureC >= 38.0) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.thermostat_rounded, size: 16, color: AppColors.navyDark),
              const SizedBox(width: 3),
              const Text('Suhu ', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              Text(
                '${v.tempComma}°C',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          _dot(),
          _vitalText('Nadi', '${v.heartRate}', ' x/m', boldVal: true),
          _dot(),
          _vitalText('SpO2', '${v.spo2}%', '', boldVal: false),
        ],
      );
    }

    if (patient.priority == TriagePriority.green) {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _vitalText('SpO2', '${v.spo2}%', '', boldVal: true),
          _dot(),
          _vitalText('TD', v.bpValue, '', boldVal: true),
          _dot(),
          _vitalText('Nadi', '${v.heartRate}', ' x/m', boldVal: false),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monitor_heart_outlined, size: 16, color: AppColors.navyDark),
            const SizedBox(width: 4),
            const Text('SpO2 ', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            Text(
              '${v.spo2}%',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        _dot(),
        _vitalText('Nadi', '${v.heartRate}', ' x/m', boldVal: true),
        _dot(),
        _vitalText('RR', '${v.respiratoryRate}', ' x/m', highlightBlue: v.respiratoryRate > 24),
      ],
    );
  }

  Widget _dot() {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.textSubtle,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _vitalText(
    String label,
    String value,
    String suffix, {
    bool boldVal = false,
    bool highlightBlue = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: (boldVal || highlightBlue) ? FontWeight.w800 : FontWeight.w500,
            color: highlightBlue ? AppColors.primaryBlue : AppColors.textPrimary,
          ),
        ),
        if (suffix.isNotEmpty)
          Text(
            suffix,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

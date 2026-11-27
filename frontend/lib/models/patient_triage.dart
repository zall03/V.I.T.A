import 'triage_enums.dart';

class VitalHistoryEntry {
  final String timeLabel;
  final String sourceBadge;
  final String vitalsLine;
  final String note;
  final bool isLatest;

  const VitalHistoryEntry({
    required this.timeLabel,
    required this.sourceBadge,
    required this.vitalsLine,
    required this.note,
    this.isLatest = false,
  });
}

class VitalsData {
  int systolicBp;
  int diastolicBp;
  int heartRate;
  int respiratoryRate;
  int spo2;
  double temperatureC;
  String avpu;

  VitalsData({
    required this.systolicBp,
    required this.diastolicBp,
    required this.heartRate,
    required this.respiratoryRate,
    required this.spo2,
    required this.temperatureC,
    required this.avpu,
  });

  String get bpValue => '$systolicBp/$diastolicBp';
  String get tempComma => temperatureC.toStringAsFixed(1).replaceAll('.', ',');

  String get bpStatus => systolicBp >= 140 || diastolicBp >= 90
      ? 'Pre-Hipertensi'
      : systolicBp < 90
          ? 'Hipotensi'
          : 'Normal';

  String get hrStatus => heartRate > 100
      ? 'Takikardia'
      : heartRate < 60
          ? 'Bradikardia'
          : 'Normal';

  String get rrStatus => respiratoryRate > 24
      ? 'Takipnea'
      : respiratoryRate < 12
          ? 'Bradipnea'
          : 'Normal';

  String get spo2Status => spo2 < 90
      ? 'Hipoksia Kritis (AI)'
      : spo2 < 94
          ? 'Hipoksia Sedang'
          : spo2 < 96
              ? 'Batas Bawah'
              : 'Normal (O2)';

  String get tempStatus => temperatureC >= 38.0
      ? 'Febris'
      : temperatureC < 36.0
          ? 'Hipotermia'
          : 'Afebris (Normal)';

  VitalsData copyWith({
    int? systolicBp,
    int? diastolicBp,
    int? heartRate,
    int? respiratoryRate,
    int? spo2,
    double? temperatureC,
    String? avpu,
  }) {
    return VitalsData(
      systolicBp: systolicBp ?? this.systolicBp,
      diastolicBp: diastolicBp ?? this.diastolicBp,
      heartRate: heartRate ?? this.heartRate,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      spo2: spo2 ?? this.spo2,
      temperatureC: temperatureC ?? this.temperatureC,
      avpu: avpu ?? this.avpu,
    );
  }
}

class PatientTriage {
  final String id;
  final String queueNumber;
  final String name;
  final int ageYears;
  final String gender;
  final IITTAgeGroup ageGroup;
  final String caseType;
  final String arrivalTime;
  final String verifiedAt;
  final String verifiedBy;
  final bool nikVerified;
  final bool isOfflineArchive;
  final TriagePriority priority;
  final List<String> objectiveTriggers;
  final String chiefComplaint;
  final int? painScaleNrs;
  final String handlingStatus;
  final bool isCompleted;
  final bool manualOverride;
  final String? overrideReason;
  final bool satusehatSynced;
  final String sandboxId;
  final String originalTranscript;
  final int audioDurationSeconds;
  final String bedLabel;
  final String outcomeSummary;
  final List<VitalHistoryEntry> vitalHistory;
  final VitalsData vitals;

  const PatientTriage({
    required this.id,
    required this.queueNumber,
    required this.name,
    required this.ageYears,
    required this.gender,
    required this.ageGroup,
    required this.arrivalTime,
    required this.priority,
    required this.objectiveTriggers,
    required this.chiefComplaint,
    required this.vitals,
    this.caseType = 'Non-Trauma',
    this.verifiedAt = '13:42 WIB',
    this.verifiedBy = 'NRS-2048 (Ns. S. Rahayu)',
    this.nikVerified = true,
    this.isOfflineArchive = false,
    this.painScaleNrs,
    this.handlingStatus = 'Menunggu Dokter',
    this.isCompleted = false,
    this.manualOverride = false,
    this.overrideReason,
    this.satusehatSynced = false,
    this.sandboxId = 'SB-99412',
    this.originalTranscript =
        '"Pasien laki-laki 45 tahun, nyeri dada berat menjalar ke lengan kiri & sesak napas 30 menit lalu. Tensi 150/95, nadi 118, RR 28, SpO2 89%, suhu 36,8, sadar penuh."',
    this.audioDurationSeconds = 24,
    this.bedLabel = 'Bed Resusitasi 01',
    this.outcomeSummary = 'Selesai Penanganan IGD',
    this.vitalHistory = const [],
  });

  String get painCategoryText {
    final score = painScaleNrs;
    if (score == null) return '! Wajib Diisi Manual';
    if (score >= 9) return 'Nyeri Sangat Berat';
    if (score >= 7) return 'Nyeri Berat (VAS)';
    if (score >= 5) return 'Nyeri Sedang (VAS)';
    if (score >= 3) return 'Nyeri Ringan-Sedang';
    return 'Nyeri Ringan (VAS)';
  }

  PatientTriage copyWith({
    TriagePriority? priority,
    List<String>? objectiveTriggers,
    String? chiefComplaint,
    int? painScaleNrs,
    String? handlingStatus,
    bool? isCompleted,
    bool? isOfflineArchive,
    bool? manualOverride,
    String? overrideReason,
    bool? satusehatSynced,
    String? originalTranscript,
    VitalsData? vitals,
  }) {
    return PatientTriage(
      id: id,
      queueNumber: queueNumber,
      name: name,
      ageYears: ageYears,
      gender: gender,
      ageGroup: ageGroup,
      caseType: caseType,
      arrivalTime: arrivalTime,
      verifiedAt: verifiedAt,
      verifiedBy: verifiedBy,
      nikVerified: nikVerified,
      isOfflineArchive: isOfflineArchive ?? this.isOfflineArchive,
      priority: priority ?? this.priority,
      objectiveTriggers: objectiveTriggers ?? this.objectiveTriggers,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      painScaleNrs: painScaleNrs ?? this.painScaleNrs,
      handlingStatus: handlingStatus ?? this.handlingStatus,
      isCompleted: isCompleted ?? this.isCompleted,
      manualOverride: manualOverride ?? this.manualOverride,
      overrideReason: overrideReason ?? this.overrideReason,
      satusehatSynced: satusehatSynced ?? this.satusehatSynced,
      sandboxId: sandboxId,
      originalTranscript: originalTranscript ?? this.originalTranscript,
      audioDurationSeconds: audioDurationSeconds,
      bedLabel: bedLabel,
      outcomeSummary: outcomeSummary,
      vitalHistory: vitalHistory,
      vitals: vitals ?? this.vitals,
    );
  }
}

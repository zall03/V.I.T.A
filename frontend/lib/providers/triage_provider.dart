import 'package:flutter/material.dart';
import '../models/patient_triage.dart';
import '../models/triage_enums.dart';

class TriageProvider extends ChangeNotifier {
  static const List<String> shiftOptions = [
    'IGD — Shift Pagi (07:00 - 14:00)',
    'IGD — Shift Siang (14:00 - 21:00)',
    'IGD — Shift Malam (21:00 - 07:00)',
  ];

  static const List<String> zoneOptions = [
    'Zona Resusitasi & Triase Utama (Bed 01-04)',
    'Zona Observasi & Resusitasi (Bed 01-06)',
    'Zona Tindakan Akut & Pediatrik (Bed 05-08)',
  ];

  static const List<String> micOptions = [
    '0812-3456-7890 • Peredam Bising AI: Optimal',
    '0812-3456-7890 • Peredam Bising AI: Maksimal',
  ];

  String _selectedShift = shiftOptions.first;
  String _nurseId = 'NRS-2048';
  final String _nurseName = 'Ns. S. Rahayu';
  final String _nurseFullName = 'Ns. Siti Rahayu, S.Kep';
  final String _nurseRole = 'Perawat Triase Ahli • IGD RSUD';
  String _assignedZone = zoneOptions.first;
  String _phoneAndMic = micOptions.first;
  bool _profileUpdated = false;

  ConnectionMode _connectionMode = ConnectionMode.online;
  String _selectedFilter = 'Semua';
  String _historyFilter = 'Selesai';
  int _nextQueueCounter = 43;

  final List<PatientTriage> _patients = [];

  TriageProvider() {
    _seedDummyPatients();
  }

  String get selectedShift => _selectedShift;
  String get nurseId => _nurseId;
  String get nurseName => _nurseName;
  String get nurseFullName => _nurseFullName;
  String get nurseRole => _nurseRole;
  String get assignedZone => _assignedZone;
  String get phoneAndMic => _phoneAndMic;
  bool get profileUpdated => _profileUpdated;

  ConnectionMode get connectionMode => _connectionMode;
  bool get isOnline => _connectionMode == ConnectionMode.online;
  String get selectedFilter => _selectedFilter;
  String get historyFilter => _historyFilter;

  String get nextQueueNumber =>
      '#${_nextQueueCounter.toString().padLeft(3, '0')}';

  void setShift(String shift) {
    _selectedShift = shift;
    notifyListeners();
  }

  void setNurseId(String id) {
    if (id.trim().isNotEmpty) {
      _nurseId = id.trim();
      notifyListeners();
    }
  }

  void updateNurseProfile({
    String? shift,
    String? zone,
    String? phoneAndMic,
  }) {
    if (shift != null) _selectedShift = shift;
    if (zone != null) _assignedZone = zone;
    if (phoneAndMic != null) _phoneAndMic = phoneAndMic;
    _profileUpdated = true;
    notifyListeners();
  }

  void toggleConnectionMode() {
    _connectionMode = _connectionMode == ConnectionMode.online
        ? ConnectionMode.offline
        : ConnectionMode.online;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setHistoryFilter(String filter) {
    _historyFilter = filter;
    notifyListeners();
  }

  List<PatientTriage> get activePatients =>
      _patients.where((p) => !p.isCompleted && !p.isOfflineArchive).toList();

  List<PatientTriage> get historyPatients =>
      _patients.where((p) => p.isCompleted).toList();

  int get totalActiveCount => activePatients.length;
  int get redCount =>
      activePatients.where((p) => p.priority == TriagePriority.red).length;
  int get yellowCount =>
      activePatients.where((p) => p.priority == TriagePriority.yellow).length;
  int get greenCount =>
      activePatients.where((p) => p.priority == TriagePriority.green).length;

  int get historyTotalCount => historyPatients.length;
  int get historyRedCount =>
      historyPatients.where((p) => p.priority == TriagePriority.red).length;
  int get historyYellowCount =>
      historyPatients.where((p) => p.priority == TriagePriority.yellow).length;
  int get historyGreenCount =>
      historyPatients.where((p) => p.priority == TriagePriority.green).length;

  List<PatientTriage> get filteredPatients {
    switch (_selectedFilter) {
      case 'Merah':
        return activePatients
            .where((p) => p.priority == TriagePriority.red)
            .toList();
      case 'Kuning':
        return activePatients
            .where((p) => p.priority == TriagePriority.yellow)
            .toList();
      case 'Hijau':
        return activePatients
            .where((p) => p.priority == TriagePriority.green)
            .toList();
      default:
        return activePatients;
    }
  }

  List<PatientTriage> get filteredHistoryPatients {
    switch (_historyFilter) {
      case 'Merah':
        return historyPatients
            .where((p) => p.priority == TriagePriority.red)
            .toList();
      case 'Kuning':
        return historyPatients
            .where((p) => p.priority == TriagePriority.yellow)
            .toList();
      case 'Hijau':
        return historyPatients
            .where((p) => p.priority == TriagePriority.green)
            .toList();
      default:
        return historyPatients;
    }
  }

  PatientTriage? findById(String id) {
    for (final p in _patients) {
      if (p.id == id) return p;
    }
    return null;
  }

  void addPatient(PatientTriage patient) {
    _patients.insert(0, patient);
    _nextQueueCounter++;
    notifyListeners();
  }

  void updatePatient(PatientTriage updated) {
    final idx = _patients.indexWhere((p) => p.id == updated.id);
    if (idx != -1) {
      _patients[idx] = updated;
      notifyListeners();
    }
  }

  void markHandledByDoctor(String id) {
    final idx = _patients.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _patients[idx] = _patients[idx].copyWith(
        handlingStatus: 'Selesai / Pindah Ruang (ICU)',
        isCompleted: true,
        satusehatSynced: true,
      );
      notifyListeners();
    }
  }

  void markSatusehatSynced(String id) {
    final idx = _patients.indexWhere((p) => p.id == id);
    if (idx != -1) {
      _patients[idx] = _patients[idx].copyWith(satusehatSynced: true);
      notifyListeners();
    }
  }

  void _seedDummyPatients() {
    _patients.addAll([
      PatientTriage(
        id: '042',
        queueNumber: '#042',
        name: 'Tn. Hendra Gunawan',
        ageYears: 45,
        gender: 'Laki-laki',
        ageGroup: IITTAgeGroup.adult,
        arrivalTime: '2 mnt lalu',
        priority: TriagePriority.red,
        chiefComplaint: 'Nyeri dada berat & sesak napas akut',
        painScaleNrs: 8,
        bedLabel: 'Bed Resusitasi 01',
        objectiveTriggers: const [
          'SpO2 89% (Oksigen kritis di bawah 90%)',
          'Nyeri dada berat & sesak napas (Risiko kardiorespirasi tinggi)',
          'RR 28 x/mnt & Nadi 118 x/mnt di atas ambang takikardia/takipnea',
        ],
        vitalHistory: const [
          VitalHistoryEntry(
            timeLabel: '13:42 WIB • Evaluasi Pasca-O2 (Terkini)',
            sourceBadge: '✓ Monitor Bed 01',
            vitalsLine: 'SpO2: 93% (↑)  •  TD: 145/90  •  Nadi: 110 x/mnt',
            note: 'O2 NRM 10 Lpm terpasang oleh Ns. S. Rahayu',
            isLatest: true,
          ),
          VitalHistoryEntry(
            timeLabel: '13:40 WIB • Triase Awal Masuk IGD',
            sourceBadge: '🎙 Suara AI VITA',
            vitalsLine: 'SpO2: 89% (!)  •  TD: 150/95  •  Nadi: 118 x/mnt',
            note: 'Hipoksia kritis & nyeri dada kiri — Prioritas 1 Merah',
          ),
          VitalHistoryEntry(
            timeLabel: '13:25 WIB • Pra-Rumah Sakit (Ambulan)',
            sourceBadge: '🚑 Rujukan Awal',
            vitalsLine: 'SpO2: 90%  •  TD: 155/95  •  Nadi: 120 x/mnt',
            note: 'Keluhan nyeri dada mendadak 30 menit SMRS',
          ),
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
      ),
      PatientTriage(
        id: '041',
        queueNumber: '#041',
        name: 'An. Nabila Putri',
        ageYears: 8,
        gender: 'Perempuan',
        ageGroup: IITTAgeGroup.pediatric,
        arrivalTime: '9 mnt lalu',
        priority: TriagePriority.yellow,
        chiefComplaint: 'Demam tinggi persisten & muntah terus-menerus',
        painScaleNrs: 5,
        bedLabel: 'Bed Observasi Anak 01',
        objectiveTriggers: const [
          'Protokol Pediatrik (< 12 th): Suhu 39,2°C (Febris tinggi)',
          'Nadi 132 x/mnt di atas batas normal usia anak',
          'Risiko dehidrasi akibat muntah persisten',
        ],
        vitals: VitalsData(
          systolicBp: 102,
          diastolicBp: 68,
          heartRate: 132,
          respiratoryRate: 24,
          spo2: 97,
          temperatureC: 39.2,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
      PatientTriage(
        id: '039',
        queueNumber: '#039',
        name: 'Tn. Budi Santoso',
        ageYears: 27,
        gender: 'Laki-laki',
        ageGroup: IITTAgeGroup.adult,
        arrivalTime: '18 mnt lalu',
        priority: TriagePriority.green,
        chiefComplaint: 'Vulnus laceratum (luka robek ringan) antebrachii',
        painScaleNrs: 3,
        bedLabel: 'Bed Tindakan Minor 02',
        objectiveTriggers: const [
          'Seluruh tanda vital dalam batas normal (SpO2 99%, TD 120/80)',
          'Luka robek minor tanpa perdarahan aktif masif',
        ],
        vitals: VitalsData(
          systolicBp: 120,
          diastolicBp: 80,
          heartRate: 76,
          respiratoryRate: 16,
          spo2: 99,
          temperatureC: 36.5,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
      // Seeded History Patients matching halaman riwayat triase (Selesai & SATUSEHAT).png
      PatientTriage(
        id: '036',
        queueNumber: '#036',
        name: 'An. Rafi Pratama',
        ageYears: 6,
        gender: 'Anak Laki-laki',
        ageGroup: IITTAgeGroup.pediatric,
        arrivalTime: 'Selesai 12:40 WIB',
        verifiedAt: '12:40 WIB',
        priority: TriagePriority.yellow,
        chiefComplaint: 'Asma bronkial akut • Nebulisasi Selesai (Pulang)',
        painScaleNrs: 3,
        handlingStatus: 'Selesai / Rawat Jalan (Pulang)',
        isCompleted: true,
        satusehatSynced: true,
        bedLabel: 'Bed Observasi Anak 02',
        outcomeSummary: 'Pasien #036 — Nebulisasi Selesai (Pulang)',
        originalTranscript:
            '"Pasien anak laki-laki 6 tahun, riwayat asma bronkial akut, sesak napas mereda pasca nebulisasi Ventolin. SpO2 naik ke 98%, nadi 104, RR 22, suhu 36,7, sadar penuh."',
        vitalHistory: const [
          VitalHistoryEntry(
            timeLabel: '12:40 WIB • Evaluasi Pasca-Nebulisasi',
            sourceBadge: '✓ Siap Pulang',
            vitalsLine: 'SpO2: 98% (↑)  •  TD: 100/65  •  Nadi: 104 x/mnt',
            note: 'Wheezing minimal, pasien diperbolehkan rawat jalan',
            isLatest: true,
          ),
          VitalHistoryEntry(
            timeLabel: '12:05 WIB • Triase Awal Masuk IGD',
            sourceBadge: '🎙 Suara AI VITA',
            vitalsLine: 'SpO2: 92%  •  RR: 32 x/mnt  •  Nadi: 124 x/mnt',
            note: 'Asma eksaserbasi sedang — Prioritas 2 Kuning',
          ),
        ],
        objectiveTriggers: const [
          'Asma bronkial akut anak dengan respons optimal terhadap nebulisasi',
        ],
        vitals: VitalsData(
          systolicBp: 100,
          diastolicBp: 65,
          heartRate: 104,
          respiratoryRate: 22,
          spo2: 98,
          temperatureC: 36.7,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
      PatientTriage(
        id: '035',
        queueNumber: '#035',
        name: 'Ny. Dina Kartika',
        ageYears: 29,
        gender: 'Perempuan',
        ageGroup: IITTAgeGroup.adult,
        arrivalTime: 'Selesai 12:15 WIB',
        verifiedAt: '12:15 WIB',
        priority: TriagePriority.green,
        chiefComplaint: 'Luka jahit ringan • Rawat Jalan Selesai',
        painScaleNrs: 2,
        handlingStatus: 'Selesai / Rawat Jalan (Pulang)',
        isCompleted: true,
        satusehatSynced: true,
        bedLabel: 'Bed Tindakan Minor 01',
        outcomeSummary: 'Pasien #035 — Rawat Jalan Selesai',
        objectiveTriggers: const [
          'Tindakan hecting minor selesai tanpa komplikasi',
        ],
        vitals: VitalsData(
          systolicBp: 118,
          diastolicBp: 76,
          heartRate: 132,
          respiratoryRate: 18,
          spo2: 97,
          temperatureC: 39.2,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
      PatientTriage(
        id: '034',
        queueNumber: '#034',
        name: 'Tn. Slamet Widodo',
        ageYears: 51,
        gender: 'Laki-laki',
        ageGroup: IITTAgeGroup.adult,
        arrivalTime: 'Selesai 11:45 WIB',
        verifiedAt: '11:45 WIB',
        priority: TriagePriority.green,
        chiefComplaint: 'Kolik abdomen • Observasi & Injeksi Selesai',
        painScaleNrs: 2,
        handlingStatus: 'Selesai / Rawat Jalan (Pulang)',
        isCompleted: true,
        satusehatSynced: true,
        bedLabel: 'Bed Observasi 04',
        outcomeSummary: 'Pasien #034 — Observasi & Injeksi Selesai',
        objectiveTriggers: const [
          'Nyeri abdomen terkendali pasca terapi analgetik IV',
        ],
        vitals: VitalsData(
          systolicBp: 120,
          diastolicBp: 80,
          heartRate: 76,
          respiratoryRate: 16,
          spo2: 99,
          temperatureC: 36.6,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
    ]);
  }
}

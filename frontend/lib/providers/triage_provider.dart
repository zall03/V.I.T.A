import 'package:flutter/material.dart';
import '../models/patient_triage.dart';
import '../models/triage_enums.dart';

class TriageProvider extends ChangeNotifier {
  static const List<String> shiftOptions = [
    'IGD — Shift Pagi (07:00 - 14:00)',
    'IGD — Shift Siang (14:00 - 21:00)',
    'IGD — Shift Malam (21:00 - 07:00)',
  ];

  String _selectedShift = shiftOptions.first;
  String _nurseId = 'NRS-2048';
  final String _nurseName = 'Ns. S. Rahayu';
  ConnectionMode _connectionMode = ConnectionMode.online;
  String _selectedFilter = 'Semua';
  int _nextQueueCounter = 43;

  final List<PatientTriage> _patients = [];

  TriageProvider() {
    _seedDummyPatients();
  }

  String get selectedShift => _selectedShift;
  String get nurseId => _nurseId;
  String get nurseName => _nurseName;
  ConnectionMode get connectionMode => _connectionMode;
  bool get isOnline => _connectionMode == ConnectionMode.online;
  String get selectedFilter => _selectedFilter;

  String get nextQueueNumber => '#${_nextQueueCounter.toString().padLeft(3, '0')}';

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

  List<PatientTriage> get activePatients =>
      _patients.where((p) => !p.isCompleted && !p.isOfflineArchive).toList();

  List<PatientTriage> get historyPatients =>
      _patients.where((p) => p.isCompleted).toList();

  int get totalActiveCount => activePatients.length;
  int get redCount => activePatients.where((p) => p.priority == TriagePriority.red).length;
  int get yellowCount => activePatients.where((p) => p.priority == TriagePriority.yellow).length;
  int get greenCount => activePatients.where((p) => p.priority == TriagePriority.green).length;
  int get offlineArchiveCount => _patients.where((p) => p.isOfflineArchive && !p.isCompleted).length;

  List<PatientTriage> get filteredPatients {
    switch (_selectedFilter) {
      case 'Merah':
        return activePatients.where((p) => p.priority == TriagePriority.red).toList();
      case 'Kuning':
        return activePatients.where((p) => p.priority == TriagePriority.yellow).toList();
      case 'Hijau':
        return activePatients.where((p) => p.priority == TriagePriority.green).toList();
      case 'Arsip Offline':
        return _patients.where((p) => p.isOfflineArchive && !p.isCompleted).toList();
      default:
        return activePatients;
    }
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
        handlingStatus: 'Sudah Ditangani Dokter',
        isCompleted: true,
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
      PatientTriage(
        id: '038',
        queueNumber: '#038',
        name: 'Ny. Ratna Dewi',
        ageYears: 34,
        gender: 'Perempuan',
        ageGroup: IITTAgeGroup.adult,
        arrivalTime: '24 mnt lalu',
        priority: TriagePriority.yellow,
        chiefComplaint: 'Nyeri abdomen kanan bawah & mual sejak pagi',
        painScaleNrs: 7,
        objectiveTriggers: const [
          'Nyeri abdomen akut skala NRS 7/10',
          'Nadi 106 x/mnt (Takikardia ringan)',
        ],
        vitals: VitalsData(
          systolicBp: 118,
          diastolicBp: 76,
          heartRate: 106,
          respiratoryRate: 20,
          spo2: 98,
          temperatureC: 37.8,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
      PatientTriage(
        id: '037',
        queueNumber: '#037',
        name: 'Tn. Arif Rahman',
        ageYears: 52,
        gender: 'Laki-laki',
        ageGroup: IITTAgeGroup.adult,
        arrivalTime: '31 mnt lalu',
        priority: TriagePriority.green,
        chiefComplaint: 'Keseleo pergelangan kaki kanan ringan pasca olahraga',
        painScaleNrs: 3,
        objectiveTriggers: const [
          'Tanda vital stabil & tidak ada deformitas terbuka',
        ],
        vitals: VitalsData(
          systolicBp: 125,
          diastolicBp: 82,
          heartRate: 78,
          respiratoryRate: 18,
          spo2: 99,
          temperatureC: 36.6,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
      PatientTriage(
        id: '035',
        queueNumber: '#035',
        name: 'Ny. Sri Wahyuni',
        ageYears: 61,
        gender: 'Perempuan',
        ageGroup: IITTAgeGroup.adult,
        arrivalTime: '48 mnt lalu',
        verifiedAt: '12:54 WIB',
        priority: TriagePriority.yellow,
        chiefComplaint: 'Pusing berputar hebat & tekanan darah tinggi',
        painScaleNrs: 6,
        handlingStatus: 'Sudah Ditangani Dokter',
        isCompleted: true,
        satusehatSynced: true,
        objectiveTriggers: const [
          'Hipertensi urgensi TD 170/100 mmHg',
          'Vertigo akut disertai mual',
        ],
        vitals: VitalsData(
          systolicBp: 170,
          diastolicBp: 100,
          heartRate: 92,
          respiratoryRate: 20,
          spo2: 98,
          temperatureC: 36.7,
          avpu: 'Sadar Penuh (Alert / A)',
        ),
      ),
    ]);
  }
}

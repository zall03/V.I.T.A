import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/api/vita_api.dart';

/// Live clinical workflow. No demo patients or local triage classifications.
class ClinicalWorkspace extends StatefulWidget {
  const ClinicalWorkspace({super.key});
  @override
  State<ClinicalWorkspace> createState() => _ClinicalWorkspaceState();
}

class _ClinicalWorkspaceState extends State<ClinicalWorkspace> {
  final api = VitaApi(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    ),
  );
  final email = TextEditingController();
  final password = TextEditingController();
  final transcript = TextEditingController();
  final clinical = TextEditingController();
  Map<String, dynamic>? user, encounter, assessment;
  List<dynamic> patients = [];
  bool busy = false;
  String status = '';
  String? transcriptId, extractionId;
  Timer? timer;

  String uuid() {
    final r = Random.secure();
    final b = List.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => status = e is ApiFailure
              ? 'Permintaan gagal: ${e.code} (${e.status}). Jika 409, muat ulang assessment.'
              : 'Koneksi atau format data gagal. Periksa server dan input.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> login() async {
    final identity = await api.login(email.text.trim(), password.text);
    password.clear();
    if (identity['role'] != 'nurse') {
      await api.logout();
      throw const ApiFailure(403, 'nurse_required');
    }
    final rows = await api.patients();
    if (!mounted) return;
    setState(() {
      user = identity;
      patients = rows as List;
      status = '';
    });
  }

  Future<void> start(Map<String, dynamic> patient) async {
    final created = await api.createEncounter(patient['id'] as String);
    final started = await api.startEncounter(
      created['id'] as String,
      created['version'] as int,
    );
    if (!mounted) return;
    setState(() {
      encounter = Map<String, dynamic>.from(started as Map);
      assessment = null;
      transcriptId = null;
      extractionId = null;
      transcript.clear();
      clinical.clear();
      status = 'Encounter dimulai.';
    });
  }

  Future<void> loadAssessment() async {
    final result = await api.assessment(encounter!['id'] as String);
    if (!mounted) return;
    setState(() {
      assessment = Map<String, dynamic>.from(result as Map);
      encounter!['version'] = assessment!['encounter_version'];
      clinical.text = const JsonEncoder.withIndent('  ')
          .convert(assessment!['data']);
      status =
          'Assessment ${assessment!['assessment_status']}, revisi ${assessment!['revision_number']}';
    });
  }

  Future<void> extract() async {
    final id = encounter!['id'] as String;
    final saved = await api.submitTranscript(
      id,
      uuid(),
      transcript.text.trim(),
    );
    transcriptId = saved['id'] as String;
    final job = await api.extract(id, uuid(), transcriptId!);
    extractionId = job['id'] as String;
    if (!mounted) return;
    setState(() => status = 'Ekstraksi ${job['status']}. Menunggu worker.');
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!busy && mounted) run(poll);
    });
  }

  Future<void> poll() async {
    final job = await api.extraction(encounter!['id'] as String, extractionId!);
    if (!mounted) return;
    setState(() => status = 'Ekstraksi: ${job['status']}');
    if (job['status'] == 'failed') {
      timer?.cancel();
      setState(
        () => status =
            'Ekstraksi gagal: ${job['error_code']}. Entri manual tetap tersedia.',
      );
    } else if (job['status'] == 'succeeded') {
      timer?.cancel();
      await loadAssessment();
      if (!mounted) return;
      final result = job['data'] as Map;
      setState(
        () => status =
            'Provider: ${result['provider']} / ${result['model_name']}. '
            'Wajib review manusia. Peringatan: ${result['warnings']}',
      );
    }
  }

  void manual() {
    clinical.text = jsonEncode({
      'chief_complaint': null,
      'history_of_present_illness': null,
      'symptoms': [],
      'medical_history': [],
      'allergies': {'status': 'unknown', 'items': []},
      'medications': [],
      'vital_signs': {
        for (final k in [
          'systolic_bp',
          'diastolic_bp',
          'heart_rate',
          'respiratory_rate',
          'temperature',
          'spo2',
        ])
          k: null,
      },
    });
    setState(
      () => status = 'Draft manual. Isi hanya informasi yang diketahui.',
    );
  }

  Future<void> save() async {
    final data = jsonDecode(clinical.text) as Map<String, dynamic>;
    await api.saveAssessment(
      encounter!['id'] as String,
      encounter!['version'] as int,
      data,
      initial: assessment == null,
    );
    await loadAssessment();
  }

  Future<void> verify() async {
    if (jsonEncode(jsonDecode(clinical.text)) != jsonEncode(assessment!['data'])) {
      setState(() => status = 'Ada perubahan belum disimpan. Simpan revisi sebelum verifikasi.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi assessment tersimpan?'),
        content: const Text(
          'Pastikan seluruh informasi telah ditinjau. Simpan perubahan sebelum verifikasi. Ini bukan penetapan kategori triase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await api.verify(
      encounter!['id'] as String,
      assessment!['id'] as String,
      encounter!['version'] as int,
    );
    await loadAssessment();
    if (mounted) {
      setState(
        () => status =
            'Assessment terverifikasi. Dokumentasi siap untuk triase. '
            'Kategori IITT belum tersedia: engine backend belum diimplementasikan.',
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    api.close();
    email.dispose();
    password.dispose();
    transcript.dispose();
    clinical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('V.I.T.A. • Dokumentasi Klinis'),
      actions: [
        if (user != null)
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: busy
                ? null
                : () => run(() async {
                    timer?.cancel();
                    try {
                      await api.logout();
                    } finally {
                      if (mounted) {
                        setState(() {
                          user = null;
                          encounter = null;
                          assessment = null;
                          patients = [];
                          transcript.clear();
                          clinical.clear();
                          status = '';
                        });
                      }
                    }
                  }),
          ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (busy) const LinearProgressIndicator(),
            if (status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(status),
              ),
            if (user == null) ...[
              const Text('Masuk dengan akun nurse backend'),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              FilledButton(
                onPressed: busy ? null : () => run(login),
                child: const Text('Masuk'),
              ),
            ] else ...[
              Text('${user!['name']} • ${user!['role']}'),
              TextButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        await api.refresh();
                        await api.me();
                        if (mounted) {
                          setState(() => status = 'Sesi diperbarui.');
                        }
                      }),
                child: const Text('Perbarui sesi'),
              ),
              if (encounter == null) ...[
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => run(() async {
                          final p = await api.createPatient({
                            'identity_status': 'temporary',
                            'full_name': null,
                            'birth_date': null,
                            'sex': 'unknown',
                          });
                          await start(Map<String, dynamic>.from(p as Map));
                        }),
                  child: const Text('Intake pasien identitas belum diketahui'),
                ),
                const Text('Pasien fasilitas — 20 data pertama'),
                for (final p in patients)
                  ListTile(
                    title: Text(
                      p['full_name'] as String? ?? 'Identitas sementara',
                    ),
                    subtitle: Text(p['medical_record_number'] as String),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: busy
                        ? null
                        : () => run(
                            () => start(Map<String, dynamic>.from(p as Map)),
                          ),
                  ),
              ] else ...[
                Text('Encounter: ${encounter!['id']}'),
                const Text(
                  'Masukkan transkrip yang sudah ditinjau. Perekaman whisper.cpp belum terhubung.',
                ),
                TextField(
                  controller: transcript,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Transkrip / catatan manual',
                  ),
                ),
                FilledButton(
                  onPressed: busy || extractionId != null
                      ? null
                      : () => run(extract),
                  child: const Text('Kirim dan ekstrak melalui backend'),
                ),
                TextButton(
                  onPressed: busy ? null : manual,
                  child: const Text('Entri manual tanpa AI'),
                ),
                TextButton(
                  onPressed: busy ? null : () => run(loadAssessment),
                  child: const Text('Muat ulang assessment tersimpan'),
                ),
                const Text(
                  'Editor klinis terstruktur (JSON schema 1.0). Nilai tidak diketahui tetap null.',
                ),
                TextField(
                  controller: clinical,
                  maxLines: 15,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                FilledButton(
                  onPressed: busy || clinical.text.isEmpty
                      ? null
                      : () => run(save),
                  child: const Text('Simpan revisi untuk ditinjau'),
                ),
                FilledButton(
                  onPressed:
                      busy ||
                          assessment == null ||
                          assessment!['assessment_status'] == 'verified'
                      ? null
                      : () => run(verify),
                  child: const Text('Verifikasi revisi tersimpan'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Antrean, klasifikasi IITT, dan pengiriman SATUSEHAT belum tersedia. Penanganan klinis tidak boleh menunggu aplikasi.',
                ),
              ],
            ],
          ],
        ),
      ),
    ),
  );
}

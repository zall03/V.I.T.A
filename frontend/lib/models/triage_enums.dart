enum TriagePriority {
  red(
    label: 'Merah',
    badgeTitle: 'PRIORITAS 1 — RESUSITASI SEGERA',
    detailBadge: 'PRIORITAS 1 • RESUSITASI SEGERA',
    queueLabel: 'Prioritas 1 (Resusitasi/Gawat)',
    levelText: 'IITT LEVEL 1',
    categoryText: 'IITT Kategori 1 • Bed Resusitasi',
    headline: 'Membutuhkan penanganan medis segera.',
    recommendedRoom: 'Ruang Resusitasi (Bed 01–02)',
    waitTime: '0 Menit (Segera / Immediate)',
    rationaleTitle: 'Alasan Prioritas 1 (Standar Medis WHO)',
  ),
  yellow(
    label: 'Kuning',
    badgeTitle: 'PRIORITAS 2 — OBSERVASI DARURAT',
    detailBadge: 'PRIORITAS 2 • OBSERVASI DARURAT',
    queueLabel: 'Prioritas 2 (Darurat)',
    levelText: 'IITT LEVEL 2',
    categoryText: 'IITT Kategori 2 • Observasi Darurat',
    headline: 'Membutuhkan evaluasi medis prioritas.',
    recommendedRoom: 'Zona Observasi Darurat (Bed 03–07)',
    waitTime: '< 10–15 Menit',
    rationaleTitle: 'Alasan Prioritas 2 (Standar Medis WHO)',
  ),
  green(
    label: 'Hijau',
    badgeTitle: 'PRIORITAS 3 — TINDAKAN NON-KRITIS',
    detailBadge: 'PRIORITAS 3 • NON-KRITIS (STABIL)',
    queueLabel: 'Prioritas 3 (Tidak Gawat)',
    levelText: 'IITT LEVEL 3',
    categoryText: 'IITT Kategori 3 • Tindakan Minor',
    headline: 'Kondisi stabil, ditangani sesuai urutan.',
    recommendedRoom: 'Zona Triase Hijau / Tindakan Minor',
    waitTime: '± 25–35 Menit',
    rationaleTitle: 'Alasan Prioritas 3 (Standar Medis WHO)',
  );

  const TriagePriority({
    required this.label,
    required this.badgeTitle,
    required this.detailBadge,
    required this.queueLabel,
    required this.levelText,
    required this.categoryText,
    required this.headline,
    required this.recommendedRoom,
    required this.waitTime,
    required this.rationaleTitle,
  });

  final String label;
  final String badgeTitle;
  final String detailBadge;
  final String queueLabel;
  final String levelText;
  final String categoryText;
  final String headline;
  final String recommendedRoom;
  final String waitTime;
  final String rationaleTitle;
}

enum IITTAgeGroup {
  adult(
    label: 'Dewasa (≥ 12 th)',
    shortLabel: '≥12 th',
    code: 'ADULT_GTE_12',
    subtitle: 'Protokol Dewasa • Skor MEWS / ATS Dewasa',
  ),
  pediatric(
    label: 'Anak (< 12 th)',
    shortLabel: '<12 th',
    code: 'PEDIATRIC_LT_12',
    subtitle: 'Protokol Pediatrik • Ambang TTV Anak WHO',
  );

  const IITTAgeGroup({
    required this.label,
    required this.shortLabel,
    required this.code,
    required this.subtitle,
  });

  final String label;
  final String shortLabel;
  final String code;
  final String subtitle;
}

enum ConnectionMode {
  online(label: 'Online • SATUSEHAT'),
  offline(label: 'Offline • Mode Lokal');

  const ConnectionMode({required this.label});
  final String label;
}

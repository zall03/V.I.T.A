# Product Requirements Document (PRD): V.I.T.A.
**Voice Integrated Triage Assessment — Hands-Free Clinical Intake, Triage Queue Support, and SATUSEHAT-Ready Documentation**

---

## 1. Informasi Proyek

| Atribut | Detail |
| :--- | :--- |
| **Nama Produk** | V.I.T.A. (Voice Integrated Triage Assessment) |
| **Versi Dokumen** | v1.0 (MVP — Target 4 Minggu) |
| **Tim Pengembang** | **wishweluck** — M. Haris Tri Nugraha (Leader), M. Rizal Jamali, Sandi Wira Priangga, Arfa Zulhilmi |
| **Kategori Kasus** | Case 2: Stronger Communities and Everyday Services |
| **Platform** | Aplikasi Mobile Perawat (Flutter) + Core Backend (Go) + AI Service (Python / Google Gemini API) |
| **Status** | Draft Finalisasi untuk Pengembangan |

---

## 2. Latar Belakang & Pernyataan Masalah

Pada jam sibuk di Instalasi Gawat Darurat (IGD) maupun Puskesmas, perawat triase harus memeriksa pasien, mengukur tanda-tanda vital (TTV), sekaligus mencatat anamnesis secara manual di atas kertas. Pola kerja ini menimbulkan tiga masalah utama:

1. **Pencatatan lambat dan tidak lengkap:** Observasi lapangan dan wawancara pada 8 Oktober 2026 bersama perawat IGD RSD Gunung Jati Cirebon menunjukkan pencatatan kertas menyulitkan dokumentasi keluhan serta pengecekan triase manual. Hal ini sejalan dengan studi di RSUD Kembangan yang menemukan 88% formulir IGD memiliki kolom kosong.
2. **Beban kerja ganda (*double-entry*):** Perawat harus mengetik ulang catatan kertas ke sistem elektronik untuk memenuhi standar rekam medis nasional **SATUSEHAT**.
3. **Antrean tidak transparan:** Keterlambatan input data membuat pasien dan keluarga di ruang tunggu tidak mendapatkan kejelasan status prioritas penanganan.

Penelitian menunjukkan *AI clinical scribe* mampu memangkas waktu pencatatan IGD hingga 28%, namun solusi komersial yang tersedia umumnya ditujukan bagi dokter berbahasa Inggris serta belum terintegrasi dengan protokol triase lokal maupun standar SATUSEHAT.

---

## 3. Tujuan & Metrik Keberhasilan (Success Metrics)

| Metrik | Target v1 | Metode Pengukuran |
| :--- | :--- | :--- |
| **Kecepatan Asesmen Triase** | 30–40% lebih cepat dibanding pencatatan manual | Uji coba simulasi dengan 10–15 perawat menggunakan data sintetis |
| **Kelengkapan Data Klinis** | 0 kolom wajib kosong (*zero missing fields*) | Validasi otomatis skema formulir WHO & payload SATUSEHAT FHIR |
| **Akurasi Penentuan Prioritas** | 100% deterministik sesuai aturan usia IITT ($< 12$ th dan $\ge 12$ th) | *Unit test* pada *rule engine* Go terhadap skenario kasus standar |
| **Keandalan Mode Offline** | 0 kehilangan rekaman suara saat koneksi terputus | Pengujian *store-and-forward* saat koneksi diputus lalu *online* kembali |

---

## 4. Target Pengguna (User Personas)

* **Perawat Triase IGD / Puskesmas (Pengguna Utama):** Bertugas melakukan skrining awal secara cepat, mengukur TTV, mewawancarai pasien/keluarga, dan menetapkan prioritas triase di lingkungan yang bising dan bertekanan tinggi.
* **Pasien & Keluarga di Ruang Tunggu (Pengguna Sekunder):** Membutuhkan kepastian dan transparansi urutan prioritas penanganan medis (Merah, Kuning, Hijau) tanpa melanggar privasi medis.

---

## 5. Ruang Lingkup Produk (Scope Management)

Agar target pengembangan **4 minggu** realistis untuk tim berisi 4 orang, fitur dibagi tegas sebagai berikut:

### Termasuk dalam v1 (Wajib Selesai)
* Dashboard antrean triase aktif beserta filter **Arsip Offline**.
* *Intake* suara 2 arah (*Push-to-Talk*) dengan kartu panduan pertanyaan template.
* Perekaman & penyimpanan lokal *offline* (*store-and-forward*) beserta sinkronisasi otomatis saat jaringan kembali *online*.
* Transkripsi lokal *on-device* dan ekstraksi transkrip ke draf formulir klinis WHO (Identitas, TTV, *Primary Survey* ABCDE, Anamnesa SAMPLE, Skala Nyeri NRS) via Google Gemini API.
* Mesin aturan deterministik **IITT** berbasis usia ($< 12$ tahun dan $\ge 12$ tahun) di *backend* Go.
* Layar verifikasi perawat (*human-in-the-loop*) dengan fitur edit cepat dan *override* manual prioritas.
* Generasi dan validasi *payload* JSON **SATUSEHAT FHIR** (opsi *push live* ke SATUSEHAT Sandbox atau validator lokal mengikuti keputusan tim *backend*).

### Opsional / Nilai Tambah Demo
* Halaman web/TV *read-only* untuk layar ruang tunggu pasien (*Live Queue Display*) menggunakan nomor antrean anonim.

### Di Luar Cakupan v1 (Mockup Statis / Fase 2)
* Integrasi *backend real-time* untuk tab **Kapasitas Bed IGD** dan **Jadwal Shift Petugas** (jika dipertahankan di UI demi kelengkapan visual, cukup menggunakan data statis).

---

## 6. Kebutuhan Fungsional (Functional Requirements)

### F1. Dashboard Antrean Triase & Status Koneksi
* **Header Status:** Menampilkan identitas `V.I.T.A. • IGD`, nama perawat bertugas, jam aktual & label shift yang sesuai, serta indikator koneksi (`Online • SATUSEHAT` / `Offline • Mode Lokal`).
* **Ringkasan Prioritas:** Tiga kartu statistik jumlah pasien aktif: **Merah (Resusitasi)**, **Kuning (Urgen)**, dan **Hijau (Non-Urgen)**.
* **Filter Antrean:** Filter cepat `Semua`, `Merah`, `Kuning`, `Hijau`, dan `Arsip Offline` (dilengkapi penanda jumlah rekaman yang belum tersinkronisasi).
* **Kartu Pasien:** Diurutkan berdasarkan tingkat kegawatdaruratan lalu waktu kedatangan; menampilkan nomor antrean, identitas ringkas, badge kelompok usia IITT ($< 12$ th / $\ge 12$ th), keluhan utama, ringkasan TTV kritis, dan tombol `Buka Asesmen`.
* **Tombol Aksi Utama:** Tombol melayang `+ Triase Suara` dengan jarak bawah (*padding*) yang cukup agar tidak menutupi tombol pada kartu antrean.

### F2. Intake Suara 2 Arah Terpandu (*Push-to-Talk* & *Offline*)
* **Target Pasien:** Mendukung pemilihan pasien dari daftar antrean maupun pembuatan cepat `+ Pasien Baru`.
* **Panduan Pertanyaan Template (4 Tahap):**
  1. **Identitas & Usia:** Menentukan cabang aturan IITT ($< 12$ th atau $\ge 12$ th).
  2. **Keluhan Utama & Tanda Bahaya (*Red Flags*):** Menangkap gejala kritis (nyeri dada, sesak berat, kejang, perdarahan, penurunan kesadaran).
  3. **Tanda-Tanda Vital (TTV):** Panduan pengucapan TD, Nadi (HR), Laju Napas (RR), Suhu, SpO2, dan Kesadaran (AVPU/GCS) disertai indikator *chip* visual untuk parameter yang sudah terekam.
  4. **Verifikasi:** Melanjutkan ke lembar asesmen.
* **Mekanisme *Push-to-Talk* (PTT):** Perawat menekan dan menahan tombol mikrofon saat berbicara/mewawancarai pasien untuk meminimalkan kebisingan latar IGD.
* **Mode *Offline* (*Store-and-Forward*):**
  * Saat jaringan terputus, rekaman audio (dan transkrip lokal *on-device* jika tersedia) disimpan otomatis ke penyimpanan lokal HP dengan status **Menunggu Sinyal**.
  * Perawat tetap dapat menandai prioritas darurat manual (Merah/Kuning) secara lokal jika pasien dalam kondisi kritis.
  * Begitu koneksi kembali *online*, aplikasi mengunggah arsip ke server AI secara otomatis dan mengubah statusnya menjadi **Siap Diverifikasi**.

### F3. Ekstraksi Klinis AI (Gemini) & Lembar Asesmen WHO
* **Pemisahan Peran AI:** Layanan AI (Python + Google Gemini API) **hanya** mengekstrak transkrip menjadi draf formulir klinis terstruktur, bukan menetapkan diagnosis medis atau keputusan triase akhir.
* **Struktur Formulir yang Dapat Diedit Perawat:**
  * **Section A — Tanda-Tanda Vital (TTV):** TD, Nadi/HR, Laju Napas/RR, Saturasi SpO2, dan Suhu Aksila, masing-masing dilengkapi label status otomatis (*Tinggi*, *Takikardia*, *Takipnea*, *Hipoksia*, *Normal*).
  * **Section B — Primary Survey (ABCDE):** Pilihan cepat *toggle* untuk *Airway*, *Breathing*, *Circulation*, dan *Disability* (GCS/AVPU).
  * **Section C — Anamnesa SAMPLE & Nyeri:** Keluhan utama, alergi, riwayat penyakit, serta *slider* skala nyeri NRS (0–10).

### F4. Mesin Aturan Deterministik IITT & Verifikasi Perawat
* **Evaluasi Deterministik (Go Backend):** *Backend* Go menghitung prioritas triase (**Merah / Kuning / Hijau**) secara deterministik berdasarkan aturan **IITT (Interagency Integrated Triage Tool)** sesuai kelompok usia pasien ($< 12$ tahun vs $\ge 12$ tahun).
* **Transparansi Pemicu:** Banner hasil triase wajib menampilkan pemicu objektifnya (contoh: *"Pemicu objektif: SpO2 92% ($< 94\%$) & Nyeri Dada Kritis"*), bukan skor kepercayaan AI.
* **Verifikasi & *Override*:** Perawat dapat menyunting kolom draf atau melakukan *override* manual prioritas (dengan catatan alasan singkat) sebelum menekan `Validasi & Simpan Asesmen` untuk mengunci data ke *live queue*.

### F5. Interoperabilitas SATUSEHAT FHIR
* **Pemetaan Resource FHIR:** *Backend* Go memetakan asesmen terverifikasi ke *payload* JSON sesuai standar SATUSEHAT Kemenkes, minimal mencakup resource `Patient`, `Encounter`, `Observation` (TTV), dan `Condition` (keluhan/tanda bahaya).
* **Indikator Kesiapan di UI:** Menampilkan status kelengkapan di bagian bawah lembar asesmen (contoh: `SATUSEHAT FHIR Siap • 0 kolom kosong`).

---

## 7. Arsitektur Teknis & Kontrak Data

### Komponen Sistem
1. **Mobile Client (Flutter):** UI perawat, perekaman audio *push-to-talk*, penyimpanan arsip lokal (SQLite/Hive), transkripsi *on-device*, dan sinkronisasi latar belakang.
2. **AI Extraction Service (Python + Google Gemini API):** Menerima transkrip berlabel tahap pertanyaan (atau audio arsip) dan mengembalikan JSON terstruktur sesuai skema formulir klinis WHO menggunakan *structured output*.
3. **Core Backend (Go):** Autentikasi, manajemen antrean *real-time* (WebSocket/SSE), *rule engine* deterministik IITT ($< 12$ th & $\ge 12$ th), serta mapper dan validator **SATUSEHAT FHIR**.

### Contoh Kontrak Data JSON (Flutter, Python AI, dan Go Backend)
```json
{
  "encounter_id": "ENC-20261126-014",
  "patient": {
    "name": "Tn. Hendra Gunawan",
    "age_years": 48,
    "gender": "male",
    "iitt_age_group": "ADULT_GTE_12"
  },
  "vitals": {
    "systolic_bp": 160,
    "diastolic_bp": 95,
    "heart_rate": 115,
    "respiratory_rate": 24,
    "spo2": 92,
    "temperature_c": 36.8,
    "avpu": "Alert"
  },
  "primary_survey": {
    "airway": "Paten",
    "breathing": "Sesak",
    "circulation": "Akral Dingin / Diaphoresis",
    "disability": "Alert (GCS 15)"
  },
  "anamnesis": {
    "chief_complaint": "Nyeri dada retrosternal menjalar ke lengan kiri sejak 2 jam lalu",
    "red_flags": ["chest_pain", "shortness_of_breath", "diaphoresis"],
    "allergies": "Tidak ada",
    "past_medical_history": "Hipertensi 5 tahun tidak rutin",
    "pain_scale_nrs": 7
  },
  "triage_result": {
    "priority": "RED",
    "rule_source": "IITT_DETERMINISTIC_ADULT",
    "triggers": ["SpO2 < 94% (92%)", "High-risk chest pain"],
    "nurse_verified": true,
    "manual_override": false
  },
  "satusehat_status": "FHIR_PAYLOAD_READY"
}
```

---

## 8. Kebutuhan Non-Fungsional (NFR) & Keamanan Klinis

* **Keamanan Klinis (*Human-in-the-Loop*):** Sistem tidak boleh menetapkan diagnosis definitif otomatis dan tidak boleh memasukkan pasien ke antrean akhir tanpa verifikasi eksplisit dari perawat.
* **Privasi & Data Uji:** Seluruh pengembangan, uji coba, dan demo menggunakan **data pasien sintetis**. Layar ruang tunggu hanya menampilkan nomor antrean anonim (misal `A-014`) tanpa nama asli maupun keluhan medis.
* **Kinerja Respons:** Waktu ekstraksi AI hingga tampil di layar verifikasi ditargetkan $< 5$ detik pada koneksi standar; kalkulasi skor IITT di *backend* Go $< 200$ ms.
* **Ergonomi IGD:** Seluruh tombol utama (PTT dan *toggle* ABCDE) memiliki area sentuh besar yang nyaman dioperasikan satu tangan.

---

## 9. Rencana Pengembangan 4 Minggu (Milestones)

| Minggu | Fokus Utama | Deliverable Kunci |
| :--- | :--- | :--- |
| **Minggu 1** | Fondasi UI & Kontrak Data | Finalisasi desain UI, *slicing* layar utama Flutter (Antrean, Live Suara PTT, Lembar Asesmen), kesepakatan kontrak JSON, inisialisasi repo Go & Python |
| **Minggu 2** | Suara, Offline & AI | Implementasi *Push-to-Talk*, perekaman & penyimpanan lokal *offline*, *on-device STT*, dan layanan Python + Gemini API untuk ekstraksi draf WHO |
| **Minggu 3** | IITT Engine & Live Queue | Implementasi *rule engine* deterministik IITT ($< 12$ th & $\ge 12$ th) di Go, sinkronisasi *live queue* WebSocket/SSE, integrasi *end-to-end* Flutter–Go |
| **Minggu 4** | SATUSEHAT FHIR & Uji Coba | Mapper/validator SATUSEHAT FHIR (atau *push* Sandbox), uji coba simulasi data sintetis dengan 10–15 perawat, *bug fixing*, dan persiapan demo |

---

## 10. Risiko & Mitigasi

| Risiko | Dampak | Strategi Mitigasi |
| :--- | :--- | :--- |
| **Kebisingan latar di IGD** | Transkrip suara kurang akurat | Gunakan *Push-to-Talk* per tahap pertanyaan template dan sediakan edit manual cepat di layar verifikasi |
| **Internet putus di Puskesmas/IGD** | Ekstraksi Gemini tertunda | Simpan audio & transkrip lokal (*store-and-forward*), sediakan tombol *flag* darurat manual saat *offline* |
| **Keterlambatan akses SATUSEHAT Sandbox** | Gagal demo *live push* API Kemenkes | Bangun generator & validator skema JSON FHIR lokal di Go sebagai *fallback* yang tetap patuh standar Kemenkes |
| **Salah interpretasi AI pada angka TTV** | Risiko kesalahan prioritas triase | Wajibkan layar verifikasi perawat + sorot warna merah/kuning pada angka TTV abnormal sebelum skor IITT dikunci |

---

## 11. Referensi

1. Rahman et al. (2023), *Jurnal Kesehatan Tambusai*, 4(1), 84–90.
2. Preiksaitis et al. (2026), *JMIR AI*, 5, e92193.
3. WHO (2020), *Standardized Clinical Form* & Permenkes RI No. 47/2018.
4. WHO (2020), *Interagency Integrated Triage Tool (IITT)* & Kemenkes RI (2022), *SATUSEHAT FHIR*.
5. Biro et al. (2025), *J Med Internet Res*, 27, e64993.
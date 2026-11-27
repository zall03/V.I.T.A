import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_mobile/core/theme/app_theme.dart';
import 'package:vita_mobile/providers/triage_provider.dart';
import 'package:vita_mobile/screens/auth/login_screen.dart';

void main() {
  testWidgets('Fingerprint Login, Nurse Profile, Riwayat Archive, and 4-Step Flow',
      (WidgetTester tester) async {
    final provider = TriageProvider();
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(provider: provider),
      ),
    );

    // 1. Login via Fingerprint Modal
    expect(find.text('Masuk Cepat dengan Sidik Jari (1–Sentuh)'), findsOneWidget);
    await tester.ensureVisible(
        find.text('Masuk Cepat dengan Sidik Jari (1–Sentuh)'));
    await tester.tap(find.text('Masuk Cepat dengan Sidik Jari (1–Sentuh)'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Sidik Jari Perawat Terverifikasi'), findsOneWidget);

    await tester.tap(find.text('Masuk ke Antrean Triase IGD →'));
    await tester.pumpAndSettle();
    expect(find.text('Monitor TV Ruang Tunggu IGD • Aktif'), findsOneWidget);

    // 2. Open Nurse Profile & toggle Edit Data
    await tester
        .tap(find.image(const AssetImage('assets/images/profil.png')).first);
    await tester.pumpAndSettle();
    expect(find.text('Profil Perawat IGD'), findsOneWidget);

    await tester.tap(find.text('✎ Edit Data'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Simpan'), findsOneWidget);
    await tester.tap(find.text('✓ Simpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Antrean IGD'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 3. Switch to Riwayat tab & open Arsip Riwayat #036
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Riwayat Triase'), findsWidgets);
    await tester.tap(find.text('#036'));
    await tester.pumpAndSettle();
    expect(find.text('Arsip Riwayat #036'), findsOneWidget);
    expect(find.text('HTTP 201 Created ✓'), findsOneWidget);
    await tester.tap(find.text('← Kembali ke Daftar Riwayat IGD'));
    await tester.pumpAndSettle();

    // 4. Open Triase Baru -> Step 1 -> Step 2 (Inline Edit Teks) -> Step 3
    await tester.tap(find.text('Triase Baru'));
    await tester.pumpAndSettle();
    expect(find.text('KATEGORI INSIDEN CEPAT (OPSIONAL)'), findsOneWidget);

    await tester.tap(find.text('Lanjut ke Rekam Suara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Teks'));
    await tester.pumpAndSettle();
    expect(find.text('✓ Simpan Teks'), findsOneWidget);

    await tester.tap(find.text('Ekstrak ke Form'));
    await tester.pumpAndSettle();
    expect(find.text('6 Parameter Klinis'), findsOneWidget);
  });
}

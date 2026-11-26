import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vita_mobile/core/theme/app_theme.dart';
import 'package:vita_mobile/providers/triage_provider.dart';
import 'package:vita_mobile/screens/auth/login_screen.dart';

void main() {
  testWidgets('Login to Queue, Public TV, and Triase Baru flow works',
      (WidgetTester tester) async {
    final provider = TriageProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: LoginScreen(provider: provider),
      ),
    );

    // Verify Login Screen elements
    expect(find.text('V.I.T.A.'), findsOneWidget);
    expect(find.text('Mulai Shift'), findsOneWidget);

    // Tap Mulai Shift -> navigates to MainNavigationScreen (QueueDashboardScreen)
    await tester.ensureVisible(find.text('Mulai Shift'));
    await tester.tap(find.text('Mulai Shift'));
    await tester.pumpAndSettle();

    expect(find.text('Antrean Triase'), findsWidgets);
    expect(find.text('Monitor TV Ruang Tunggu IGD • Aktif'), findsOneWidget);
    expect(find.text('Triase Baru'), findsOneWidget);

    // Tap Lihat TV -> opens PublicTvScreen
    await tester.tap(find.text('Lihat TV'));
    await tester.pumpAndSettle();
    expect(find.text('TV Ruang Tunggu IGD • Live'), findsOneWidget);

    // Return to Nurse Mode
    await tester.tap(find.text('Mode Perawat'));
    await tester.pumpAndSettle();
    expect(find.text('Monitor TV Ruang Tunggu IGD • Aktif'), findsOneWidget);

    // Tap Triase Baru -> opens Step 1/4
    await tester.tap(find.text('Triase Baru'));
    await tester.pumpAndSettle();
    expect(find.text('Informasi Awal Pasien'), findsOneWidget);
    expect(find.text('LANGKAH 1/4'), findsOneWidget);
  });
}

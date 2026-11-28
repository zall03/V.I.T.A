import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'providers/triage_provider.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  runApp(const VitaApp());
}

class VitaApp extends StatefulWidget {
  const VitaApp({super.key});

  @override
  State<VitaApp> createState() => _VitaAppState();
}

class _VitaAppState extends State<VitaApp> {
  late final TriageProvider _triageProvider;

  @override
  void initState() {
    super.initState();
    _triageProvider = TriageProvider();
  }

  @override
  void dispose() {
    _triageProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'V.I.T.A. - Triase Suara & Dokumentasi Klinis IGD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(provider: _triageProvider),
    );
  }
}

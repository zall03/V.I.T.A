import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/waveform_visualizer.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  final TriageProvider provider;

  const SplashScreen({super.key, required this.provider});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isReadyPhase = false;
  double _progress = 0.42;
  Timer? _phaseTimer;
  Timer? _navTimer;
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Phase 2 (AI Core Ignition) -> Phase 3 (Voice Wave & Ready)
    _phaseTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isReadyPhase = true;
        _progress = 1.0;
      });
    });

    // Phase 3 -> Login Screen
    _navTimer = Timer(const Duration(milliseconds: 2800), _goToLogin);
  }

  void _goToLogin() {
    _phaseTimer?.cancel();
    _navTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => LoginScreen(provider: widget.provider),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _navTimer?.cancel();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = !_isReadyPhase;

    return GestureDetector(
      onTap: _goToLogin,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? const [
                      AppColors.splashDarkTop,
                      AppColors.splashDarkMid,
                      AppColors.splashDarkBottom,
                    ]
                  : const [
                      Color(0xFFF0F9FF),
                      Color(0xFFE0F2FE),
                      Color(0xFFF8FAFC),
                    ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  // Top Status Pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.waveCyan.withValues(alpha: 0.45)
                            : AppColors.primaryBorderStrong.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? AppColors.waveCyan : AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDark
                              ? 'AI VOICE TRIAGE ENGINE • IGD'
                              : '✓ AI IGD SIAP • SATUSEHAT SYNC',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark ? Colors.white : AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Orbital Rings + Logo
                  SizedBox(
                    width: 230,
                    height: 230,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RotationTransition(
                          turns: _ringController,
                          child: _OrbitalRings(isDark: isDark),
                        ),
                        Container(
                          width: 104,
                          height: 104,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? AppColors.waveCyan.withValues(alpha: 0.35)
                                    : AppColors.primaryBlue.withValues(alpha: 0.14),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_vita.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'V.I.T.A.',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Triase Suara & Dokumentasi Klinis IGD',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Bottom Waveform & Progress Card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? AppColors.waveCyan.withValues(alpha: 0.25)
                            : Colors.white,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.10),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        const WaveformVisualizer(
                          animate: true,
                          barCount: 13,
                          maxHeight: 42,
                          barWidth: 5,
                          spacing: 6,
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.15, end: _progress),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, val, _) => LinearProgressIndicator(
                              value: val,
                              minHeight: 6,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : AppColors.primaryTint,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? AppColors.waveCyan : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isDark
                              ? 'Menginisialisasi Sensor Suara & AI Triase... 42%'
                              : 'Modul Suara & Rekam Medis IGD Aktif • 100%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitalRings extends StatelessWidget {
  final bool isDark;

  const _OrbitalRings({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ringColor = isDark
        ? AppColors.waveCyan.withValues(alpha: 0.45)
        : AppColors.primaryBorderStrong.withValues(alpha: 0.45);
    final dotColor = isDark ? AppColors.waveCyan : AppColors.primaryBlue;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ringColor.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
        ),
        Container(
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor, width: 1.5),
          ),
        ),
        Container(
          width: 136,
          height: 136,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ringColor.withValues(alpha: 0.7), width: 1.4),
          ),
        ),
        Positioned(
          top: 16,
          right: 42,
          child: _dot(10, dotColor),
        ),
        Positioned(
          left: 16,
          top: 76,
          child: _dot(12, dotColor),
        ),
        Positioned(
          bottom: 24,
          right: 34,
          child: _dot(9, dotColor.withValues(alpha: 0.75)),
        ),
      ],
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

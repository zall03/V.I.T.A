import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/triage_provider.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  final TriageProvider provider;

  const LoginScreen({super.key, required this.provider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _selectedShift;
  bool _isDropdownOpen = false;
  bool _showPin = false;
  late final TextEditingController _nurseIdController;
  final List<TextEditingController> _pinControllers = [
    TextEditingController(text: '4'),
    TextEditingController(text: '8'),
    TextEditingController(text: '2'),
    TextEditingController(text: '6'),
  ];
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());
  int _activePinIndex = 3;
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _enableBiometrics = false;

  @override
  void initState() {
    super.initState();
    _selectedShift = widget.provider.selectedShift;
    _nurseIdController = TextEditingController();
    for (int i = 0; i < 4; i++) {
      _pinFocusNodes[i].addListener(() {
        if (_pinFocusNodes[i].hasFocus && mounted) {
          setState(() => _activePinIndex = i);
        }
      });
    }
  }

  @override
  void dispose() {
    _nurseIdController.dispose();
    _passwordController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _pinFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _handleStartShift() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.provider.login(
        _nurseIdController.text.trim(),
        _passwordController.text,
      );
      if (_enableBiometrics) {
        try {
          await widget.provider.api.enableBiometrics();
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Biometrik tidak dapat diaktifkan. Login password tetap tersedia.',
                ),
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Login gagal. Periksa ID akun/email, password, dan koneksi.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    widget.provider.setShift(_selectedShift);
    widget.provider.setNurseId(_nurseIdController.text);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(provider: widget.provider),
      ),
    );
  }

  Future<void> _showFingerprintModal() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final identity = await widget.provider.api.biometricLogin();
      if (identity['role'] != 'nurse') {
        await widget.provider.api.logout();
        throw StateError('nurse_required');
      }
      widget.provider.identity = identity;
      widget.provider.setNurseId(identity['id'] as String);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainNavigationScreen(provider: widget.provider),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Biometrik dibatalkan/tidak tersedia atau sesi berakhir. Login password dan aktifkan biometrik terlebih dahulu.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void unusedDemoFingerprintModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryTint,
                  border: Border.all(color: AppColors.primaryBorder, width: 2),
                ),
                child: Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue,
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '✓ Sidik Jari Perawat Terverifikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.provider.nurseFullName} • ID: ${_nurseIdController.text}\n$_selectedShift',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _handleStartShift();
                  },
                  child: const Text(
                    'Masuk ke Antrean Triase IGD →',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Logo Card
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo_vita.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'V.I.T.A.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navyDark,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Triase Suara & Dokumentasi Klinis IGD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              // Registered Nurse ID Banner (matching Login - 1. Ketik ID Perawat.png)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryPillBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '✓ ID Perawat ${_nurseIdController.text} Terdaftar • Ketuk Kotak PIN di Bawah',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Login Form Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHIFT',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () =>
                          setState(() => _isDropdownOpen = !_isDropdownOpen),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDropdownOpen
                                ? AppColors.primaryBorderStrong
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedShift,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              _isDropdownOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isDropdownOpen) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: TriageProvider.shiftOptions.map((option) {
                            final isSelected = option == _selectedShift;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedShift = option;
                                  _isDropdownOpen = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE5EEFF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'ID PERAWAT',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _nurseIdController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.verified_outlined,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showPin = !_showPin),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showPin
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 16,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showPin ? 'Show' : 'Hide',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPin,
                      decoration: const InputDecoration(
                        labelText: 'Password akun',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    Offstage(
                      offstage: true,
                      child: Row(
                        children: List.generate(4, (index) {
                          final isActive = _activePinIndex == index;
                          final obscureBox =
                              !_showPin ||
                              (index == 3 && !_pinFocusNodes[3].hasFocus);
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < 3 ? 10 : 0,
                              ),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primaryBlue
                                        : AppColors.border,
                                    width: isActive ? 2 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: TextField(
                                  controller: _pinControllers[index],
                                  focusNode: _pinFocusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  obscureText: obscureBox,
                                  obscuringCharacter: '•',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onTap: () =>
                                      setState(() => _activePinIndex = index),
                                  onChanged: (val) {
                                    if (val.isNotEmpty && index < 3) {
                                      _pinFocusNodes[index + 1].requestFocus();
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Primary CTA: Mulai Shift
              CheckboxListTile(
                value: _enableBiometrics,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _enableBiometrics = v ?? false),
                title: const Text('Aktifkan biometrik setelah login'),
                subtitle: const Text(
                  'Hanya untuk perangkat pribadi. Semua biometrik terdaftar di HP dapat membuka sesi ini.',
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _handleStartShift,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mulai Shift',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Secondary CTA: Masuk Cepat dengan Sidik Jari (1-Sentuh)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.primaryTintSoft,
                    foregroundColor: AppColors.navyDark,
                    side: const BorderSide(
                      color: AppColors.primaryBorderStrong,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _showFingerprintModal,
                  icon: const Icon(
                    Icons.fingerprint_rounded,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                  label: const Text(
                    'Masuk Cepat dengan Sidik Jari (1–Sentuh)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

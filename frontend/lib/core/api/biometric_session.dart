import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// OS-backed storage plus an application-level biometric gate.
/// Does not claim a biometric-bound cryptographic key or identify an individual nurse.
class BiometricSession {
  final auth = LocalAuthentication();
  final storage = const FlutterSecureStorage();
  String key(String origin) => 'vita.biometric.refresh.$origin';
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<bool> authenticate() async {
    if (!supported ||
        !await auth.canCheckBiometrics ||
        (await auth.getAvailableBiometrics()).isEmpty) {
      return false;
    }
    return auth.authenticate(
      localizedReason: 'Buka sesi perawat V.I.T.A.',
      biometricOnly: true,
    );
  }

  Future<void> save(String origin, String token) =>
      storage.write(key: key(origin), value: token);
  Future<void> clear(String origin) async {
    if (supported) await storage.delete(key: key(origin));
  }

  Future<String?> unlock(String origin) async {
    if (!await authenticate()) return null;
    return storage.read(key: key(origin));
  }
}

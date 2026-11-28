# Biometric login implementation

Flutter local_auth 3.0.2 and flutter_secure_storage 9.2.4 added. Android activity
uses FlutterFragmentActivity with USE_BIOMETRIC permission. iOS Face ID usage string
added; iOS build/signing not tested. Mobile only; browser/desktop fail safely.

Password login remains required for initial enrollment. Explicit checkbox opts in;
OS biometric authentication precedes saving refresh token. Subsequent biometric
button authenticates locally then rotates token through backend and checks nurse role.
Rotated token replaces stored token; refresh failure clears stored credentials.
End-shift logout removes local credentials and attempts server revocation. Reopening
app without logout retains biometric enrollment until session expiry/revocation.

Security boundary: encrypted OS storage plus application-level biometric gate, NOT
cryptographically biometric-bound token access. Device-enrolled biometrics identify
device user, not particular nurse. Personal devices only; no password or biometric
template stored. Strong Keystore/Keychain auth-bound keys and enrollment-change
invalidation remain future hardening. No claim of compromised-device resistance.

Verification: Flutter analyze passed; 3 tests passed (transport and UI fallback;
no real sensor test). Android debug APK build passed in 43s after disabling Kotlin
incremental compilation to avoid C:/D: cross-drive cache failure. Gradle/AGP/Kotlin
future-support warnings remain. Real sensor enrollment/cancel/lockout/relaunch,
refresh expiry and iOS Keychain entitlements require device acceptance testing.

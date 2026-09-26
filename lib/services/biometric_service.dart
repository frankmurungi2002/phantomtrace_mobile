import 'package:local_auth/local_auth.dart';

/// Thin wrapper around local_auth for fingerprint / face unlock.
///
/// Two use cases:
///  1. At app startup, if the user previously opted in, prompt for
///     fingerprint → if OK, use the stored JWT and skip the login screen.
///  2. Any sensitive action inside the app (e.g. Wipe, Delete Device)
///     that we want to gate behind a second factor.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True on a phone that has at least one biometric enrolled (fingerprint
  /// or face). Devices with only a PIN/pattern also return true because
  /// authenticateWithBiometrics falls back to device credentials.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics ||
          await _auth.isDeviceSupported();
      if (!canCheck) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Prompt for fingerprint. Returns true if the user authenticated.
  /// [reason] is the message shown on the OS-level fingerprint sheet.
  Future<bool> authenticate({String reason = 'Sign in to PhantomTrace'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,   // allow device PIN as a fallback
          stickyAuth: true,       // survives brief backgrounding
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

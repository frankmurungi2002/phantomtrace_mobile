import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the JWT + biometric-unlock credentials in the OS's secure enclave
/// (Android Keystore / iOS Keychain), NOT in plain SharedPreferences.
/// That way even a rooted phone won't leak the token.
class TokenService {
  static const _tokenKey     = 'jwt_token';
  static const _bioTokenKey  = 'jwt_token_bio';   // token guarded by fingerprint
  static const _bioEmailKey  = 'bio_email';
  static const _bioEnabledKey = 'bio_enabled';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Regular JWT (used by every authenticated request) ────────────────
  Future<void> saveToken(String token) async =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    // Don't wipe the biometric-guarded copy on a normal logout — the user
    // may want to sign back in with fingerprint. Use disableBiometric()
    // to explicitly turn that off.
  }

  // ── Biometric unlock support ─────────────────────────────────────────
  /// Called after a successful password login when the user opts in to
  /// biometric sign-in. Stores the JWT + email so the next launch can
  /// prompt for a fingerprint and skip the password screen entirely.
  Future<void> enableBiometric({required String token, required String email}) async {
    await _storage.write(key: _bioTokenKey, value: token);
    await _storage.write(key: _bioEmailKey, value: email);
    await _storage.write(key: _bioEnabledKey, value: '1');
  }

  Future<void> disableBiometric() async {
    await _storage.delete(key: _bioTokenKey);
    await _storage.delete(key: _bioEmailKey);
    await _storage.delete(key: _bioEnabledKey);
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _bioEnabledKey);
    return v == '1';
  }

  Future<String?> getBiometricToken() async =>
      _storage.read(key: _bioTokenKey);

  Future<String?> getBiometricEmail() async =>
      _storage.read(key: _bioEmailKey);
}

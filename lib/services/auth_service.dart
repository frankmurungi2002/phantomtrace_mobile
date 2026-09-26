import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants/api_constants.dart';

/// Result of a login attempt.
///  * [token] non-null → done, save it and open the dashboard
///  * [requiresTwoFactor] true → open the TwoFactorVerifyScreen with
///    [preAuthToken] (short-lived, 5 min)
///  * [error] non-null → show the message
class LoginResult {
  final String? token;
  final String? preAuthToken;
  final bool requiresTwoFactor;
  final String? error;
  const LoginResult._({
    this.token, this.preAuthToken,
    this.requiresTwoFactor = false, this.error,
  });
  factory LoginResult.ok(String token)      => LoginResult._(token: token);
  factory LoginResult.needs2fa(String pre)  => LoginResult._(preAuthToken: pre, requiresTwoFactor: true);
  factory LoginResult.err(String message)   => LoginResult._(error: message);
}

class AuthService {
  final Dio dio = Dio(BaseOptions(validateStatus: (s) => true));

  Future<LoginResult> login(String email, String password) async {
    try {
      final r = await dio.post(
        '${ApiConstants.baseUrl}/api/auth/login',
        data: {'email': email, 'password': password},
      );
      if (r.statusCode == 200) {
        if (r.data['requires_2fa'] == true) {
          return LoginResult.needs2fa(r.data['pre_auth_token'] as String);
        }
        final token = r.data['token'] as String?;
        if (token == null) return LoginResult.err('Login failed');
        await _registerFcmToken(token);
        return LoginResult.ok(token);
      }
      final err = r.data is Map ? (r.data['error'] ?? 'Invalid credentials') : 'Invalid credentials';
      return LoginResult.err(err.toString());
    } catch (_) {
      return LoginResult.err('Could not reach the server');
    }
  }

  /// Called by the biometric-unlock path when a stored JWT is being reused.
  /// Just re-registers the FCM token so pushes still work after a reboot.
  Future<void> refreshFcmForToken(String jwtToken) => _registerFcmToken(jwtToken);

  Future<void> _registerFcmToken(String jwtToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await dio.post(
        '${ApiConstants.baseUrl}/api/auth/fcm-token',
        data: {'token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $jwtToken'}),
      );
    } catch (_) {
      // FCM registration is best-effort; don't block login
    }
  }
}

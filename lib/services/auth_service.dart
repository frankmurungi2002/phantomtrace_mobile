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
  // Timeouts tuned so we survive a cold-start on Render free tier.
  final Dio dio = Dio(BaseOptions(
    validateStatus: (s) => true,
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 15),
  ));

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
        if (token == null) {
          return LoginResult.err(
              'The server answered OK but did not return a login token. '
              'Please try again, or contact support if it keeps happening.');
        }
        await _registerFcmToken(token);
        return LoginResult.ok(token);
      }
      return LoginResult.err(_friendlyServerError(r));
    } on DioException catch (e) {
      return LoginResult.err(_friendlyNetworkError(e));
    } catch (e) {
      return LoginResult.err('Unexpected error signing in.\n($e)');
    }
  }

  /// Convert any HTTP non-200 response into a user-facing message.
  String _friendlyServerError(Response r) {
    final code = r.statusCode ?? 0;
    String? backendMsg;
    if (r.data is Map) {
      final m = r.data as Map;
      backendMsg = (m['error'] ?? m['message'])?.toString();
    } else if (r.data is String) {
      final s = r.data as String;
      if (!s.startsWith('<')) backendMsg = s;
    }
    switch (code) {
      case 400:
        return backendMsg ??
            'Please check your email and password and try again.';
      case 401:
        return 'That email and password did not match. Try again, or use '
               '"Forgot password?" if you cannot remember your password.';
      case 403:
        return backendMsg ??
            'Your account is locked out. Please try again later or contact '
            'support.';
      case 429:
        return 'Too many login attempts. Please wait a minute and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'The server is having a problem right now (error $code). '
               'Please try again in a few seconds.'
               '${backendMsg != null ? "\nDetails: $backendMsg" : ""}';
      default:
        return backendMsg ??
            'Could not sign in (error $code). Please try again.';
    }
  }

  /// Convert a Dio network exception into a user-facing message that says
  /// what to try next.
  String _friendlyNetworkError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'The server took too long to respond. If this is your first '
               'request after a long time, the server may be waking up — '
               'please try again in 30 seconds.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server took too long to answer. Please check your '
               'internet connection and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your Wi-Fi or mobile '
               'data and try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please update the PhantomTrace '
               'app from the Play Store.';
      case DioExceptionType.cancel:
        return 'Sign in was cancelled.';
      case DioExceptionType.unknown:
      default:
        final msg = e.message ?? '';
        return 'Could not reach the server.'
               '${msg.isNotEmpty ? "\nDetails: $msg" : " Please try again."}';
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

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dio/dio.dart';
import 'token_service.dart';

class NotificationService {
  static final Dio _dio = Dio(BaseOptions(validateStatus: (s) => true));

  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _saveFcmToken(fcmToken);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveFcmToken);

    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground message: ${message.notification?.title}');
    });
  }

  static Future<void> _saveFcmToken(String fcmToken) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) return;
      await _dio.post(
        'http://192.168.1.76:5000/api/auth/fcm-token',
        data: {'token': fcmToken},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print('FCM token saved to backend');
    } catch (e) {
      print('FCM token save failed: $e');
    }
  }
}

import 'package:dio/dio.dart';

class AuthService {
  final Dio dio = Dio(
    BaseOptions(
      validateStatus: (status) => true,
    ),
  );

  Future<String?> login(
    String email,
    String password,
  ) async {
    final response = await dio.post(
      'https://phantomtrace-backend-c0if.onrender.com/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return response.data['token'];
    }

    return null;
  }
}

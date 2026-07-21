import 'package:dio/dio.dart';

class AuthService {

  final Dio dio = Dio();

  Future<String?> login(
    String email,
    String password,
  ) async {

    final response = await dio.post(
      'http://127.0.0.1:5000/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    return response.data['token'];
  }
}

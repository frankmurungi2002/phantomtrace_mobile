import 'package:dio/dio.dart';

class CommandService {
  final Dio dio = Dio(BaseOptions(
    validateStatus: (status) => true,
  ));

  Future<void> sendCommand(
    String token,
    String deviceId,
    String commandType,
  ) async {
    final response = await dio.post(
      'https://phantomtrace-backend-c0if.onrender.com/api/command/send',
      data: {
        'device_id': deviceId,
        'command_type': commandType,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
    if (response.statusCode != 201) {
      throw Exception('Command failed: ${response.statusCode}');
    }
  }
}

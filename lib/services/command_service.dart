import 'package:dio/dio.dart';

class CommandService {
  final Dio dio = Dio();

  Future<void> sendCommand(
    String token,
    String deviceId,
    String commandType,
  ) async {
    await dio.post(
      'http://192.168.1.76:5000/api/command/send',
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
  }
}

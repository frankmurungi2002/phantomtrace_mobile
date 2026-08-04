import 'package:dio/dio.dart';

import '../models/command_result.dart';

class CommandHistoryService {
  final Dio dio = Dio();

  Future<List<CommandResult>> getHistory(
    String token,
    String deviceId,
  ) async {
    final response = await dio.get(
      'https://phantomtrace-backend-c0if.onrender.com/api/command/history/$deviceId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final List results =
        response.data['results'];

    return results
        .map(
          (e) =>
              CommandResult.fromJson(e),
        )
        .toList();
  }
}

import 'package:dio/dio.dart';

import '../models/device.dart';

class DeviceService {
  final Dio dio = Dio();

  Future<List<Device>> getDevices(
    String token,
  ) async {
    final response = await dio.get(
      'http://10.31.49.252:5000/api/device/list',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final List devices =
        response.data['devices'];

    return devices
        .map(
          (e) => Device.fromJson(e),
        )
        .toList();
  }
}

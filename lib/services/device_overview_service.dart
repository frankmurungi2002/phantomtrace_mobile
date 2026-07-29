import 'package:dio/dio.dart';

import '../models/device_overview.dart';

class DeviceOverviewService {
  final Dio dio = Dio();

  Future<DeviceOverview> getOverview(
    String token,
    String deviceId,
  ) async {
    final response = await dio.get(
      'http://192.168.1.76:5000/api/device/overview/$deviceId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    return DeviceOverview.fromJson(
      response.data,
    );
  }
}

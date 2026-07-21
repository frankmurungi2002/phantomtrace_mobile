import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class DeviceService {

  final Dio dio = Dio();

  Future<List<dynamic>> getDevices() async {

    final response = await dio.get(
      '${ApiConstants.baseUrl}/api/device/list',
    );

    return response.data;
  }
}

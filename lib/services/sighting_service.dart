import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/sighting.dart';

class SightingService {
  final Dio dio = Dio();

  Future<List<Sighting>> getSightings(String token, String deviceId) async {
    final response = await dio.get(
      '${ApiConstants.baseUrl}/api/sightings/$deviceId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List data = response.data['sightings'] ?? response.data ?? [];
    return data.map((e) => Sighting.fromJson(e)).toList();
  }
}

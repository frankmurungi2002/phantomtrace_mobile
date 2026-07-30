import 'package:dio/dio.dart';

import '../models/evidence_photo.dart';

class EvidenceService {
  final Dio dio = Dio();

  Future<List<EvidencePhoto>> getPhotos(
    String token,
    String deviceId,
  ) async {
    final response = await dio.get(
      'http://10.31.49.252:5000/api/evidence/photos/$deviceId',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    final List photos =
        response.data['photos'];

    return photos
        .map(
          (e) =>
              EvidencePhoto.fromJson(e),
        )
        .toList();
  }

  Future<void> deletePhoto(String token, String photoId) async {
    await dio.delete(
      'http://10.31.49.252:5000/api/evidence/photo/$photoId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
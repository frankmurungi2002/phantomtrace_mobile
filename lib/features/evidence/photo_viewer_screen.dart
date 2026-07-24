import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String photoId;

  const PhotoViewerScreen({
    super.key,
    required this.photoId,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        'http://127.0.0.1:5000/api/evidence/photo/$photoId';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Screenshot',
        ),
      ),
      body: Center(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          progressIndicatorBuilder:
              (context, url, progress) {
            return CircularProgressIndicator(
              value: progress.progress,
            );
          },
          errorWidget:
              (context, url, error) {
            return const Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}

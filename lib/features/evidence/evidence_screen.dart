import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/evidence_photo.dart';
import '../../services/evidence_service.dart';
import '../../services/token_service.dart';
import 'photo_viewer_screen.dart';

class EvidenceScreen extends StatefulWidget {
  final String deviceId;

  const EvidenceScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<EvidenceScreen> createState() =>
      _EvidenceScreenState();
}

class _EvidenceScreenState
    extends State<EvidenceScreen> {
  Future<List<EvidencePhoto>> loadEvidence() async {
    final token =
        await TokenService().getToken();

    return EvidenceService().getPhotos(
      token!,
      widget.deviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0B0F19,
      ),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF0B0F19,
        ),
        title: const Text(
          'Evidence',
        ),
      ),
      body: FutureBuilder<List<EvidencePhoto>>(
        future: loadEvidence(),
        builder: (
          context,
          snapshot,
        ) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final photos =
              snapshot.data!;

          if (photos.isEmpty) {
            return const Center(
              child: Text(
                'No Evidence Found',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(24),
            itemCount:
                photos.length,
            itemBuilder:
                (context, index) {
              final photo =
                  photos[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PhotoViewerScreen(
                        photoId: photo.id,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin:
                      const EdgeInsets.only(
                    bottom: 16,
                  ),
                  decoration:
                      BoxDecoration(
                    color: const Color(
                      0xFF111827,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.only(
                          topLeft:
                              Radius.circular(
                            20,
                          ),
                          topRight:
                              Radius.circular(
                            20,
                          ),
                        ),
                        child:
                            CachedNetworkImage(
                          imageUrl:
                              'http://127.0.0.1:5000/api/evidence/photo/${photo.id}',
                          height: 140,
                          width:
                              double.infinity,
                          fit: BoxFit.cover,
                          errorWidget:
                              (
                            context,
                            url,
                            error,
                          ) {
                            return Container(
                              height: 140,
                              color:
                                  const Color(
                                0xFF1F2937,
                              ),
                              child:
                                  const Center(
                                child: Icon(
                                  Icons.image,
                                  color:
                                      Colors.white54,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.all(
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color:
                                      Colors.blue,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                const Expanded(
                                  child: Text(
                                    'Screenshot',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          18,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ),
                                if (index == 0)
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          10,
                                      vertical:
                                          4,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          Colors.blue,
                                      borderRadius:
                                          BorderRadius.circular(
                                        999,
                                      ),
                                    ),
                                    child:
                                        const Text(
                                      'LATEST',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize:
                                            11,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Text(
                              DateFormat(
                                'dd MMM yyyy • HH:mm',
                              ).format(
                                DateTime.parse(
                                  photo.timestamp,
                                ),
                              ),
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Row(
                              children: [
                                Text(
                                  'Tap to view',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.blue,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                                SizedBox(
                                  width: 6,
                                ),
                                Icon(
                                  Icons
                                      .arrow_forward_ios,
                                  size: 12,
                                  color:
                                      Colors.blue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

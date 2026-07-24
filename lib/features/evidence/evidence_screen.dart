import 'package:flutter/material.dart';

import '../../models/evidence_photo.dart';
import '../../services/evidence_service.dart';
import '../../services/token_service.dart';

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

  Future<List<EvidencePhoto>>
      loadEvidence() async {

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
      body: FutureBuilder<
          List<EvidencePhoto>>(
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

              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 16,
                ),
                padding:
                    const EdgeInsets.all(
                  20,
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

                    const Text(
                      'Screenshot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      photo.timestamp,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      photo.id,
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Colors.white54,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

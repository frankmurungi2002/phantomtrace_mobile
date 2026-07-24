import 'package:flutter/material.dart';

import '../../models/device_overview.dart';
import '../../services/device_overview_service.dart';
import '../../services/token_service.dart';
import '../evidence/evidence_screen.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailsScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailsScreen> createState() =>
      _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState
    extends State<DeviceDetailsScreen> {
  Future<DeviceOverview> loadOverview() async {
    final token =
        await TokenService().getToken();

    return DeviceOverviewService()
        .getOverview(
      token!,
      widget.deviceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        title: const Text(
          'Device Overview',
        ),
      ),
      body: FutureBuilder<DeviceOverview>(
        future: loadOverview(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final overview =
              snapshot.data!;

          return Padding(
            padding:
                const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Intelligence',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    overview.online
                        ? 'ONLINE'
                        : 'OFFLINE',
                    style: TextStyle(
                      color:
                          overview.online
                              ? Colors.green
                              : Colors.orange,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EvidenceScreen(
                              deviceId:
                                  widget.deviceId,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'View Evidence',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  _section(
                    'System',
                    [
                      _row(
                        'Hostname',
                        overview.hostname,
                      ),
                      _row(
                        'Username',
                        overview.username,
                      ),
                      _row(
                        'OS',
                        overview.osName,
                      ),
                      _row(
                        'Version',
                        overview.osVersion,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _section(
                    'Network',
                    [
                      _row(
                        'IP Address',
                        overview.ipAddress,
                      ),
                      _row(
                        'MAC Address',
                        overview.macAddress,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _section(
                    'Storage',
                    [
                      _row(
                        'Free Disk',
                        '${overview.freeGb} GB',
                      ),
                      _row(
                        'Used Disk',
                        '${overview.usedGb} GB',
                      ),
                      _row(
                        'Total Disk',
                        '${overview.totalGb} GB',
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  _section(
                    'Activity',
                    [
                      _row(
                        'Processes',
                        overview
                            .processCount
                            .toString(),
                      ),
                      _row(
                        'Commands',
                        overview
                            .commandCount
                            .toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius:
            BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

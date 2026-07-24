import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/device_overview.dart';
import '../../services/device_overview_service.dart';
import '../../services/token_service.dart';
import '../commands/command_center_screen.dart';
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
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Device Overview',
        ),
      ),
      body: FutureBuilder<DeviceOverview>(
        future: loadOverview(),
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

          final overview =
              snapshot.data!;

          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(
              20,
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'DEVICE INTELLIGENCE',
                        style: TextStyle(
                          color: AppColors
                              .textSecondary,
                          letterSpacing: 2,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        overview.hostname,
                        style:
                            const TextStyle(
                          fontSize: 30,
                          fontWeight:
                              FontWeight.w800,
                          color: AppColors
                              .textPrimary,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration:
                                BoxDecoration(
                              color: overview
                                      .online
                                  ? AppColors
                                      .success
                                  : AppColors
                                      .warning,
                              shape: BoxShape
                                  .circle,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Text(
                            overview.online
                                ? 'ONLINE'
                                : 'OFFLINE',
                            style:
                                TextStyle(
                              color: overview
                                      .online
                                  ? AppColors
                                      .success
                                  : AppColors
                                      .warning,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          ElevatedButton(
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
                          'Evidence',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CommandCenterScreen(
                                deviceId:
                                    widget.deviceId,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Commands',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'Processes',
                        overview
                            .processCount
                            .toString(),
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child: _metricCard(
                        'Commands',
                        overview
                            .commandCount
                            .toString(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                _section(
                  'SYSTEM',
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
                      'Operating System',
                      overview.osName,
                    ),
                    _row(
                      'Version',
                      overview.osVersion,
                    ),
                  ],
                ),

                const SizedBox(
                  height: 16,
                ),

                _section(
                  'NETWORK',
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
                  height: 16,
                ),

                _section(
                  'STORAGE',
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
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color:
                  AppColors.textSecondary,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textPrimary,
            ),
          ),
        ],
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
        color: AppColors.surface,
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
              fontSize: 16,
              letterSpacing: 1.5,
              color:
                  AppColors.textPrimary,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
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
        vertical: 10,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors
                    .textSecondary,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color:
                    AppColors.textPrimary,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

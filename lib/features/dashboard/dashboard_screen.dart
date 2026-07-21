import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import '../../services/token_service.dart';
import '../devices/device_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {

  Future<List<Device>> loadDevices() async {
    final token =
        await TokenService().getToken();

    if (token == null) {
      return [];
    }

    return DeviceService().getDevices(token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Device>>(
        future: loadDevices(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final devices = snapshot.data!;

          if (devices.isEmpty) {
            return const Center(
              child: Text(
                'No Devices Found',
              ),
            );
          }

          final device = devices.first;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(36),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'PHANTOMTRACE',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 4,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Security Operations',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 32),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF111827),
                        borderRadius:
                            BorderRadius.circular(
                          28,
                        ),
                        border: Border.all(
                          color:
                              const Color(0xFF1F2937),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          const Text(
                            'ACTIVE ENDPOINT',
                            style: TextStyle(
                              color:
                                  Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),

                          const Spacer(),

                          Text(
                            '${devices.length}',
                            style: const TextStyle(
                              fontSize: 120,
                              height: 1,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),

                          const Text(
                            'Protected Devices',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Text(
                            'Status: ${device.status}',
                            style: const TextStyle(
                              color:
                                  Colors.white70,
                            ),
                          ),

                          const Spacer(),

                          InkWell(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              22,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const DeviceDetailsScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets
                                      .all(22),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFF0B0F19,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  22,
                                ),
                              ),
                              child: Row(
                                children: [

                                  Icon(
                                    Icons.computer,
                                    color: device
                                            .online
                                        ? Colors.green
                                        : Colors.orange,
                                  ),

                                  const SizedBox(
                                      width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [

                                        Text(
                                          device
                                              .deviceName,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                18,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                          ),
                                        ),

                                        const SizedBox(
                                            height:
                                                4),

                                        Text(
                                          device
                                              .status,
                                          style:
                                              const TextStyle(
                                            color: Colors
                                                .white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Text(
                                    device.online
                                        ? 'ONLINE'
                                        : 'OFFLINE',
                                    style:
                                        TextStyle(
                                      color: device
                                              .online
                                          ? Colors
                                              .green
                                          : Colors
                                              .orange,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

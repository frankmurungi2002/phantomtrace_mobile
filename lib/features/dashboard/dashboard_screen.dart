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

    return DeviceService().getDevices(
      token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0F19),
      body: FutureBuilder<List<Device>>(
        future: loadDevices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final devices =
              snapshot.data!;

          if (devices.isEmpty) {
            return const Center(
              child: Text(
                'No Devices Found',
              ),
            );
          }

          final device =
              devices.first;

          final onlineCount =
              devices
                  .where(
                    (d) => d.online,
                  )
                  .length;

          return SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'PHANTOMTRACE',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 4,
                      color:
                          Colors.white70,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Security Operations',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .all(24),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF111827,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        24,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Devices',
                                style:
                                    TextStyle(
                                  color: Colors
                                      .white70,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                '${devices.length}',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      32,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .center,
                            children: [
                              const Text(
                                'Online',
                                style:
                                    TextStyle(
                                  color: Colors
                                      .white70,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                '$onlineCount',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      32,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .end,
                            children: [
                              const Text(
                                'Coverage',
                                style:
                                    TextStyle(
                                  color: Colors
                                      .white70,
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              const Text(
                                '100%',
                                style:
                                    TextStyle(
                                  fontSize:
                                      32,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets
                            .all(28),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFF111827,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        24,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'ACTIVE ENDPOINT',
                          style:
                              TextStyle(
                            color: Colors
                                .white70,
                            letterSpacing:
                                2,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        Text(
                          device.deviceName,
                          style:
                              const TextStyle(
                            fontSize: 30,
                            fontWeight:
                                FontWeight
                                    .w800,
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
                                color: device
                                        .online
                                    ? Colors
                                        .green
                                    : Colors
                                        .orange,
                                shape: BoxShape
                                    .circle,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
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

                        const SizedBox(
                          height: 12,
                        ),

                        Text(
                          'Last Seen: ${device.lastSeen}',
                          style:
                              const TextStyle(
                            color: Colors
                                .white70,
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          child:
                              ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DeviceDetailsScreen(
                                    deviceId:
                                        device
                                            .id,
                                  ),
                                ),
                              );
                            },
                            child:
                                const Text(
                              'Open Device',
                            ),
                          ),
                        ),
                      ],
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

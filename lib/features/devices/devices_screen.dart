import 'package:flutter/material.dart';

import '../../models/device.dart';
import '../../services/device_service.dart';
import '../../services/token_service.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() =>
      _DevicesScreenState();
}

class _DevicesScreenState
    extends State<DevicesScreen> {

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
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              const Text(
                'Devices',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Monitor every protected endpoint.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: FutureBuilder<List<Device>>(
                  future: loadDevices(),
                  builder:
                      (context, snapshot) {

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

                    return ListView.builder(
                      itemCount:
                          devices.length,
                      itemBuilder:
                          (context, index) {

                        final device =
                            devices[index];

                        return Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 16,
                          ),
                          padding:
                              const EdgeInsets.all(
                            24,
                          ),
                          decoration:
                              BoxDecoration(
                            color: const Color(
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

                              Container(
                                width: 58,
                                height: 58,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      device.online
                                          ? const Color(
                                              0x3322C55E)
                                          : const Color(
                                              0x33F59E0B),
                                  shape:
                                      BoxShape
                                          .circle,
                                ),
                                child: Icon(
                                  Icons.laptop,
                                  color: device
                                          .online
                                      ? const Color(
                                          0xFF22C55E)
                                      : Colors
                                          .orange,
                                ),
                              ),

                              const SizedBox(
                                  width: 18),

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
                                        color: Colors
                                            .white,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    Text(
                                      device.status,
                                      style:
                                          const TextStyle(
                                        color: Colors
                                            .white70,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    Text(
                                      device.online
                                          ? 'ONLINE'
                                          : 'OFFLINE',
                                      style:
                                          TextStyle(
                                        color: device
                                                .online
                                            ? const Color(
                                                0xFF22C55E)
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

                              const Icon(
                                Icons
                                    .chevron_right,
                                color:
                                    Colors.white70,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

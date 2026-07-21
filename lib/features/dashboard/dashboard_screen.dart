import 'package:flutter/material.dart';
import '../devices/device_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE ENDPOINT',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),

                      const Spacer(),

                      const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 120,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const Text(
                        'Device Online',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'All systems operational',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),

                      const Spacer(),

                      InkWell(
                        borderRadius: BorderRadius.circular(22),
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
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0F19),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.computer,
                                color: Colors.green,
                              ),

                              SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Francis Laptop',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),

                                    SizedBox(height: 4),

                                    Text(
                                      'Kali Linux',
                                      style: TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Text(
                                'ONLINE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                      FontWeight.w700,
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
      ),
    );
  }
}

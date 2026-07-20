import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              const Text(
                'Good Afternoon, Francis',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Monitor and manage your endpoints.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                ),

                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Endpoint Overview',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 16),

                    Text(
                      '1',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    Text(
                      'Device Online',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Devices',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                ),

                child: const Row(
                  children: [

                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF3B82F6),
                      child: Icon(Icons.computer),
                    ),

                    SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            'Francis Laptop',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            'Linux • Online',
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.chevron_right,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

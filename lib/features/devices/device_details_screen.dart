import 'package:flutter/material.dart';

class DeviceDetailsScreen extends StatelessWidget {
  const DeviceDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        title: const Text(
          'Device Overview',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Francis Laptop',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'ONLINE',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF1F2937),
                  ),
                ),
                child: Column(
                  children: [

                    _row('Hostname', 'FrankKali'),

                    _row(
                      'Operating System',
                      'Kali Linux',
                    ),

                    _row('Username', 'root'),

                    _row(
                      'IP Address',
                      '127.0.1.1',
                    ),

                    const Divider(
                      color: Colors.white24,
                    ),

                    _row('Processes', '100'),

                    _row(
                      'Free Disk',
                      '27.56 GB',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _row(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Row(
        children: [

          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

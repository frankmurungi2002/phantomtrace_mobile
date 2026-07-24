import 'package:flutter/material.dart';

import '../../services/command_service.dart';
import '../../services/token_service.dart';

class CommandCenterScreen extends StatelessWidget {
  final String deviceId;

  const CommandCenterScreen({
    super.key,
    required this.deviceId,
  });

  Future<void> sendCommand(
    BuildContext context,
    String command,
  ) async {
    final token =
        await TokenService().getToken();

    await CommandService().sendCommand(
      token!,
      deviceId,
      command,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$command queued',
          ),
        ),
      );
    }
  }

  Widget commandButton(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () =>
            sendCommand(
          context,
          title,
        ),
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B0F19),
        title: const Text(
          'Command Center',
        ),
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          children: [
            commandButton(
              context,
              'PING',
              Icons.wifi,
            ),

            const SizedBox(height: 12),

            commandButton(
              context,
              'SYSTEM_INFO',
              Icons.computer,
            ),

            const SizedBox(height: 12),

            commandButton(
              context,
              'GET_NETWORK',
              Icons.network_check,
            ),

            const SizedBox(height: 12),

            commandButton(
              context,
              'GET_DISKS',
              Icons.storage,
            ),

            const SizedBox(height: 12),

            commandButton(
              context,
              'GET_PROCESSES',
              Icons.memory,
            ),

            const SizedBox(height: 12),

            commandButton(
              context,
              'SCREENSHOT',
              Icons.camera_alt,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/command_service.dart';
import '../../services/token_service.dart';
import 'command_history_screen.dart';

class CommandCenterScreen extends StatefulWidget {
  final String deviceId;
  const CommandCenterScreen({super.key, required this.deviceId});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
  String? _loadingCommand;

  Future<void> sendCommand(String command) async {
    setState(() => _loadingCommand = command);
    try {
      final token = await TokenService().getToken();
      await CommandService().sendCommand(token!, widget.deviceId, command);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 2),
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('$command sent successfully',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text('Failed to send $command',
                  style: const TextStyle(color: Colors.white)),
            ]),
          ),
        );
      }
    }
    if (mounted) setState(() => _loadingCommand = null);
  }

  Widget commandCard(
    String title,
    String subtitle,
    IconData icon, {
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primary;
    final isLoading = _loadingCommand == title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isLoading || _loadingCommand != null ? null : () => sendCommand(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLoading ? color.withAlpha(30) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLoading ? color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(isLoading ? 60 : 30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLoading ? color : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoading ? 'Sending...' : subtitle,
                    style: TextStyle(
                      color: isLoading ? color.withAlpha(180) : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? const SizedBox(width: 14)
                : const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textSecondary, size: 14),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Command Center')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('REMOTE OPERATIONS',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              const Text('Execute commands on the endpoint.',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    commandCard('PING', 'Check device is alive', Icons.wifi),
                    commandCard('SYSTEM_INFO', 'Collect system details', Icons.computer),
                    commandCard('GET_NETWORK', 'Retrieve network information', Icons.network_check),
                    commandCard('GET_DISKS', 'Analyze storage usage', Icons.storage),
                    commandCard('GET_PROCESSES', 'Inspect running processes', Icons.memory),
                    commandCard('GET_LOCATION', 'Get current location', Icons.location_on),
                    commandCard('PHOTO', 'Capture thief face via webcam',
                        Icons.face_retouching_natural, accentColor: Colors.red),
                    commandCard('SCREENSHOT', 'Capture screen evidence',
                        Icons.screenshot_monitor, accentColor: Colors.blue),
                    commandCard('LOCK', 'Lock device immediately',
                        Icons.lock, accentColor: Colors.orange),
                    commandCard('ALARM', 'Trigger loud alarm at max volume',
                        Icons.volume_up, accentColor: Colors.red),
                    commandCard('STOP_ALARM', 'Stop the alarm',
                        Icons.volume_off, accentColor: Colors.green),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CommandHistoryScreen(deviceId: widget.deviceId)),
                      ),
                      icon: const Icon(Icons.history),
                      label: const Text('Command History'),
                    ),
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

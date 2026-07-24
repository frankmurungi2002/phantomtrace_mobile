import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/command_service.dart';
import '../../services/token_service.dart';
import 'command_history_screen.dart';

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
          backgroundColor:
              AppColors.surface,
          content: Text(
            '$command queued',
            style: const TextStyle(
              color:
                  AppColors.textPrimary,
            ),
          ),
        ),
      );
    }
  }

  Widget commandCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(20),
      onTap: () => sendCommand(
        context,
        title,
      ),
      child: Container(
        padding:
            const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(
                color: AppColors
                    .primary
                    .withAlpha(30),
                borderRadius:
                    BorderRadius
                        .circular(
                  14,
                ),
              ),
              child: Icon(
                icon,
                color:
                    AppColors.primary,
              ),
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      color: AppColors
                          .textPrimary,
                      fontSize: 16,
                      fontWeight:
                          FontWeight
                              .w700,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      color: AppColors
                          .textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .arrow_forward_ios,
              color:
                  AppColors
                      .textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Command Center',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.all(
            20,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const Text(
                'REMOTE OPERATIONS',
                style: TextStyle(
                  color: AppColors
                      .textSecondary,
                  letterSpacing: 2,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                'Execute commands on the endpoint.',
                style: TextStyle(
                  color: AppColors
                      .textSecondary,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Expanded(
                child: ListView(
                  children: [
                    commandCard(
                      context,
                      'PING',
                      'Check device status',
                      Icons.wifi,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    commandCard(
                      context,
                      'SYSTEM_INFO',
                      'Collect system details',
                      Icons.computer,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    commandCard(
                      context,
                      'GET_NETWORK',
                      'Retrieve network information',
                      Icons.network_check,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    commandCard(
                      context,
                      'GET_DISKS',
                      'Analyze storage usage',
                      Icons.storage,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    commandCard(
                      context,
                      'GET_PROCESSES',
                      'Inspect running processes',
                      Icons.memory,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    commandCard(
                      context,
                      'SCREENSHOT',
                      'Capture screen evidence',
                      Icons.camera_alt,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CommandHistoryScreen(
                              deviceId:
                                  deviceId,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.history,
                      ),
                      label: const Text(
                        'Command History',
                      ),
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

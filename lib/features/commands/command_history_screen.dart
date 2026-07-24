
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/command_result.dart';
import '../../services/command_history_service.dart';
import '../../services/token_service.dart';

class CommandHistoryScreen extends StatefulWidget {
  final String deviceId;

  const CommandHistoryScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<CommandHistoryScreen> createState() =>
      _CommandHistoryScreenState();
}

class _CommandHistoryScreenState
    extends State<CommandHistoryScreen> {
  Future<List<CommandResult>> loadHistory() async {
    final token =
        await TokenService().getToken();

    return CommandHistoryService()
        .getHistory(
      token!,
      widget.deviceId,
    );
  }

  IconData getIcon(String command) {
    switch (command) {
      case 'SCREENSHOT':
        return Icons.camera_alt;
      case 'GET_NETWORK':
        return Icons.network_check;
      case 'GET_DISKS':
        return Icons.storage;
      case 'GET_PROCESSES':
        return Icons.memory;
      case 'PING':
        return Icons.wifi;
      default:
        return Icons.terminal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text('Command History'),
      ),
      body: FutureBuilder<List<CommandResult>>(
        future: loadHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final results = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 16,
                ),
                padding: const EdgeInsets.all(
                  20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getIcon(
                            item.commandType,
                          ),
                          color: Colors.blue,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(
                            item.commandType,
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withOpacity(0.2),
                        borderRadius:
                            BorderRadius.circular(
                          999,
                        ),
                      ),
                      child: Text(
                        item.result,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

Text(
  DateFormat(
    'dd MMM yyyy • HH:mm',
  ).format(
    DateTime.parse(
      item.executedAt,
    ),
  ),
  style: const TextStyle(
    color: Colors.white70,
    fontSize: 12,
  ),
),                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

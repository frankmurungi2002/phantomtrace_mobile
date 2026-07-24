import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B0F19),
        title: const Text(
          'Command History',
        ),
      ),
      body: FutureBuilder<
          List<CommandResult>>(
        future: loadHistory(),
        builder: (
          context,
          snapshot,
        ) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final results =
              snapshot.data!;

          return ListView.builder(
            padding:
                const EdgeInsets.all(24),
            itemCount:
                results.length,
            itemBuilder:
                (context, index) {
              final item =
                  results[index];

              return Container(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFF111827,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      item.commandType,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      item.result,
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      item.executedAt,
                      style:
                          const TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

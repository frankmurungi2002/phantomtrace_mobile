class CommandResult {
  final String commandType;
  final String result;
  final String executedAt;

  CommandResult({
    required this.commandType,
    required this.result,
    required this.executedAt,
  });

  factory CommandResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return CommandResult(
      commandType:
          json['command_type'] ?? '',
      result:
          json['result'] ?? '',
      executedAt:
          json['executed_at'] ?? '',
    );
  }

}

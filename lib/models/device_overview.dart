class DeviceOverview {
  final bool online;
  final int processCount;
  final int commandCount;

  final String hostname;
  final String username;
  final String osName;
  final String osVersion;

  final String ipAddress;
  final String macAddress;

  final String freeGb;
  final String usedGb;
  final String totalGb;

  DeviceOverview({
    required this.online,
    required this.processCount,
    required this.commandCount,
    required this.hostname,
    required this.username,
    required this.osName,
    required this.osVersion,
    required this.ipAddress,
    required this.macAddress,
    required this.freeGb,
    required this.usedGb,
    required this.totalGb,
  });

  factory DeviceOverview.fromJson(
    Map<String, dynamic> json,
  ) {
    return DeviceOverview(
      online: json['online'] ?? false,
      processCount: json['process_count'] ?? 0,
      commandCount: json['command_count'] ?? 0,

      hostname:
          json['system_info']['hostname'] ?? '',

      username:
          json['system_info']['username'] ?? '',

      osName:
          json['system_info']['os_name'] ?? '',

      osVersion:
          json['system_info']['os_version'] ?? '',

      ipAddress:
          json['network_info']['ip_address'] ?? '',

      macAddress:
          json['network_info']['mac_address'] ?? '',

      freeGb:
          json['disk_info']['free_gb'] ?? '',

      usedGb:
          json['disk_info']['used_gb'] ?? '',

      totalGb:
          json['disk_info']['total_gb'] ?? '',
    );
  }
}

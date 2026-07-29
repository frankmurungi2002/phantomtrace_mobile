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
  final double? latitude;
  final double? longitude;
  final String city;
  final String area;
  final String country;
  final String isp;
  final String locationIp;

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
    this.latitude,
    this.longitude,
    required this.city,
    required this.area,
    required this.country,
    required this.isp,
    required this.locationIp,
  });

  factory DeviceOverview.fromJson(Map<String, dynamic> json) {
    final systemInfo = json['system_info'] as Map<String, dynamic>? ?? {};
    final networkInfo = json['network_info'] as Map<String, dynamic>? ?? {};
    final diskInfo = json['disk_info'] as Map<String, dynamic>? ?? {};
    final locationInfo = json['location_info'] as Map<String, dynamic>? ?? {};

    return DeviceOverview(
      online: json['online'] ?? false,
      processCount: json['process_count'] ?? 0,
      commandCount: json['command_count'] ?? 0,
      hostname: systemInfo['hostname'] ?? 'Not reported',
      username: systemInfo['username'] ?? 'Not reported',
      osName: systemInfo['os_name'] ?? 'Not reported',
      osVersion: systemInfo['os_version'] ?? 'Not reported',
      ipAddress: networkInfo['ip_address'] ?? 'Not reported',
      macAddress: networkInfo['mac_address'] ?? 'Not reported',
      freeGb: diskInfo['free_gb']?.toString() ?? '—',
      usedGb: diskInfo['used_gb']?.toString() ?? '—',
      totalGb: diskInfo['total_gb']?.toString() ?? '—',
      latitude: (locationInfo['latitude'] as num?)?.toDouble(),
      longitude: (locationInfo['longitude'] as num?)?.toDouble(),
      city: locationInfo['city'] ?? 'Not reported',
      area: locationInfo['area'] ?? '',
      country: locationInfo['country'] ?? 'Not reported',
      isp: locationInfo['isp'] ?? 'Not reported',
      locationIp: locationInfo['ip_address'] ?? 'Not reported',
    );
  }
}

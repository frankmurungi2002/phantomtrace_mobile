class Device {
  final String id;
  final String deviceName;
  final bool online;
  final String status;
  final String lastSeen;

  Device({
    required this.id,
    required this.deviceName,
    required this.online,
    required this.status,
    required this.lastSeen,
  });

  factory Device.fromJson(
    Map<String, dynamic> json,
  ) {
    return Device(
      id: json['id'] ?? '',
      deviceName:
          json['device_name'] ?? 'Unknown Device',
      online: json['online'] ?? false,
      status: json['status'] ?? 'UNKNOWN',
      lastSeen: json['last_seen'] ?? '',
    );
  }
}

class Device {
  final String id;
  final String deviceName;
  final bool online;
  final String status;
  final String lastSeen;
  final bool biosProtected;
  final String? biosManufacturer;
  final String? biosModel;

  Device({
    required this.id,
    required this.deviceName,
    required this.online,
    required this.status,
    required this.lastSeen,
    this.biosProtected = false,
    this.biosManufacturer,
    this.biosModel,
  });

  factory Device.fromJson(
    Map<String, dynamic> json,
  ) {
    return Device(
      id: json['id'] ?? '',
      deviceName: json['device_name'] ?? 'Unknown Device',
      online: json['online'] ?? false,
      status: json['status'] ?? 'UNKNOWN',
      lastSeen: json['last_seen'] ?? '',
      biosProtected: json['bios_protected'] == true,
      biosManufacturer: json['bios_manufacturer'],
      biosModel: json['bios_model'],
    );
  }
}

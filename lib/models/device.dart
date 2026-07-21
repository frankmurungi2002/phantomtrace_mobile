class Device {
  final String id;
  final String hostname;
  final bool online;

  Device({
    required this.id,
    required this.hostname,
    required this.online,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      hostname: json['hostname'] ?? 'Unknown Device',
      online: json['online'] ?? false,
    );
  }
}

/// One point on a device's location trail, as returned by
/// `GET /api/sightings/<deviceId>`.
class Sighting {
  final String id;
  final double latitude;
  final double longitude;
  final String city;
  final String area;
  final String country;
  final String isp;
  final String ipAddress;
  final String method;
  final DateTime? timestamp;

  Sighting({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.area,
    required this.country,
    required this.isp,
    required this.ipAddress,
    required this.method,
    this.timestamp,
  });

  /// "Kampala Road, Kampala, Uganda" — skips blank and "Unknown" parts.
  String get placeName {
    final parts = [area, city, country]
        .where((p) => p.trim().isNotEmpty && p != 'Unknown')
        .toList();
    return parts.isEmpty ? 'Unknown place' : parts.join(', ');
  }

  factory Sighting.fromJson(Map<String, dynamic> json) {
    return Sighting(
      id: json['id']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      city: json['city'] ?? 'Unknown',
      area: json['area'] ?? '',
      country: json['country'] ?? 'Unknown',
      isp: json['isp'] ?? 'Unknown',
      ipAddress: json['ip_address'] ?? 'Unknown',
      method: json['method'] ?? 'WIFI',
      timestamp: _parseUtc(json['timestamp']),
    );
  }

  /// The backend sends naive UTC ISO strings (no "Z"); treat them as UTC.
  static DateTime? _parseUtc(dynamic v) {
    if (v is! String || v.isEmpty) return null;
    final hasZone = v.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(v);
    return DateTime.tryParse(hasZone ? v : '${v}Z')?.toLocal();
  }
}

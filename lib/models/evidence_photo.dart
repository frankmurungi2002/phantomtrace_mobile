class EvidencePhoto {
  final String id;
  final String timestamp;
  final String filePath;

  EvidencePhoto({
    required this.id,
    required this.timestamp,
    required this.filePath,
  });

  factory EvidencePhoto.fromJson(
    Map<String, dynamic> json,
  ) {
    return EvidencePhoto(
      id: json['id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      filePath: json['file_path'] ?? '',
    );
  }
}

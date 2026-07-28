class EvidencePhoto {
  final String id;
  final String timestamp;
  final String filePath;
  final String photoType;

  EvidencePhoto({
    required this.id,
    required this.timestamp,
    required this.filePath,
    required this.photoType,
  });

  factory EvidencePhoto.fromJson(Map<String, dynamic> json) {
    return EvidencePhoto(
      id: json['id'] ?? '',
      timestamp: json['timestamp'] ?? '',
      filePath: json['file_path'] ?? '',
      photoType: json['photo_type'] ?? 'SCREENSHOT',
    );
  }
}

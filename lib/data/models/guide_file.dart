class GuideFile {
  const GuideFile({
    required this.id,
    required this.fileName,
    required this.fileBase64,
    required this.uploadedBy,
    this.createdAt,
  });

  final String id;
  final String fileName;
  final String fileBase64;
  final String uploadedBy;
  final DateTime? createdAt;

  factory GuideFile.fromMap(Map<String, dynamic> map) {
    return GuideFile(
      id: (map['id'] ?? '') as String,
      fileName: (map['file_name'] ?? '') as String,
      fileBase64: (map['file_base64'] ?? '') as String,
      uploadedBy: (map['uploaded_by'] ?? '') as String,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }
}

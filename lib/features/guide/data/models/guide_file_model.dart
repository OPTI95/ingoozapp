import '../../domain/entities/guide_file.dart';

class GuideFileModel extends GuideFile {
  const GuideFileModel({
    required super.id,
    required super.title,
    super.fileUrl,
    super.order,
    super.createdAt,
  });

  factory GuideFileModel.fromJson(Map<String, dynamic> json) {
    return GuideFileModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      order: (json['order'] as num?)?.toInt() ?? 0,
      createdAt: _date(json['created_at']),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

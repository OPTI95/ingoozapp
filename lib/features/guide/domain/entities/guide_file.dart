import 'package:equatable/equatable.dart';

/// A published driver-guide document (`GET /guide/`).
class GuideFile extends Equatable {
  const GuideFile({
    required this.id,
    required this.title,
    this.fileUrl,
    this.order = 0,
    this.createdAt,
  });

  final int id;
  final String title;
  final String? fileUrl;
  final int order;
  final DateTime? createdAt;

  bool get hasFile => (fileUrl ?? '').isNotEmpty;

  @override
  List<Object?> get props => [id, title, fileUrl, order, createdAt];
}

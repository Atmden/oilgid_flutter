import '../../../../core/utils/parsers.dart';
import '../../domain/entities/app_notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.kind,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
    super.url,
    super.imageUrl,
    super.pushLogId,
    super.readAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      url: _nonEmpty(json['url']),
      imageUrl: _nonEmpty(json['image_url']),
      pushLogId: toIntSafe(json['push_log_id']),
      isRead: json['is_read'] == true,
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static String? _nonEmpty(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal();
  }
}

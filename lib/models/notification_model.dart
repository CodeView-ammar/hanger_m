class NotificationModel {
  final int id;
  final String message;
  final String status;
  final bool isRead;
  final DateTime createdAt;
  final int userId;

  NotificationModel({
    required this.id,
    required this.message,
    required this.status,
    required this.isRead,
    required this.createdAt,
    required this.userId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['message'],
      status: json['status'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      userId: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'status': status,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'user': userId,
    };
  }
}

class NotificationStatus {
  static const String error = 'error';
  static const String confirmation = 'confirmation';
  static const String alert = 'alert';
}
class SupportTicket {
  final int id;
  final String title;
  final String category;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int userId;
  final String userName;
  final int unreadMessagesCount;
  final List<SupportMessage> messages;

  SupportTicket({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.userName,
    required this.unreadMessagesCount,
    required this.messages,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      priority: json['priority'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      userId: json['user']['id'],
      userName: json['user_name'],
      unreadMessagesCount: json['unread_messages_count'] ?? 0,
      messages: (json['messages'] as List?)
          ?.map((msg) => SupportMessage.fromJson(msg))
          .toList() ?? [],
    );
  }
}

class SupportMessage {
  final int id;
  final int ticketId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final bool isRead;
  final String senderName;
  final int senderId;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    required this.isRead,
    required this.senderName,
    required this.senderId,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      ticketId: json['ticket'],
      content: json['content'],
      messageType: json['message_type'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      senderName: json['sender_name'],
      senderId: json['sender']['id'],
    );
  }
}

class SupportCategories {
  static const String general = 'general';
  static const String technical = 'technical';
  static const String billing = 'billing';
  static const String order = 'order';
  static const String complaint = 'complaint';
  static const String suggestion = 'suggestion';
}

class SupportPriorities {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';
}

class SupportStatus {
  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
}
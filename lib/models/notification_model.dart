import 'package:firebase_messaging/firebase_messaging.dart';

/// Notification model for storing Firebase notifications locally
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String? orderId;
  final DateTime receivedAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.orderId,
    required this.receivedAt,
    this.isRead = false,
  });

  /// Create from RemoteMessage (Firebase)
  factory NotificationItem.fromRemoteMessage(RemoteMessage message) {
    return NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'Notifikasi Baru',
      body: message.notification?.body ?? '',
      orderId: message.data['order_id'],
      receivedAt: message.sentTime ?? DateTime.now(),
    );
  }

  /// Create from JSON (for persistence)
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      orderId: json['order_id'],
      receivedAt: DateTime.tryParse(json['received_at'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }

  /// Convert to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'order_id': orderId,
      'received_at': receivedAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Get formatted time string (e.g., "5 menit lalu", "2 jam lalu", "Kemarin")
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(receivedAt);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      // Format as date
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${receivedAt.day} ${months[receivedAt.month - 1]}';
    }
  }

  /// Check if notification is about a new order
  bool get isOrderNotification => orderId != null;
}

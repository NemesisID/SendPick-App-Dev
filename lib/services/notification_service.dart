import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiClient _apiClient = ApiClient();

  // Simpan FCM Token
  String? fcmToken;

  // Callback untuk navigasi saat notifikasi di-tap
  Function(String?)? onNotificationTap;

  // Callback untuk update UI saat ada notifikasi baru
  VoidCallback? onNotificationReceived;

  // Store notifications locally
  final List<NotificationItem> _notifications = [];

  /// Get all notifications (newest first)
  List<NotificationItem> get notifications => 
      List.unmodifiable(_notifications.reversed.toList());

  /// Get unread notification count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Check if there are any notifications
  bool get hasNotifications => _notifications.isNotEmpty;

  /// Inisialisasi service
  Future<void> initialize() async {
    // Request permission (untuk iOS & Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Permission status: ${settings.authorizationStatus}');

    // Get FCM Token
    fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $fcmToken');

    // Listen untuk token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      fcmToken = newToken;
      debugPrint('FCM Token refreshed: $newToken');
      // Kirim token baru ke API saat refresh
      sendTokenToServer(newToken);
    });

    // Setup local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel untuk Android
    await _createNotificationChannel();

    // Listen untuk foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listen untuk user tap notifikasi (dari background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check apakah app dibuka dari notifikasi (saat terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Create notification channel untuk Android 8+
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_channel', // id
      'Order Notifications', // title
      description: 'Notifikasi untuk order baru',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Dapatkan FCM Token untuk dikirim ke API
  Future<String?> getToken() async {
    fcmToken ??= await _messaging.getToken();
    return fcmToken;
  }

  /// Kirim FCM Token ke server untuk push notification
  /// Dipanggil setelah login dan saat token refresh
  Future<bool> sendTokenToServer(String? token) async {
    if (token == null || token.isEmpty) {
      debugPrint('FCM Token is null or empty, skipping server update');
      return false;
    }

    try {
      final response = await _apiClient.put(
        ApiConfig.fcmTokenEndpoint,
        body: {'fcm_token': token},
      );
      
      if (response.success) {
        debugPrint('FCM Token berhasil dikirim ke server');
        return true;
      } else {
        debugPrint('Gagal mengirim FCM Token: ${response.message}');
        return false;
      }
    } on ApiError catch (e) {
      debugPrint('Error mengirim FCM Token: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Error tidak terduga saat mengirim FCM Token: $e');
      return false;
    }
  }

  /// Handle pesan saat app di foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    debugPrint('Data: ${message.data}');

    // Store notification locally
    final notification = NotificationItem.fromRemoteMessage(message);
    _notifications.add(notification);

    // Notify listeners that a new notification was received
    onNotificationReceived?.call();

    // Tampilkan local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'Notifikasi Baru',
      body: message.notification?.body ?? '',
      payload: message.data['order_id'],
    );
  }

  /// Handle saat user tap notifikasi
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('User tapped notification: ${message.data}');

    // Store notification if not already stored
    final notification = NotificationItem.fromRemoteMessage(message);
    if (!_notifications.any((n) => n.id == notification.id)) {
      _notifications.add(notification);
    }

    // Mark as read since user tapped it
    markAsRead(notification.id);

    // Navigate ke halaman order detail
    String? orderId = message.data['order_id'];
    if (onNotificationTap != null) {
      onNotificationTap!(orderId);
    }
  }

  /// Handle tap pada local notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (onNotificationTap != null) {
      onNotificationTap!(response.payload);
    }
  }

  /// Tampilkan local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      channelDescription: 'Notifikasi untuk order baru',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  /// Set callback untuk handle notifikasi tap
  void setOnNotificationTap(Function(String?) callback) {
    onNotificationTap = callback;
  }

  /// Set callback untuk update UI saat ada notifikasi baru
  void setOnNotificationReceived(VoidCallback callback) {
    onNotificationReceived = callback;
  }

  /// Mark a notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
    }
  }

  /// Mark all notifications as read
  void markAllAsRead() {
    for (var notification in _notifications) {
      notification.isRead = true;
    }
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
  }

  /// Remove a specific notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
  }
}

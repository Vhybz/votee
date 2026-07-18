import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'push_notification_service.dart';

class SystemNotification {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  SystemNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory SystemNotification.fromJson(Map<String, dynamic> json) {
    return SystemNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }
}

class NotificationNotifier extends StateNotifier<List<SystemNotification>> {
  final Ref ref;

  NotificationNotifier(this.ref) : super([]);

  Future<void> loadNotifications() async {
    // Logic to fetch notifications from Supabase
  }

  void addNotification(String title, String message) async {
    final notification = SystemNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );
    
    state = [notification, ...state];

    PushNotificationService.showNotification(
      id: notification.createdAt.millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
    );
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<SystemNotification>>((ref) {
  return NotificationNotifier(ref);
});

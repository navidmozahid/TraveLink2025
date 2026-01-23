import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final supabase = Supabase.instance.client;

  // CREATE NOTIFICATION
  Future<void> createNotification({
    required String userId,      // receiver
    required String actorId,     // sender
    required String type,
    String? postId,
  }) async {
    if (userId == actorId) return; // prevent self notification

    await supabase.from('notifications').insert({
      'user_id': userId,
      'from_user_id': actorId, // IMPORTANT: matches notification screen
      'type': type,
      'post_id': postId,
      'is_read': false,
    });
  }

  // MARK SINGLE NOTIFICATION AS READ
  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // MARK ALL AS READ (optional, not used yet)
  Future<void> markAllAsRead(String userId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }
}

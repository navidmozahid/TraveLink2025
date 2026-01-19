import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final supabase = Supabase.instance.client;

  // CREATE NOTIFICATION
  Future<void> createNotification({
    required String userId,
    required String actorId,
    required String type,
    String? postId,
  }) async {
    if (userId == actorId) return; // no self notifications

    await supabase.from('notifications').insert({
      'user_id': userId,
      'actor_id': actorId,
      'type': type,
      'post_id': postId,
    });
  }

  // MARK AS READ
  Future<void> markAsRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}

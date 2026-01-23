import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class FollowService {
  final supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // FOLLOW
  Future<void> followUser(String userId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // prevent self follow
    if (user.id == userId) return;

    // prevent duplicate follow
    final existing = await supabase
        .from('follows')
        .select('id')
        .eq('follower_id', user.id)
        .eq('following_id', userId)
        .maybeSingle();

    if (existing != null) return;

    await supabase.from('follows').insert({
      'follower_id': user.id,
      'following_id': userId,
    });

    // 🔔 CREATE FOLLOW NOTIFICATION
    await _notificationService.createNotification(
      userId: userId,     // receiver
      actorId: user.id,   // sender
      type: 'follow',
    );
  }

  // UNFOLLOW
  Future<void> unfollowUser(String userId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('follows')
        .delete()
        .eq('follower_id', user.id)
        .eq('following_id', userId);
  }

  // IS FOLLOWING
  Future<bool> isFollowing(String userId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final data = await supabase
        .from('follows')
        .select('id')
        .eq('follower_id', user.id)
        .eq('following_id', userId)
        .maybeSingle();

    return data != null;
  }

  // COUNT FOLLOWERS
  Future<int> countFollowers(String userId) async {
    final data = await supabase
        .from('follows')
        .select('id')
        .eq('following_id', userId);

    return data.length;
  }

  // COUNT FOLLOWING
  Future<int> countFollowing(String userId) async {
    final data = await supabase
        .from('follows')
        .select('id')
        .eq('follower_id', userId);

    return data.length;
  }
}

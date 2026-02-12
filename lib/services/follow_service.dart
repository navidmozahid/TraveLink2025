import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class FollowService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService =
  NotificationService();

  /// ==============================
  /// FOLLOW USER
  /// ==============================
  Future<void> followUser(String userId) async {
    final currentUser = _supabase.auth.currentUser;

    if (currentUser == null) return;

    // 🚫 Prevent self follow
    if (currentUser.id == userId) return;

    try {
      // 🚫 Prevent duplicate follow
      final existing = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId)
          .maybeSingle();

      if (existing != null) return;

      // ✅ Insert follow
      await _supabase.from('follows').insert({
        'follower_id': currentUser.id,
        'following_id': userId,
      });

      // 🔔 Create notification
      await _notificationService.createNotification(
        userId: userId, // receiver
        actorId: currentUser.id, // sender
        type: 'follow',
      );
    } catch (e) {
      print('Follow error: $e');
    }
  }

  /// ==============================
  /// UNFOLLOW USER
  /// ==============================
  Future<void> unfollowUser(String userId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId);
    } catch (e) {
      print('Unfollow error: $e');
    }
  }

  /// ==============================
  /// CHECK IF FOLLOWING
  /// ==============================
  Future<bool> isFollowing(String userId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final data = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', currentUser.id)
          .eq('following_id', userId)
          .maybeSingle();

      return data != null;
    } catch (e) {
      print('isFollowing error: $e');
      return false;
    }
  }

  /// ==============================
  /// COUNT FOLLOWERS
  /// ==============================
  Future<int> countFollowers(String userId) async {
    try {
      final data = await _supabase
          .from('follows')
          .select('id')
          .eq('following_id', userId);

      return data.length;
    } catch (e) {
      print('countFollowers error: $e');
      return 0;
    }
  }

  /// ==============================
  /// COUNT FOLLOWING
  /// ==============================
  Future<int> countFollowing(String userId) async {
    try {
      final data = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', userId);

      return data.length;
    } catch (e) {
      print('countFollowing error: $e');
      return 0;
    }
  }

  /// ==============================
  /// GET FOLLOWERS LIST (ALL)
  /// ==============================
  Future<List<String>> getFollowersIds(String userId) async {
    try {
      final data = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);

      return data
          .map<String>((e) => e['follower_id'] as String)
          .toList();
    } catch (e) {
      print('getFollowersIds error: $e');
      return [];
    }
  }

  /// ==============================
  /// GET FOLLOWING LIST (ALL)
  /// ==============================
  Future<List<String>> getFollowingIds(String userId) async {
    try {
      final data = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      return data
          .map<String>((e) => e['following_id'] as String)
          .toList();
    } catch (e) {
      print('getFollowingIds error: $e');
      return [];
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class LikeService {
  final supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // LIKE
  Future<void> likePost(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1️⃣ get post owner
    final post = await supabase
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();

    if (post == null) return;

    final String postOwnerId = post['user_id'];

    // 2️⃣ insert like
    await supabase.from('likes').insert({
      'user_id': user.id,
      'post_id': postId,
    });

    // 3️⃣ notify (not self)
    if (postOwnerId != user.id) {
      await _notificationService.createNotification(
        userId: postOwnerId, // receiver
        actorId: user.id,    // who liked
        type: 'like',
        postId: postId,
      );
    }
  }

  // UNLIKE
  Future<void> unlikePost(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('likes')
        .delete()
        .eq('user_id', user.id)
        .eq('post_id', postId);
  }

  // CHECK IF LIKED
  Future<bool> isLiked(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;

    final data = await supabase
        .from('likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('post_id', postId)
        .maybeSingle();

    return data != null;
  }

  // ❤️ LIKE COUNT
  Future<int> countLikes(String postId) async {
    final response = await supabase
        .from('likes')
        .select('id')
        .eq('post_id', postId);

    return response.length;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class CommentService {
  final supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // ================= STREAM COMMENTS (REALTIME + PROFILES) =================
  Stream<List<Map<String, dynamic>>> streamComments(String postId) {
    return supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .asyncMap((comments) async {
      if (comments.isEmpty) return [];

      final userIds =
      comments.map((c) => c['user_id'] as String).toSet().toList();

      final profiles = await supabase
          .from('profiles')
          .select('id, name, avatar_url')
          .inFilter('id', userIds);

      final profileMap = {
        for (final p in profiles) p['id']: p,
      };

      return comments.map((c) {
        return {
          ...c,
          'profiles': profileMap[c['user_id']],
        };
      }).toList();
    });
  }

  // ================= ADD COMMENT / REPLY =================
  Future<void> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final inserted = await supabase
        .from('comments')
        .insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
      'parent_id': parentId,
    })
        .select()
        .maybeSingle();

    if (inserted == null) return;

    final post = await supabase
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();

    if (post == null) return;
    final postOwnerId = post['user_id'];

    // 🔔 notify post owner
    if (postOwnerId != user.id) {
      await _notificationService.createNotification(
        userId: postOwnerId,
        actorId: user.id,
        type: 'comment',
        postId: postId,
      );
    }

    // 🔔 notify replied comment owner
    if (parentId != null) {
      final parent = await supabase
          .from('comments')
          .select('user_id')
          .eq('id', parentId)
          .maybeSingle();

      if (parent != null &&
          parent['user_id'] != user.id &&
          parent['user_id'] != postOwnerId) {
        await _notificationService.createNotification(
          userId: parent['user_id'],
          actorId: user.id,
          type: 'reply',
          postId: postId,
        );
      }
    }
  }

  // ================= COMMENT LIKES =================
  Stream<List<Map<String, dynamic>>> streamCommentLikes(String commentId) {
    return supabase
        .from('comment_likes')
        .stream(primaryKey: ['id'])
        .eq('comment_id', commentId);
  }

  Future<void> likeComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final exists = await supabase
        .from('comment_likes')
        .select('id')
        .eq('comment_id', commentId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (exists != null) return;

    await supabase.from('comment_likes').insert({
      'comment_id': commentId,
      'user_id': user.id,
    });
  }

  Future<void> unlikeComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', user.id);
  }

  // ================= UPDATE COMMENT =================
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('comments')
        .update({'content': content})
        .eq('id', commentId)
        .eq('user_id', user.id);
  }

  // ================= DELETE COMMENT =================
  // ✅ comment owner OR post owner
  Future<void> deleteComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final comment = await supabase
        .from('comments')
        .select('user_id, post_id')
        .eq('id', commentId)
        .maybeSingle();

    if (comment == null) return;

    final post = await supabase
        .from('posts')
        .select('user_id')
        .eq('id', comment['post_id'])
        .maybeSingle();

    final isCommentOwner = comment['user_id'] == user.id;
    final isPostOwner = post != null && post['user_id'] == user.id;

    if (isCommentOwner || isPostOwner) {
      await supabase.from('comments').delete().eq('id', commentId);
    }
  }

  // ================= COMMENT COUNT (FIXES YOUR ERROR) =================
  Future<int> countComments(String postId) async {
    final data = await supabase
        .from('comments')
        .select('id')
        .eq('post_id', postId);

    return data.length;
  }

  // ================= REALTIME COMMENT COUNT (OPTIONAL) =================
  Stream<int> streamCommentCount(String postId) {
    return supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) => rows.length);
  }
}

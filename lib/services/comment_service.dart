import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class CommentService {
  final supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // ---------------- FETCH COMMENTS (SAFE + PROFILES) ----------------
  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    // 1️⃣ fetch comments
    final comments = await supabase
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at');

    if (comments.isEmpty) return [];

    // 2️⃣ collect user ids
    final userIds = <String>{};
    for (final c in comments) {
      userIds.add(c['user_id']);
    }

    // 3️⃣ fetch profiles
    final profiles = await supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .inFilter('id', userIds.toList());

    // 4️⃣ map profiles
    final Map<String, Map<String, dynamic>> profileMap = {};
    for (final p in profiles) {
      profileMap[p['id']] = p;
    }

    // 5️⃣ merge
    return comments.map<Map<String, dynamic>>((c) {
      return {
        ...c,
        'profiles': profileMap[c['user_id']],
      };
    }).toList();
  }

  // ---------------- ADD COMMENT / REPLY ----------------
  Future<void> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1️⃣ insert comment
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

    // 2️⃣ get post owner
    final post = await supabase
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();

    if (post == null) return;

    final String postOwnerId = post['user_id'];

    // 3️⃣ notify post owner (not self)
    if (postOwnerId != user.id) {
      await _notificationService.createNotification(
        userId: postOwnerId,
        actorId: user.id,
        type: 'comment',
        postId: postId,
      );
    }

    // 4️⃣ reply notification
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

  // ---------------- COMMENT COUNT ----------------
  Future<int> countComments(String postId) async {
    final response = await supabase
        .from('comments')
        .select('id')
        .eq('post_id', postId);

    return response.length;
  }

  // ---------------- DELETE COMMENT ----------------
  Future<void> deleteComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', user.id);
  }

  // ---------------- UPDATE COMMENT ----------------
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
}

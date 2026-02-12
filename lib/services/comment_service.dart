import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class CommentService {
  final SupabaseClient supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  // ================= STREAM COMMENTS =================
  Stream<List<Map<String, dynamic>>> streamComments(String postId) {
    return supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at')
        .asyncMap((comments) async {
      if (comments.isEmpty) return [];

      // ✅ ADDED: fetch post owner once (REQUIRED FOR UI DELETE)
      final post = await supabase
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .maybeSingle();

      final postOwnerId = post?['user_id'];

      final userIds =
      comments.map((c) => c['user_id'] as String).toSet().toList();

      final users = await supabase
          .from('app_users')
          .select('id, name, avatar_url, user_type')
          .inFilter('id', userIds);

      final userMap = {
        for (final u in users) u['id']: u,
      };

      final businesses = await supabase
          .from('business_accounts')
          .select('id, agency_name, logo_url')
          .inFilter('id', userIds);

      final businessMap = {
        for (final b in businesses) b['id']: b,
      };

      return comments.map((c) {
        final u = userMap[c['user_id']];
        final bool isBusiness = u?['user_type'] == 'agency';
        final business = businessMap[c['user_id']];

        return {
          ...c,

          // ✅ ADDED: expose post owner for UI permission check
          'post_owner_id': postOwnerId,

          // expose user_type
          'user_type': u?['user_type'],

          // traveler profile (UNCHANGED)
          'profiles': !isBusiness && u != null
              ? {
            'id': u['id'],
            'name': u['name'],
            'avatar_url': u['avatar_url'],
          }
              : null,

          // business profile (for business comments)
          'business_accounts': isBusiness && business != null
              ? {
            'id': business['id'],
            'agency_name': business['agency_name'],
            'avatar_url': business['logo_url'],
          }
              : null,
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

    final inserted = await supabase.from('comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
      'parent_id': parentId,
    }).select().maybeSingle();

    if (inserted == null) return;

    final post = await supabase
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();

    if (post == null) return;
    final postOwnerId = post['user_id'];

    if (postOwnerId != user.id) {
      await _notificationService.createNotification(
        userId: postOwnerId,
        actorId: user.id,
        type: 'comment',
        postId: postId,
      );
    }

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
        .eq('comment_id', commentId)
        .asyncMap((likes) async {
      if (likes.isEmpty) return [];

      final userIds =
      likes.map((l) => l['user_id'] as String).toSet().toList();

      final users = await supabase
          .from('app_users')
          .select('id, name, avatar_url, user_type')
          .inFilter('id', userIds);

      final userMap = {
        for (final u in users) u['id']: u,
      };

      return likes.map((l) {
        final u = userMap[l['user_id']];
        return {
          ...l,
          'profiles': u == null
              ? null
              : {
            'id': u['id'],
            'name': u['name'],
            'avatar_url': u['avatar_url'],
            'user_type': u['user_type'],
          },
        };
      }).toList();
    });
  }

  // ================= LIKE COMMENT =================
  Future<void> likeComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase.from('comment_likes').upsert(
      {
        'comment_id': commentId,
        'user_id': user.id,
      },
      onConflict: 'comment_id,user_id',
    );

    if (res.error != null) {
      debugPrint('LIKE COMMENT ERROR: ${res.error!.message}');
    }
  }

  // ================= UNLIKE COMMENT =================
  Future<void> unlikeComment(String commentId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final res = await supabase
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', user.id);

    if (res.error != null) {
      debugPrint('UNLIKE COMMENT ERROR: ${res.error!.message}');
    }
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

  // ================= COMMENT COUNT =================
  Future<int> countComments(String postId) async {
    final data = await supabase
        .from('comments')
        .select('id')
        .eq('post_id', postId);

    return data.length;
  }

  // ================= REALTIME COMMENT COUNT =================
  Stream<int> streamCommentCount(String postId) {
    return supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((rows) => rows.length);
  }
}

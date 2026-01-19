import 'package:supabase_flutter/supabase_flutter.dart';

class LikeService {
  final supabase = Supabase.instance.client;

  // LIKE
  Future<void> likePost(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('likes').insert({
      'user_id': user.id,
      'post_id': postId,
    });
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

  // 👥 WHO LIKED (NEW)
  Future<List<Map<String, dynamic>>> fetchLikes(String postId) async {
    final response = await supabase
        .from('likes')
        .select('''
          user_id,
          profiles (
            name,
            avatar_url
          )
        ''')
        .eq('post_id', postId);

    return List<Map<String, dynamic>>.from(response);
  }
}

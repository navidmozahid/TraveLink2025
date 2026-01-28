import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  static const String _bucket = 'post-images';

  // ================= UPLOAD SINGLE MEDIA =================
  Future<String> uploadMedia(File file) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final ext = file.path.split('.').last;
    final path = '${user.id}/${_uuid.v4()}.$ext';

    await supabase.storage.from(_bucket).upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  // ================= UPLOAD MULTIPLE MEDIA =================
  Future<List<String>> uploadMultipleMedia(List<File> files) async {
    final List<String> urls = [];

    for (final file in files) {
      final url = await uploadMedia(file);
      urls.add(url);
    }

    return urls;
  }

  // ================= CREATE OLD POST (SINGLE MEDIA) =================
  Future<void> createPost({
    required String mediaUrl,
    required String caption,
    required String location,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await supabase.from('posts').insert({
      'user_id': user.id,
      'media_url': mediaUrl,
      'caption': caption,
      'location': location,
    });
  }

  // ================= CREATE NEW POST (MULTIPLE MEDIA) =================
  Future<void> createPostWithMultipleMedia({
    required List<File> mediaFiles,
    required String caption,
    required String location,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final post = await supabase
        .from('posts')
        .insert({
      'user_id': user.id,
      'caption': caption,
      'location': location,
    })
        .select()
        .single();

    final String postId = post['id'];

    final urls = await uploadMultipleMedia(mediaFiles);

    for (final url in urls) {
      final isVideo = url.endsWith('.mp4') ||
          url.endsWith('.mov') ||
          url.endsWith('.avi') ||
          url.endsWith('.mkv');

      await supabase.from('post_media').insert({
        'post_id': postId,
        'media_url': url,
        'media_type': isVideo ? 'video' : 'image',
      });
    }
  }

  // ================= FETCH FEED POSTS =================
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final posts = await supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    if (posts.isEmpty) return [];

    final postIds = posts.map((p) => p['id']).toList();
    final userIds = posts.map((p) => p['user_id']).toSet().toList();

    final profiles = await supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .inFilter('id', userIds);

    final profileMap = {
      for (final p in profiles) p['id']: p,
    };

    final media = await supabase
        .from('post_media')
        .select()
        .inFilter('post_id', postIds);

    final Map<String, List<Map<String, dynamic>>> mediaMap = {};
    for (final m in media) {
      mediaMap.putIfAbsent(m['post_id'], () => []).add(m);
    }

    return posts.map<Map<String, dynamic>>((post) {
      return {
        ...post,
        'profiles': profileMap[post['user_id']],
        'post_media': mediaMap[post['id']] ?? [],
      };
    }).toList();
  }

  // ================= FETCH MY POSTS (PROFILE GRID) =================
  Future<List<Map<String, dynamic>>> fetchMyPosts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final posts = await supabase
        .from('posts')
        .select('id, media_url, caption, location, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(100); // 🔥 FORCE FRESH DATA

    if (posts.isEmpty) return [];

    final postIds = posts.map((p) => p['id']).toList();

    final media = await supabase
        .from('post_media')
        .select('post_id, media_url')
        .inFilter('post_id', postIds);

    final Map<String, String> previewMap = {};
    for (final m in media) {
      previewMap.putIfAbsent(m['post_id'], () => m['media_url']);
    }

    return posts.map<Map<String, dynamic>>((post) {
      return {
        ...post,
        'media_url': previewMap[post['id']] ?? post['media_url'],
      };
    }).toList();
  }

  // ================= FETCH POST MEDIA =================
  Future<List<Map<String, dynamic>>> fetchPostMedia(String postId) async {
    final data = await supabase
        .from('post_media')
        .select()
        .eq('post_id', postId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  // ================= UPDATE POST WITH MEDIA =================
  Future<void> updatePostWithMedia({
    required String postId,
    required String caption,
    required String location,
    required List<Map<String, dynamic>> removedMedia,
    required List<File> newMediaFiles,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // ✅✅✅ FIXED PART: Update caption/location with correct filter + select()
    final updatedPost = await supabase
        .from('posts')
        .update({
      'caption': caption,
      'location': location,
    })
        .eq('id', postId)
        .eq('user_id', user.id) // ✅ IMPORTANT for RLS + safe update
        .select()
        .maybeSingle();

    if (updatedPost == null) {
      throw Exception('Post update failed (RLS blocked or post not found)');
    }

    // ✅ REMOVE MEDIA
    for (final media in removedMedia) {
      final mediaUrl = media['media_url'] as String;
      final path = Uri.parse(mediaUrl)
          .path
          .split('/storage/v1/object/public/$_bucket/')
          .last;

      await supabase.storage.from(_bucket).remove([path]);
      await supabase.from('post_media').delete().eq('id', media['id']);
    }

    // ✅ ADD NEW MEDIA
    for (final file in newMediaFiles) {
      final ext = file.path.split('.').last.toLowerCase();
      final filePath = '${user.id}/${postId}_${_uuid.v4()}.$ext';

      await supabase.storage.from(_bucket).upload(
        filePath,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = supabase.storage.from(_bucket).getPublicUrl(filePath);

      await supabase.from('post_media').insert({
        'post_id': postId,
        'media_url': publicUrl,
        'media_type': ['mp4', 'mov', 'avi', 'mkv'].contains(ext)
            ? 'video'
            : 'image',
      });
    }
  }
}

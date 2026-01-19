import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  static const String _bucket = 'post-images';

  // ---------------- UPLOAD MEDIA ----------------
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

  // ---------------- CREATE POST ----------------
  Future<void> createPost({
    required String mediaUrl,
    required String caption,
    required String location,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await supabase.from('posts').insert({
      'user_id': user.id,
      'media_url': mediaUrl,
      'caption': caption,
      'location': location,
    });
  }

  // ---------------- FETCH FEED POSTS ----------------
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    // 1️⃣ Fetch posts
    final posts = await supabase
        .from('posts')
        .select()
        .order('created_at', ascending: false);

    if (posts.isEmpty) return [];

    // 2️⃣ Extract user IDs
    final userIds = <String>{};
    for (final post in posts) {
      userIds.add(post['user_id']);
    }

    // 3️⃣ Fetch profiles
    final profiles = await supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .inFilter('id', userIds.toList());

    // 4️⃣ Map profiles
    final Map<String, Map<String, dynamic>> profileMap = {};
    for (final p in profiles) {
      profileMap[p['id']] = p;
    }

    // 5️⃣ Merge posts + profiles
    return posts.map<Map<String, dynamic>>((post) {
      return {
        ...post,
        'profiles': profileMap[post['user_id']],
      };
    }).toList();
  }

  // ---------------- FETCH MY POSTS (PROFILE) ----------------
  Future<List<Map<String, dynamic>>> fetchMyPosts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('posts')
        .select('id, media_url, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

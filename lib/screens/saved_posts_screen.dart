import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'post_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _savedPosts = [];

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  Future<void> _loadSavedPosts() async {
    try {
      final myId = _supabase.auth.currentUser?.id;

      if (myId == null) {
        setState(() => _loading = false);
        return;
      }

      // ✅ 1) get saved post IDs
      final savedRows = await _supabase
          .from('saved_posts')
          .select('post_id')
          .eq('user_id', myId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> saved =
      List<Map<String, dynamic>>.from(savedRows);

      if (saved.isEmpty) {
        setState(() {
          _savedPosts = [];
          _loading = false;
        });
        return;
      }

      final postIds = saved
          .map((r) => (r['post_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      // ✅ 2) load posts (preview image)
      final postsData = await _supabase
          .from('posts')
          .select('id, media_url, post_media (media_url, media_type)')
          .inFilter('id', postIds);

      final posts = List<Map<String, dynamic>>.from(postsData);

      // ✅ 3) keep same order as saved list
      final Map<String, Map<String, dynamic>> postMap = {
        for (final p in posts) (p['id'] ?? '').toString(): p,
      };

      final ordered = <Map<String, dynamic>>[];
      for (final id in postIds) {
        final p = postMap[id];
        if (p != null) ordered.add(p);
      }

      if (!mounted) return;
      setState(() {
        _savedPosts = ordered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ✅ NEW: Remove saved post
  Future<void> _removeFromSaved(String postId) async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    await _supabase
        .from('saved_posts')
        .delete()
        .eq('user_id', myId)
        .eq('post_id', postId);

    await _loadSavedPosts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Removed from saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
          ? const Center(child: Text("No saved posts yet"))
          : GridView.builder(
        padding: const EdgeInsets.all(2),
        itemCount: _savedPosts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (_, i) {
          final post = _savedPosts[i];

          final List media =
          post['post_media'] != null ? post['post_media'] : [];

          String? previewUrl;
          bool isVideo = false;

          if (media.isNotEmpty && media.first['media_url'] != null) {
            previewUrl = media.first['media_url'];
            isVideo = media.first['media_type'] == 'video';
          } else if (post['media_url'] != null) {
            previewUrl = post['media_url'];
          }

          if (previewUrl == null || previewUrl.toString().isEmpty) {
            return Container(color: Colors.grey[300]);
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PostDetailScreen(postId: post['id']),
                ),
              );
            },

            // ✅ Instagram style: long press to remove
            onLongPress: () async {
              final action = await showModalBottomSheet<String>(
                context: context,
                builder: (_) => SafeArea(
                  child: Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.bookmark_remove,
                          color: Colors.red,
                        ),
                        title: const Text("Remove from Saved"),
                        onTap: () =>
                            Navigator.pop(context, "remove"),
                      ),
                    ],
                  ),
                ),
              );

              if (action == "remove") {
                _removeFromSaved(post['id']);
              }
            },

            child: Stack(
              fit: StackFit.expand,
              children: [
                if (!isVideo)
                  Image.network(
                    previewUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                    ),
                  )
                else
                  Container(color: Colors.black12),
                if (isVideo)
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/post_service.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';
import 'comments_screen.dart';
import 'other_profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PostService _postService = PostService();
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();

  Map<String, dynamic>? _post;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    final data = await _supabase
        .from('posts')
        .select()
        .eq('id', widget.postId)
        .maybeSingle();

    if (data == null) {
      setState(() => _loading = false);
      return;
    }

    // fetch profile
    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', data['user_id'])
        .maybeSingle();

    setState(() {
      _post = {
        ...data,
        'profiles': profile,
      };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return const Scaffold(
        body: Center(child: Text("Post not found")),
      );
    }

    final profile = _post!['profiles'];
    final currentUser = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Post")),
      body: ListView(
        children: [
          // ---------- HEADER ----------
          ListTile(
            leading: GestureDetector(
              onTap: () {
                if (_post!['user_id'] != currentUser?.id) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OtherProfileScreen(userId: _post!['user_id']),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage: profile?['avatar_url'] != null
                    ? NetworkImage(profile['avatar_url'])
                    : null,
                child: profile?['avatar_url'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            title: Text(
              profile?['name'] ?? 'Traveler',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_post!['location'] ?? ''),
          ),

          // ---------- IMAGE ----------
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              _post!['media_url'],
              fit: BoxFit.cover,
            ),
          ),

          // ---------- ACTIONS ----------
          Row(
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase
                    .from('likes')
                    .stream(primaryKey: ['id'])
                    .eq('post_id', widget.postId),
                builder: (_, snap) {
                  final likes = snap.data ?? [];
                  final isLiked = likes.any(
                        (l) => l['user_id'] == currentUser?.id,
                  );

                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.black,
                        ),
                        onPressed: () {
                          isLiked
                              ? _likeService.unlikePost(widget.postId)
                              : _likeService.likePost(widget.postId);
                        },
                      ),
                      if (likes.isNotEmpty)
                        Text(likes.length.toString()),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CommentsScreen(postId: widget.postId),
                    ),
                  );
                },
              ),
            ],
          ),

          // ---------- CAPTION ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: '${profile?['name'] ?? 'Traveler'} ',
                    style:
                    const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: _post!['caption'] ?? ''),
                ],
              ),
            ),
          ),

          // ---------- COMMENT COUNT ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FutureBuilder<int>(
              future: _commentService.countComments(widget.postId),
              builder: (_, snap) {
                if (!snap.hasData || snap.data == 0) {
                  return const SizedBox();
                }
                return Text(
                  "View ${snap.data} comments",
                  style: const TextStyle(color: Colors.grey),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

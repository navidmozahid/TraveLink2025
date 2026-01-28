import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../services/like_service.dart';
import '../services/comment_service.dart';
import 'comments_screen.dart';
import 'other_profile_screen.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();

  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _media = [];

  final Map<int, VideoPlayerController> _videoControllers = {};

  bool _isMuted = true;
  int _currentIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ---------------- LOAD POST ----------------
  Future<void> _loadPost() async {
    // ✅ FIX: force loading UI for refresh after edit
    if (mounted) {
      setState(() => _loading = true);
    }

    // ✅ FIX: clear old media state
    _media = [];
    _currentIndex = 0;

    final post = await _supabase
        .from('posts')
        .select()
        .eq('id', widget.postId)
        .maybeSingle();

    if (post == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', post['user_id'])
        .maybeSingle();

    final media = await _supabase
        .from('post_media')
        .select('media_url, media_type')
        .eq('post_id', widget.postId)
        .order('created_at');

    if (media.isNotEmpty) {
      _media = List<Map<String, dynamic>>.from(media);
    } else if (post['media_url'] != null) {
      _media = [
        {
          'media_url': post['media_url'],
          'media_type': 'image',
        }
      ];
    }

    _videoControllers.clear();

    for (int i = 0; i < _media.length; i++) {
      if (_media[i]['media_type'] == 'video') {
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(_media[i]['media_url']),
        );
        await controller.initialize();
        controller
          ..setLooping(true)
          ..setVolume(_isMuted ? 0 : 1)
          ..play();

        _videoControllers[i] = controller;
      }
    }

    if (!mounted) return;
    setState(() {
      _post = {
        ...post,
        'profiles': profile,
      };
      _loading = false;
    });
  }

  // ---------------- DELETE POST ----------------
  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await _supabase.from('posts').delete().eq('id', widget.postId);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      for (final controller in _videoControllers.values) {
        controller.setVolume(_isMuted ? 0 : 1);
      }
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
    final isOwner =
        currentUser != null && _post!['user_id'] == currentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post"),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPostScreen(
                        postId: widget.postId,
                        initialCaption: _post!['caption']?.toString() ?? '',
                        initialLocation: _post!['location']?.toString() ?? '',
                      ),
                    ),
                  );

                  if (updated == true) {
                    await _loadPost();
                  }
                }

                if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text("Edit"),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
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

          // ---------- MEDIA ----------
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: _media.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (_, i) {
                    final item = _media[i];
                    if (item['media_type'] == 'video') {
                      final controller = _videoControllers[i];
                      if (controller == null || !controller.value.isInitialized) {
                        return Container(color: Colors.black);
                      }
                      return VideoPlayer(controller);
                    }
                    return Image.network(
                      item['media_url'],
                      fit: BoxFit.cover,
                    );
                  },
                ),

                if (_videoControllers.isNotEmpty)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                  ),

                if (_media.length > 1)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _media.length,
                            (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == i ? 8 : 6,
                          height: _currentIndex == i ? 8 : 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                            _currentIndex == i ? Colors.white : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.black,
                        ),
                        onPressed: () {
                          isLiked
                              ? _likeService.unlikePost(widget.postId)
                              : _likeService.likePost(widget.postId);
                        },
                      ),
                      if (likes.isNotEmpty) Text(likes.length.toString()),
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
                      builder: (_) => CommentsScreen(postId: widget.postId),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

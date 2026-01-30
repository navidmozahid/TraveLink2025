import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/follow_service.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';
import 'message_screen.dart';
import 'post_detail_screen.dart';
import 'follow_list_screen.dart';

class OtherProfileScreen extends StatefulWidget {
  final String userId;

  const OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FollowService _followService = FollowService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];

  int _followers = 0;
  int _following = 0;

  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;

  bool get isMyProfile => widget.userId == _supabase.auth.currentUser?.id;

  // ✅ NEW: Instagram style avatar preview popup (blur background)
  void _showAvatarPreview(String avatarUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "avatar",
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                // ✅ BLUR BACKGROUND
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                ),

                // ✅ AVATAR PREVIEW
                Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        avatarUrl,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 300,
                          height: 300,
                          color: Color(0xFF475569),
                          child: const Icon(Icons.broken_image, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),

                // ✅ CLOSE BUTTON
                Positioned(
                  top: 40,
                  right: 18,
                  child: IconButton(
                    icon:
                    const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadProfile(),
      _loadPosts(),
      _loadFollowCounts(),
      _checkFollowing(),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProfile() async {
    _profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', widget.userId)
        .maybeSingle();
  }

  Future<void> _loadPosts() async {
    final data = await _supabase
        .from('posts')
        .select('id, media_url, post_media (media_url, media_type)')
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    _posts = List<Map<String, dynamic>>.from(data);
  }

  Future<void> _loadFollowCounts() async {
    _followers = await _followService.countFollowers(widget.userId);
    _following = await _followService.countFollowing(widget.userId);
  }

  Future<void> _checkFollowing() async {
    _isFollowing = await _followService.isFollowing(widget.userId);
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;

    setState(() => _followLoading = true);

    if (_isFollowing) {
      await _followService.unfollowUser(widget.userId);
    } else {
      await _followService.followUser(widget.userId);
    }

    await _loadFollowCounts();
    await _checkFollowing();

    setState(() => _followLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String name = _profile?['name'] ?? 'Traveler';
    final String bio = _profile?['bio'] ?? '';
    final String? avatar = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (avatar != null && avatar.toString().isNotEmpty) {
                      _showAvatarPreview(avatar);
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                    avatar != null ? NetworkImage(avatar) : null,
                    child: avatar == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        title: 'Posts',
                        value: _posts.length.toString(),
                      ),

                      // ✅ FOLLOWERS (CLICKABLE → MUTUAL FOLLOWERS)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: widget.userId,
                                showFollowers: true,
                                mutualOnly: true,
                              ),
                            ),
                          );
                        },
                        child: _StatItem(
                          title: 'Followers',
                          value: _followers.toString(),
                        ),
                      ),

                      // ✅ FOLLOWING (CLICKABLE → MUTUAL FOLLOWING)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: widget.userId,
                                showFollowers: false,
                                mutualOnly: true,
                              ),
                            ),
                          );
                        },
                        child: _StatItem(
                          title: 'Following',
                          value: _following.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            if (bio.isNotEmpty) Text(bio),

            const SizedBox(height: 12),

            if (!isMyProfile)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _followLoading ? null : _toggleFollow,
                      child: Text(_isFollowing ? 'Following' : 'Follow'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        // ✅ ONLY NEW CODE (Messaging) - Everything else unchanged
                        final messageService = MessageService();

                        final conversationId = await messageService
                            .getOrCreateConversation(widget.userId);

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: conversationId,
                              otherUser: {
                                "id": widget.userId,
                                "username": _profile?['username'] ?? name,
                                "avatar_url": _profile?['avatar_url'],
                              },
                            ),
                          ),
                        );

                      },
                      child: const Text("Message"),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
            const Divider(),

            // ---------- POSTS GRID (FIXED) ----------
            _posts.isEmpty
                ? const Center(child: Text('No posts'))
                : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _posts.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (_, i) {
                final post = _posts[i];

                final List<Map<String, dynamic>> media =
                post['post_media'] != null
                    ? List<Map<String, dynamic>>.from(
                  post['post_media'],
                )
                    : [];

                String? previewUrl;
                bool isVideo = false;

                if (media.isNotEmpty && media.first['media_url'] != null) {
                  previewUrl = media.first['media_url'];
                  isVideo = media.first['media_type'] == 'video';
                } else if (post['media_url'] != null) {
                  previewUrl = post['media_url'];
                }

                if (previewUrl == null) {
                  return Container(color: Color(0xFF475569));
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ✅ ONLY load images
                      if (!isVideo)
                        Image.network(
                          previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Color(0xFF475569),
                          ),
                        )
                      else
                        Container(
                          color: Colors.black12,
                        ),

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
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Color(0xFF475569)),
        ),
      ],
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/follow_service.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';
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

  // ================= AVATAR PREVIEW (BLUR) =================
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
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      color: Colors.black.withOpacity(0.35),
                    ),
                  ),
                ),
                Center(
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
                        color: const Color(0xFF475569),
                        child: const Icon(Icons.broken_image, size: 40),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 18,
                  child: IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white, size: 28),
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
      _checkFollowing(),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  // ================= LOAD PROFILE =================
  Future<void> _loadProfile() async {
    _profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', widget.userId)
        .maybeSingle();
  }

  // ================= LOAD POSTS =================
  Future<void> _loadPosts() async {
    final data = await _supabase
        .from('posts')
        .select('id, media_url, post_media (media_url, media_type)')
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    _posts = List<Map<String, dynamic>>.from(data);
  }

  // ================= FOLLOW COUNTS =================
  Future<void> _loadFollowCounts() async {
    _followers = await _followService.countFollowers(widget.userId);
    _following = await _followService.countFollowing(widget.userId);
  }

  Future<void> _checkFollowing() async {
    _isFollowing = await _followService.isFollowing(widget.userId);
  }

// ✅ ADD THESE RIGHT BELOW
  Stream<int> _followersCount() {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .map((rows) =>
    rows.where((r) => r['following_id'] == widget.userId).length);
  }

  Stream<int> _followingCount() {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .map((rows) =>
    rows.where((r) => r['follower_id'] == widget.userId).length);
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
    final String username = _profile?['username'] ?? '';
    final String bio = _profile?['bio'] ?? '';
    final String? avatar = _profile?['avatar_url'];
    final String city = _profile?['city'] ?? '';
    final String country = _profile?['country'] ?? '';
    final String website = _profile?['website_url'] ?? '';
    final List interests = (_profile?['interests'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= HEADER =================
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (avatar != null && avatar.isNotEmpty) {
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: widget.userId,
                                showFollowers: true,
                                mutualOnly: false,
                              ),
                            ),
                          );
                        },
                        child: StreamBuilder<int>(
                          stream: _followersCount(),
                          builder: (_, snap) {
                            return _StatItem(
                              title: 'Followers',
                              value: (snap.data ?? 0).toString(),
                            );
                          },
                        ),

                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: widget.userId,
                                showFollowers: false,
                                mutualOnly: false,
                              ),
                            ),
                          );
                        },
                        child: StreamBuilder<int>(
                          stream: _followingCount(),
                          builder: (_, snap) {
                            return _StatItem(
                              title: 'Following',
                              value: (snap.data ?? 0).toString(),
                            );
                          },
                        ),

                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================= INFO =================
            Text(
              name,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            if (username.isNotEmpty)
              Text('@$username',
                  style: const TextStyle(color: Colors.grey)),

            if (bio.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(bio),
              ),

            if (city.isNotEmpty || country.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      [country, city]
                          .where((e) => e.isNotEmpty)
                          .join(', '),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            if (website.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  website,
                  style: const TextStyle(color: Colors.blue),
                ),
              ),

            if (interests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: interests.map<Widget>((tag) {
                    return Chip(
                      label: Text(tag.toString()),
                      backgroundColor: const Color(0xFF475569),
                      labelStyle:
                      const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // ================= ACTIONS =================
            if (!isMyProfile)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                      _followLoading ? null : _toggleFollow,
                      child:
                      Text(_isFollowing ? 'Following' : 'Follow'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        try {
                          final messageService = MessageService();

                          debugPrint("➡️ Message pressed");
                          debugPrint(
                              "➡️ Me: ${_supabase.auth.currentUser?.id}");
                          debugPrint("➡️ Other: ${widget.userId}");

                          final conversationId =
                          await messageService.getOrCreateConversation(
                              widget.userId);

                          debugPrint(
                              "✅ Conversation ID: $conversationId");

                          if (!context.mounted) return;

                          final Map<String, dynamic> otherUser = {
                            'id': widget.userId,
                            'name': name,
                            'username':
                            username.isNotEmpty ? username : null,
                            'avatar_url': avatar,
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conversationId,
                                otherUser: otherUser,
                              ),
                            ),
                          );
                        } catch (e, s) {
                          debugPrint("❌ MESSAGE ERROR: $e");
                          debugPrint("❌ STACK: $s");

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              Text("Message failed: $e"),
                            ),
                          );
                        }
                      },
                      child: const Text('Message'),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
            const Divider(),

            // ================= POSTS GRID =================
            _posts.isEmpty
                ? const Center(child: Text('No posts'))
                : GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
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

                if (media.isNotEmpty &&
                    media.first['media_url'] != null) {
                  previewUrl = media.first['media_url'];
                  isVideo =
                      media.first['media_type'] == 'video';
                } else if (post['media_url'] != null) {
                  previewUrl = post['media_url'];
                }

                if (previewUrl == null) {
                  return Container(
                      color: const Color(0xFF475569));
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PostDetailScreen(
                                postId: post['id']),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!isVideo)
                        Image.network(
                          previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                            color:
                            const Color(0xFF475569),
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
              fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          title,
          style: const TextStyle(color: Color(0xFF475569)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';
import 'comments_screen.dart';
import 'other_profile_screen.dart';
import 'notification_screen.dart';
import 'post_detail_screen.dart'; // ✅ ADDED (needed)
import 'inbox_screen.dart';

import '../services/post_service.dart';
import '../services/follow_service.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';
import '../widgets/feed_video_player.dart';
import '../widgets/share_post_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final PostService _postService = PostService();
  final FollowService _followService = FollowService();
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();

  bool _loading = true;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _posts = [];

  final Map<String, int> _pageIndexes = {};
  bool _isFeedMuted = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // ---------------- LOAD POSTS ----------------
  Future<void> _loadPosts() async {
    try {
      final data = await _postService.fetchPosts();
      setState(() {
        _posts = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ---------------- LOGOUT ----------------
  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  // ---------------- SETTINGS ----------------
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              "Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout"),
              onTap: _logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ---------------- REALTIME NOTIFICATION COUNT ----------------
  Stream<int> _unreadNotificationCount() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
        .where((n) => n['user_id'] == user.id && n['is_read'] == false)
        .length);
  }

  // ---------------- POST CARD ----------------
  Widget _buildPost(Map<String, dynamic> post) {
    final currentUser = _supabase.auth.currentUser;
    final profile = post['profiles'];

    final String userName = profile?['name'] ?? 'Traveler';
    final String? avatarUrl = profile?['avatar_url'];
    final bool isMyPost = post['user_id'] == currentUser?.id;

    final List mediaList = post['post_media'] ?? [];
    final int activeIndex = _pageIndexes[post['id']] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- HEADER ----------
          ListTile(
            leading: GestureDetector(
              onTap: () {
                if (!isMyPost) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OtherProfileScreen(userId: post['user_id']),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person) : null,
              ),
            ),
            title: Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(post['location'] ?? ''),
            trailing: isMyPost || currentUser == null
                ? null
                : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('follows').stream(primaryKey: ['id']),
              builder: (_, snap) {
                final rows = snap.data ?? [];

                final isFollowing = rows.any(
                      (r) =>
                  r['follower_id'] == currentUser.id &&
                      r['following_id'] == post['user_id'],
                );

                return OutlinedButton(
                  onPressed: () {
                    isFollowing
                        ? _followService.unfollowUser(post['user_id'])
                        : _followService.followUser(post['user_id']);
                  },
                  child: Text(isFollowing ? "Following" : "Follow"),
                );
              },
            ),
          ),

          // ---------- MEDIA ----------
          GestureDetector(
            // ✅ FIX ADDED: open post detail and refresh feed after edit/delete
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(postId: post['id']),
                ),
              );

              if (updated == true) {
                _loadPosts();
              }
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: mediaList.isNotEmpty
                  ? Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  PageView.builder(
                    itemCount: mediaList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndexes[post['id']] = index;
                      });
                    },
                    itemBuilder: (_, i) {
                      final media = mediaList[i];

                      if (media['media_type'] == 'video') {
                        final bool isActive =
                            activeIndex == i && _currentIndex == 0;

                        return Stack(
                          children: [
                            FeedVideoPlayer(
                              key: ValueKey(media['media_url']),
                              videoUrl: media['media_url'],
                            ),
                          ],
                        );
                      }

                      return Image.network(
                        media['media_url'],
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    child: Row(
                      children: List.generate(
                        mediaList.length,
                            (i) => Container(
                          margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == activeIndex
                                ? Colors.white
                                : Colors.white54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : Image.network(
                post['media_url'],
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ---------- ACTIONS ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase.from('likes').stream(primaryKey: ['id']),
                  builder: (_, snap) {
                    final likes = snap.data ?? [];

                    final isLiked = currentUser != null &&
                        likes.any((l) =>
                        l['user_id'] == currentUser.id &&
                            l['post_id'] == post['id']);

                    final likeCount =
                        likes.where((l) => l['post_id'] == post['id']).length;

                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.black,
                          ),
                          onPressed: () {
                            isLiked
                                ? _likeService.unlikePost(post['id'])
                                : _likeService.likePost(post['id']);
                          },
                        ),
                        if (likeCount > 0) Text(likeCount.toString()),
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
                        builder: (_) => CommentsScreen(postId: post['id']),
                      ),
                    );
                  },
                ),

                // ✅ NEW: SHARE BUTTON (Instagram Style)
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      builder: (_) => SharePostSheet(postId: post['id']),
                    );
                  },
                ),

                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // ---------- COMMENT COUNT ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('comments').stream(primaryKey: ['id']),
              builder: (_, snap) {
                final count = (snap.data ?? [])
                    .where((c) => c['post_id'] == post['id'])
                    .length;

                if (count == 0) return const SizedBox();
                return Text(
                  "View $count comments",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                );
              },
            ),
          ),

          // ---------- CAPTION ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: '$userName ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: post['caption'] ?? ''),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ---------------- BODY ----------------
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (_, i) => _buildPost(_posts[i]),
        );
      case 1:
        return const Center(child: Text("Explore"));
      case 2:
        return const InboxScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox();
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TraveLink"),
        actions: [
          if (_currentIndex == 0)
            StreamBuilder<int>(
              stream: _unreadNotificationCount(),
              builder: (_, snap) {
                final count = snap.data ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettings,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePostScreen(),
            ),
          );
          _loadPosts();
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined), label: "Explore"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

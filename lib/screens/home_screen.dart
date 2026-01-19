import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_screen.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';
import 'comments_screen.dart';
import 'other_profile_screen.dart';
import 'notification_screen.dart';

import '../services/post_service.dart';
import '../services/follow_service.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';

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
    if (user == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((rows) {
      final unread = rows.where((n) =>
      n['user_id'] == user.id &&
          n['is_read'] == false);
      return unread.length;
    });
  }

  // ---------------- POST CARD ----------------
  Widget _buildPost(Map<String, dynamic> post) {
    final currentUser = _supabase.auth.currentUser;
    final profile = post['profiles'];

    final String userName = profile?['name'] ?? 'Traveler';
    final String? avatarUrl = profile?['avatar_url'];
    final bool isMyPost = post['user_id'] == currentUser?.id;

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
                backgroundColor: Colors.grey,
                backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            title: GestureDetector(
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
              child: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(post['location'] ?? ''),
            trailing: isMyPost
                ? null
                : FutureBuilder<bool>(
              future: _followService.isFollowing(post['user_id']),
              builder: (_, snap) {
                final isFollowing = snap.data ?? false;
                return OutlinedButton(
                  onPressed: () async {
                    isFollowing
                        ? await _followService
                        .unfollowUser(post['user_id'])
                        : await _followService
                        .followUser(post['user_id']);
                    setState(() {});
                  },
                  child:
                  Text(isFollowing ? "Following" : "Follow"),
                );
              },
            ),
          ),

          // ---------- IMAGE ----------
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              post['media_url'],
              fit: BoxFit.cover,
            ),
          ),

          // ---------- ACTIONS ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // ❤️ REALTIME LIKES
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('likes')
                      .stream(primaryKey: ['id'])
                      .where((rows) =>
                      rows.any((r) => r['post_id'] == post['id'])),
                  builder: (_, snap) {
                    final likes = snap.data
                        ?.where((l) => l['post_id'] == post['id'])
                        .toList() ??
                        [];
                    final isLiked = likes.any(
                            (l) => l['user_id'] == currentUser?.id);

                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                            isLiked ? Colors.red : Colors.black,
                          ),
                          onPressed: () async {
                            isLiked
                                ? await _likeService
                                .unlikePost(post['id'])
                                : await _likeService
                                .likePost(post['id']);
                          },
                        ),
                        if (likes.isNotEmpty)
                          Text(
                            likes.length.toString(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                      ],
                    );
                  },
                ),

                // 💬 COMMENTS
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CommentsScreen(postId: post['id']),
                      ),
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
            child: FutureBuilder<int>(
              future: _commentService.countComments(post['id']),
              builder: (_, snap) {
                if (!snap.hasData || snap.data == 0) {
                  return const SizedBox();
                }
                return Text(
                  "View ${snap.data} comments",
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey),
                );
              },
            ),
          ),

          // ---------- CAPTION ----------
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: '$userName ',
                    style:
                    const TextStyle(fontWeight: FontWeight.bold),
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
        return const Center(child: Text("Search"));
      case 2:
        return const Center(child: Text("Messages"));
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
          // 🔔 NOTIFICATIONS (HOME ONLY)
          if (_currentIndex == 0)
            StreamBuilder<int>(
              stream: _unreadNotificationCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const NotificationScreen(),
                          ),
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),

          // ⚙ SETTINGS (PROFILE ONLY)
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: "Messages"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

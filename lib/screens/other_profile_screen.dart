import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/post_service.dart';
import '../services/follow_service.dart';

class OtherProfileScreen extends StatefulWidget {
  final String userId;

  const OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _postService = PostService();
  final _followService = FollowService();

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _posts = [];

  int _followers = 0;
  int _following = 0;

  bool _loading = true;
  bool _isFollowing = false;

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

    setState(() => _loading = false);
  }

  // ---------------- PROFILE ----------------
  Future<void> _loadProfile() async {
    _profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', widget.userId)
        .maybeSingle();
  }

  // ---------------- POSTS ----------------
  Future<void> _loadPosts() async {
    final data = await _supabase
        .from('posts')
        .select('id, media_url')
        .eq('user_id', widget.userId)
        .order('created_at', ascending: false);

    _posts = List<Map<String, dynamic>>.from(data);
  }

  // ---------------- FOLLOW COUNTS ----------------
  Future<void> _loadFollowCounts() async {
    _followers =
    await _followService.countFollowers(widget.userId);
    _following =
    await _followService.countFollowing(widget.userId);
  }

  // ---------------- CHECK FOLLOW ----------------
  Future<void> _checkFollowing() async {
    _isFollowing =
    await _followService.isFollowing(widget.userId);
  }

  // ---------------- TOGGLE FOLLOW ----------------
  Future<void> _toggleFollow() async {
    if (_isFollowing) {
      await _followService.unfollowUser(widget.userId);
    } else {
      await _followService.followUser(widget.userId);
    }

    await _loadFollowCounts();
    await _checkFollowing();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['name'] ?? 'Traveler';
    final bio = _profile?['bio'] ?? '';
    final avatar = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- HEADER ----------
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                  avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                          title: 'Posts',
                          value: _posts.length.toString()),
                      _StatItem(
                          title: 'Followers',
                          value: _followers.toString()),
                      _StatItem(
                          title: 'Following',
                          value: _following.toString()),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ---------- NAME ----------
            Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 4),

            // ---------- BIO ----------
            if (bio.isNotEmpty)
              Text(bio, style: const TextStyle(fontSize: 14)),

            const SizedBox(height: 12),

            // ---------- FOLLOW BUTTON ----------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleFollow,
                child:
                Text(_isFollowing ? 'Following' : 'Follow'),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),

            // ---------- POSTS GRID ----------
            _posts.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No posts')),
            )
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
              itemBuilder: (_, i) => Image.network(
                _posts[i]['media_url'],
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- STAT ITEM ----------------
class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(title,
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

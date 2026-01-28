import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import 'post_detail_screen.dart';
import 'edit_post_screen.dart';
import '../services/post_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadingProfile = true;
  bool _loadingPosts = true;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _myPosts = [];

  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMyPosts();
  }

  // ✅ ADDED: check video url
  bool _isVideoUrl(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.avi') ||
        u.endsWith('.mkv') ||
        u.contains('.mp4?') ||
        u.contains('.mov?') ||
        u.contains('.avi?') ||
        u.contains('.mkv?');
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _loadingProfile = false);
        return;
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _profile = data;
        _loadingProfile = false;
      });
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }

  // ---------------- LOAD MY POSTS ----------------
  Future<void> _loadMyPosts() async {
    setState(() => _loadingPosts = true);
    final posts = await _postService.fetchMyPosts();
    setState(() {
      _myPosts = posts;
      _loadingPosts = false;
    });
  }

  // ---------------- FOLLOW COUNTS (FIXED) ----------------
  Stream<int> _followersCount() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Stream.empty();

    return Supabase.instance.client
        .from('follows')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows.where((r) => r['following_id'] == user.id).length,
    );
  }

  Stream<int> _followingCount() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return const Stream.empty();

    return Supabase.instance.client
        .from('follows')
        .stream(primaryKey: ['id'])
        .map(
          (rows) => rows.where((r) => r['follower_id'] == user.id).length,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(
        child: Text("Profile not found", style: TextStyle(color: Colors.grey)),
      );
    }

    final String name = (_profile!['name'] ?? '').toString().trim().isNotEmpty
        ? _profile!['name']
        : 'Your name';

    final String? username = _profile!['username'];
    final String bio = (_profile!['bio'] ?? '').toString();
    final String? avatarUrl = _profile!['avatar_url'];
    final String? website = _profile!['website'];
    final String? location = _profile!['location'];
    final String? homeCountry = _profile!['home_country'];
    final List interests = _profile!['interests'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- TOP ----------
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(title: "Posts", value: "${_myPosts.length}"),

                    // ✅ FOLLOWERS (REALTIME)
                    StreamBuilder<int>(
                      stream: _followersCount(),
                      builder: (_, snap) {
                        return _StatItem(
                          title: "Followers",
                          value: (snap.data ?? 0).toString(),
                        );
                      },
                    ),

                    // ✅ FOLLOWING (REALTIME)
                    StreamBuilder<int>(
                      stream: _followingCount(),
                      builder: (_, snap) {
                        return _StatItem(
                          title: "Following",
                          value: (snap.data ?? 0).toString(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------- NAME ----------
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          // ---------- USERNAME ----------
          if (username != null && username.isNotEmpty)
            Text('@$username', style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 6),

          // ---------- BIO ----------
          if (bio.isNotEmpty) Text(bio, style: const TextStyle(fontSize: 14)),

          const SizedBox(height: 8),

          // ---------- LOCATION ----------
          if (location != null || homeCountry != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  [location, homeCountry].where((e) => e != null).join(', '),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

          // ---------- WEBSITE ----------
          if (website != null && website.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(website);
                  if (await canLaunchUrl(uri)) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  website,
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // ---------- INTERESTS ----------
          if (interests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: interests
                    .map<Widget>(
                      (i) => Chip(
                    label: Text(i.toString()),
                    backgroundColor: Colors.grey[200],
                  ),
                )
                    .toList(),
              ),
            ),

          const SizedBox(height: 14),

          // ---------- EDIT PROFILE ----------
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                );

                if (updated == true) {
                  _loadProfile();
                }
              },
              child: const Text("Edit Profile"),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),

          // ---------- POSTS GRID ----------
          _loadingPosts
              ? const Center(child: CircularProgressIndicator())
              : _myPosts.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text("No posts yet")),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myPosts.length,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemBuilder: (context, index) {
              final post = _myPosts[index];

              return GestureDetector(
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(postId: post['id']),
                    ),
                  );

                  if (updated == true) {
                    _loadMyPosts();
                  }
                },
                onLongPress: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPostScreen(
                        postId: post['id'],
                        initialCaption: post['caption'],
                        initialLocation: post['location'],
                      ),
                    ),
                  );

                  if (updated == true) {
                    _loadMyPosts();
                  }
                },

                // ✅ FIXED PART: video thumbnail preview instead of Image.network
                child: Builder(
                  builder: (_) {
                    final String url = (post['media_url'] ?? '').toString();

                    if (url.isEmpty) {
                      return Container(color: Colors.grey[300]);
                    }

                    if (_isVideoUrl(url)) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.videocam,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    }

                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
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
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

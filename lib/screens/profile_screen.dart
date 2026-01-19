import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import '../services/post_service.dart';

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
    final posts = await _postService.fetchMyPosts();
    setState(() {
      _myPosts = posts;
      _loadingPosts = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return const Center(
        child: Text(
          "Profile not found",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // ---------- SAFE VALUES ----------
    final String name =
    (_profile!['name'] as String?)?.trim().isNotEmpty == true
        ? _profile!['name']
        : 'Your name';

    final String bio =
    (_profile!['bio'] as String?)?.trim().isNotEmpty == true
        ? _profile!['bio']
        : 'Add a bio';

    final String? avatarUrl = _profile!['avatar_url'] as String?;

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
                backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                        title: "Posts", value: "${_myPosts.length}"),
                    const _StatItem(title: "Followers", value: "0"),
                    const _StatItem(title: "Following", value: "0"),
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
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 4),

          // ---------- BIO ----------
          Text(
            bio,
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 12),

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
              return Image.network(
                _myPosts[index]['media_url'],
                fit: BoxFit.cover,
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}

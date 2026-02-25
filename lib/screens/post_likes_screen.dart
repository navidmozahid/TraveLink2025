import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/follow_service.dart';
import 'other_profile_screen.dart';

class PostLikesScreen extends StatefulWidget {
  final String postId;

  const PostLikesScreen({super.key, required this.postId});

  @override
  State<PostLikesScreen> createState() => _PostLikesScreenState();
}

class _PostLikesScreenState extends State<PostLikesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FollowService _followService = FollowService();

  bool _loading = true;
  List<Map<String, dynamic>> _likers = [];

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    try {
      // ✅ 1) Get likes for this post
      final likesData = await _supabase
          .from('likes')
          .select('user_id')
          .eq('post_id', widget.postId);

      final likes = List<Map<String, dynamic>>.from(likesData);

      if (likes.isEmpty) {
        if (!mounted) return;
        setState(() {
          _likers = [];
          _loading = false;
        });
        return;
      }

      // ✅ 2) Convert all userIds to String
      final List<String> userIds = likes
          .map((l) => (l['user_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      if (userIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _likers = [];
          _loading = false;
        });
        return;
      }

      // ✅ 3) Load user_type
      final usersData = await _supabase
          .from('app_users')
          .select('id, user_type')
          .inFilter('id', userIds);

      final users = List<Map<String, dynamic>>.from(usersData);

      final Map<String, Map<String, dynamic>> userMap = {
        for (final u in users) (u['id'] ?? '').toString(): u,
      };

// ✅ 4) Load traveler profiles
      final profilesData = await _supabase
          .from('profiles')
          .select('id, name, username, avatar_url')
          .inFilter('id', userIds);

      final profiles = List<Map<String, dynamic>>.from(profilesData);

      final Map<String, Map<String, dynamic>> profileMap = {
        for (final p in profiles) (p['id'] ?? '').toString(): p,
      };

// ✅ 5) Load business accounts
      final businessData = await _supabase
          .from('business_accounts')
          .select('id, agency_name, logo_url')
          .inFilter('id', userIds);

      final businesses = List<Map<String, dynamic>>.from(businessData);

      final Map<String, Map<String, dynamic>> businessMap = {
        for (final b in businesses) (b['id'] ?? '').toString(): b,
      };

// ✅ 6) Merge likes properly
      final merged = <Map<String, dynamic>>[];

      for (final like in likes) {
        final uid = (like['user_id'] ?? '').toString();
        final user = userMap[uid];

        if (user == null) continue;

        final bool isBusiness =
            user['user_type'] == 'agency' ||
                user['user_type'] == 'business';

        final profile = isBusiness
            ? businessMap[uid]
            : profileMap[uid];

        if (profile != null) {
          merged.add({
            'user_id': uid,
            'profile': profile,
            'isBusiness': isBusiness,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _likers = merged;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Load likes error: $e");
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Likes"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _likers.isEmpty
          ? const Center(child: Text("No likes yet"))
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('follows').stream(primaryKey: ['id']),
        builder: (_, snap) {
          final follows = snap.data ?? [];

          return ListView.builder(
            itemCount: _likers.length,
            itemBuilder: (_, i) {
              final row = _likers[i];
              final Map<String, dynamic>? profile =
              row['profile'] as Map<String, dynamic>?;

              final bool isBusiness =
                  (row['isBusiness'] as bool?) ?? false;

              final String userId = row['user_id'].toString();

              String name;
              String username;
              String? avatar;

              if (isBusiness) {
                name = profile?['agency_name']?.toString() ?? "Business";
                username = "";
                avatar = profile?['logo_url']?.toString();
              } else {
                name = profile?['name']?.toString() ?? "Traveler";
                username = profile?['username']?.toString() ?? "";
                avatar = profile?['avatar_url']?.toString();
              }

              final bool isMe = myId != null && userId == myId;

              final bool isFollowing = myId != null &&
                  follows.any((f) =>
                  f['follower_id'] == myId &&
                      f['following_id'] == userId);

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  (avatar != null && avatar.toString().isNotEmpty)
                      ? NetworkImage(avatar)
                      : null,
                  child: (avatar == null ||
                      avatar.toString().isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle:
                username.isNotEmpty ? Text("@$username") : null,

                // ✅ Follow / Following button (Instagram style)
                trailing: isMe
                    ? null
                    : OutlinedButton(
                  onPressed: () async {
                    if (isFollowing) {
                      await _followService.unfollowUser(userId);
                    } else {
                      await _followService.followUser(userId);
                    }
                  },
                  child:
                  Text(isFollowing ? "Following" : "Follow"),
                ),

                // ✅ Visit profile when tap anywhere
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          OtherProfileScreen(userId: userId),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

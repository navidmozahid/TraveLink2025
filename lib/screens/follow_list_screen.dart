import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'other_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userId;
  final bool showFollowers; // true = followers, false = following
  final bool mutualOnly; // true = mutual list only

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.showFollowers,
    required this.mutualOnly,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final myId = _supabase.auth.currentUser?.id;
      if (myId == null) {
        setState(() => _loading = false);
        return;
      }

      // ✅ FULL Followers list
      if (!widget.mutualOnly && widget.showFollowers) {
        final rows = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('following_id', widget.userId);

        final ids = List<Map<String, dynamic>>.from(rows)
            .map((r) => (r['follower_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();

        if (ids.isEmpty) {
          setState(() {
            _users = [];
            _loading = false;
          });
          return;
        }

        final data = await _supabase
            .from('app_users')
            .select('id, name, username, avatar_url')
            .inFilter('id', ids);

        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
        return;
      }

      // ✅ FULL Following list
      if (!widget.mutualOnly && !widget.showFollowers) {
        final rows = await _supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', widget.userId);

        final ids = List<Map<String, dynamic>>.from(rows)
            .map((r) => (r['following_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();

        if (ids.isEmpty) {
          setState(() {
            _users = [];
            _loading = false;
          });
          return;
        }

        final data = await _supabase
            .from('app_users')
            .select('id, name, username, avatar_url')
            .inFilter('id', ids);

        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
        return;
      }

      // ✅ MUTUAL Followers list (for other user profile)
      if (widget.mutualOnly && widget.showFollowers) {
        // followers of profile user
        final targetFollowersRows = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('following_id', widget.userId);

        final targetFollowers =
        List<Map<String, dynamic>>.from(targetFollowersRows)
            .map((r) => (r['follower_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        // followers of me
        final myFollowersRows = await _supabase
            .from('follows')
            .select('follower_id')
            .eq('following_id', myId);

        final myFollowers = List<Map<String, dynamic>>.from(myFollowersRows)
            .map((r) => (r['follower_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        // intersection
        final mutualIds = targetFollowers.intersection(myFollowers).toList();

        if (mutualIds.isEmpty) {
          setState(() {
            _users = [];
            _loading = false;
          });
          return;
        }

        final profiles = await _supabase
            .from('app_users')
            .select('id, name, username, avatar_url')
            .inFilter('id', mutualIds);

        setState(() {
          _users = List<Map<String, dynamic>>.from(profiles);
          _loading = false;
        });
        return;
      }

      // ✅ MUTUAL Following list (for other user profile)
      if (widget.mutualOnly && !widget.showFollowers) {
        // users that profile user follows
        final targetFollowingRows = await _supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', widget.userId);

        final targetFollowing =
        List<Map<String, dynamic>>.from(targetFollowingRows)
            .map((r) => (r['following_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        // users that I follow
        final myFollowingRows = await _supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', myId);

        final myFollowing = List<Map<String, dynamic>>.from(myFollowingRows)
            .map((r) => (r['following_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();

        // intersection
        final mutualIds = targetFollowing.intersection(myFollowing).toList();

        if (mutualIds.isEmpty) {
          setState(() {
            _users = [];
            _loading = false;
          });
          return;
        }

        final profiles = await _supabase
            .from('app_users')
            .select('id, name, username, avatar_url')
            .inFilter('id', mutualIds);

        setState(() {
          _users = List<Map<String, dynamic>>.from(profiles);
          _loading = false;
        });
        return;
      }

      // fallback
      setState(() => _loading = false);
    } catch (e) {
      debugPrint("Follow list load error: $e");
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mutualOnly
        ? (widget.showFollowers ? "Mutual Followers" : "Mutual Following")
        : (widget.showFollowers ? "Followers" : "Following");

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text("No users found"))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (_, i) {
          final u = _users[i];

          final String id = (u['id'] ?? '').toString();
          final String name =
          (u['name'] ?? 'Traveler').toString();
          final String username = (u['username'] ?? '').toString();
          final String? avatar = u['avatar_url'];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
              (avatar != null && avatar.toString().isNotEmpty)
                  ? NetworkImage(avatar)
                  : null,
              child:
              (avatar == null || avatar.toString().isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
            username.isNotEmpty ? Text("@$username") : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OtherProfileScreen(userId: id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

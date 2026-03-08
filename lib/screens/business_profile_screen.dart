import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/supabase_agency_service.dart';
import '../services/message_service.dart';
import 'edit_business_profile_screen.dart';
import 'post_detail_screen.dart';
import 'chat_screen.dart';
import 'follow_list_screen.dart';


class BusinessProfileScreen extends StatefulWidget {
  final String businessId;
  final bool isOwner;

  const BusinessProfileScreen({
    super.key,
    required this.businessId,
    this.isOwner = false,
  });

  @override
  State<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseAgencyService _agencyService =
  SupabaseAgencyService();
  final SupabaseClient _supabase =
      Supabase.instance.client;
  final MessageService _messageService =
  MessageService();
  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;

  Map<String, dynamic>? _business;
  List<Map<String, dynamic>> _posts = [];

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

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this);
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    await Future.wait([
      _loadBusinessProfile(),
      _loadBusinessPosts(),
    ]);
  }

  Future<void> _loadBusinessProfile() async {
    final data =
    await _agencyService.getBusinessProfileById(
        widget.businessId);
    if (!mounted) return;
    setState(() {
      _business = data;
      _loading = false;
    });
  }

  Future<void> _loadBusinessPosts() async {
    final posts = await _supabase
        .from('posts')
        .select('id, created_at')
        .eq('user_id', widget.businessId)
        .order('created_at', ascending: false);

    if (posts.isEmpty) {
      setState(() => _posts = []);
      return;
    }

    final postIds =
    posts.map((p) => p['id']).toList();

    final media = await _supabase
        .from('post_media')
        .select()
        .inFilter('post_id', postIds);

    final Map<String, String> previewMap = {};
    for (final m in media) {
      previewMap.putIfAbsent(
          m['post_id'], () => m['media_url']);
    }

    setState(() {
      _posts = posts
          .map<Map<String, dynamic>>((p) => {
        ...p,
        'preview_url': previewMap[p['id']],
      })
          .toList();
    });
  }

  Stream<int> _followersCount() {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
        .where((r) =>
    r['following_id'] ==
        widget.businessId)
        .length);
  }

  Stream<int> _followingCount() {
    return _supabase
        .from('follows')
        .stream(primaryKey: ['id'])
        .map((rows) => rows
        .where((r) =>
    r['follower_id'] ==
        widget.businessId)
        .length);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_business == null) {
      return const Scaffold(
        body: Center(child: Text("Business not found")),
      );
    }

    final logo = _business!['logo_url'];
    final name = _business!['agency_name'] ?? '';
    final type = _business!['agency_type'] ?? '';
    final phone = _business!['phone'];

    final location = [
      _business!['city'],
      _business!['country'],
    ]
        .where((e) =>
    e != null && e.toString().isNotEmpty)
        .join(', ');

    return Scaffold(
      appBar: widget.isOwner
          ? null
          : AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              /// ---------- HEADER ----------
              Padding(
                padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundImage: logo != null
                              ? NetworkImage(logo)
                              : null,
                          child: logo == null
                              ? const Icon(Icons.business)
                              : null,
                        ),

                        // ✅ EDIT ICON — OWNER ONLY
                        if (widget.isOwner)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditBusinessProfileScreen(
                                      business: _business!,
                                    ),
                                  ),
                                );
                                if (mounted) _reloadAll();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              location,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                          if (phone != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              phone.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// ---------- STATS ----------
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                    /// POSTS
                    _StatItem("Posts", _posts.length.toString()),

                    /// FOLLOWERS
                    StreamBuilder<int>(
                      stream: _followersCount(),
                      builder: (_, s) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: widget.businessId,
                                showFollowers: true,
                                mutualOnly: false, // 🔥 FULL LIST
                              ),
                            ),
                          );
                        },
                        child: _StatItem("Followers", '${s.data ?? 0}'),
                      ),
                    ),

                    /// FOLLOWING
                    StreamBuilder<int>(
                      stream: _followingCount(),
                      builder: (_, s) => GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: widget.businessId,
                                showFollowers: false,
                                mutualOnly: false, // 🔥 FULL LIST
                              ),
                            ),
                          );
                        },
                        child: _StatItem("Following", '${s.data ?? 0}'),
                      ),
                    ),
                  ],
                ),
              ),


              /// ---------- ACTION BUTTONS ----------
              if (!widget.isOwner)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase
                        .from('follows')
                        .stream(primaryKey: ['id']),
                    builder: (_, snap) {
                      final rows = (snap.data ?? [])
                          .where((r) => r['following_id'] == widget.businessId)
                          .toList();

                      final myId =
                          _supabase.auth.currentUser?.id;

                      final isFollowing = myId != null &&
                          rows.any((r) =>
                          r['follower_id'] == myId &&
                              r['following_id'] ==
                                  widget.businessId);

                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize:
                                const Size.fromHeight(44),
                                shape:
                                const StadiumBorder(),
                              ),
                              onPressed: myId == null
                                  ? null
                                  : () async {
                                if (isFollowing) {
                                  await _supabase
                                      .from('follows')
                                      .delete()
                                      .eq('follower_id', myId)
                                      .eq('following_id', widget.businessId);
                                } else {
                                  await _supabase
                                      .from('follows')
                                      .insert({
                                    'follower_id': myId,
                                    'following_id': widget.businessId,
                                  });
                                }
                              },

                              child: Text(
                                  isFollowing
                                      ? "Following"
                                      : "Follow"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                minimumSize:
                                const Size.fromHeight(44),
                                shape:
                                const StadiumBorder(),
                              ),
                              onPressed: () async {
                                final conversationId =
                                await _messageService
                                    .getOrCreateConversation(
                                    widget.businessId);

                                if (!mounted) return;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId:
                                      conversationId,
                                      otherUser: {
                                        'id':
                                        widget.businessId,
                                        'name': name,
                                        'avatar_url': logo,
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Message"),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              /// ---------- TABS ----------
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(text: "About"),
                ],
              ),

              /// ---------- TAB BODY ----------
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    GridView.builder(
                      padding: const EdgeInsets.all(2),
                      itemCount: _posts.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemBuilder: (_, i) {
                        final post = _posts[i];
                        final url =
                        post['preview_url'];

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
                          child: Builder(
                            builder: (_) {
                              final String mediaUrl = (url ?? '').toString();

                              if (mediaUrl.isEmpty) {
                                return Container(color: const Color(0xFF475569));
                              }

                              if (_isVideoUrl(mediaUrl)) {
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
                                mediaUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: const Color(0xFF475569),
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
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Builder(
                        builder: (_) {
                          final documents =
                              (_business!['documents'] as List?)?.cast<String>() ?? [];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _aboutItem("Description", _business!['description']),
                              _aboutItem("Phone", _business!['phone']),
                              _aboutItem("Email", _business!['email']),
                              _aboutItem("Address", _business!['address']),
                              _aboutItem("License ID", _business!['license_id']),
                              _aboutItem("Status", _business!['status']),

                              if (documents.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  "Documents",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                for (final doc in documents)
                                  InkWell(
                                    onTap: () async {
                                      final url = Supabase.instance.client.storage
                                          .from('business-docs')
                                          .getPublicUrl(doc);

                                      await launchUrl(
                                        Uri.parse(url),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        doc.split('/').last,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),


                  ],
                ),
              ),
            ],
          ),

          if (_uploading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black45,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _aboutItem(String label, dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return const SizedBox();
  }

  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;
  const _StatItem(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            )),
      ],
    );
  }
}

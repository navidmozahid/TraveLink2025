import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/message_service.dart';
import '../screens/chat_screen.dart';

class SharePostSheet extends StatefulWidget {
  final String postId;

  const SharePostSheet({super.key, required this.postId});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MessageService _messageService = MessageService();

  final TextEditingController _search = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();

    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      setState(() {
        _filtered = _users.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final username = (u['username'] ?? '').toString().toLowerCase();
          return name.contains(q) || username.contains(q);
        }).toList();
      });
    });
  }

  Future<void> _loadUsers() async {
    try {
      final myId = _supabase.auth.currentUser?.id;

      final data = await _supabase
          .from('profiles')
          .select('id, name, username, avatar_url')
          .order('name', ascending: true);

      _users = List<Map<String, dynamic>>.from(data);

      // ✅ remove myself
      if (myId != null) {
        _users.removeWhere((u) => u['id'] == myId);
      }

      _filtered = List<Map<String, dynamic>>.from(_users);

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareToUser(Map<String, dynamic> user) async {
    final String otherUserId = user['id'].toString();

    try {
      final conversationId =
      await _messageService.getOrCreateConversation(otherUserId);

      // ✅ restore chat for sender (if deleted previously)
      await _messageService.restoreChatForMe(conversationId);

      // ✅ send shared post message
      await _messageService.sendSharedPostMessage(
        conversationId: conversationId,
        sharedPostId: widget.postId,
      );

      if (!mounted) return;

      Navigator.pop(context); // close bottom sheet

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUser: {
              "id": otherUserId,
              "name": user['name'],
              "username": user['username'],
              "avatar_url": user['avatar_url'],
            },
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post shared ✅")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Share failed: $e")),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: const [
                Expanded(
                  child: Text(
                    "Share",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text("No users found")),
              )
            else
              SizedBox(
                height: 420,
                child: GridView.builder(
                  itemCount: _filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (_, i) {
                    final user = _filtered[i];

                    final avatarUrl = user['avatar_url'];
                    final name = (user['name'] ?? '').toString();
                    final username = (user['username'] ?? '').toString();

                    return InkWell(
                      onTap: () => _shareToUser(user),
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: (avatarUrl != null &&
                                avatarUrl.toString().isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: (avatarUrl == null ||
                                avatarUrl.toString().isEmpty)
                                ? const Icon(Icons.person, size: 28)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name.isNotEmpty ? name : username,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

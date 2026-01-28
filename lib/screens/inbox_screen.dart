import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/message_service.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MessageService _messageService = MessageService();

  bool _loading = true;
  List<Map<String, dynamic>> _conversations = [];

  RealtimeChannel? _inboxChannel;

  @override
  void initState() {
    super.initState();
    _loadInbox();
    _listenInboxRealtime();
  }

  @override
  void dispose() {
    _inboxChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadInbox() async {
    setState(() => _loading = true);

    final userId = _supabase.auth.currentUser!.id;

    try {
      final convos = await _supabase
          .from('conversations')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_at', ascending: false);

      final deleted = await _supabase
          .from('conversation_deletes')
          .select('conversation_id')
          .eq('user_id', userId);

      final deletedIds =
      deleted.map((e) => e['conversation_id'] as String).toSet();

      final filtered = convos
          .where((c) => !deletedIds.contains(c['id']))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final List<Map<String, dynamic>> finalList = [];

      for (final c in filtered) {
        final otherId =
        (c['user1_id'] == userId) ? c['user2_id'] : c['user1_id'];

        final otherProfile = await _supabase
            .from('profiles')
            .select('id, name, username, avatar_url')
            .eq('id', otherId)
            .single();

        // ✅ unread count
        final unreadCount = await _messageService.countUnreadMessages(c['id']);

        finalList.add({
          ...c,
          'other_user': otherProfile,
          'unread_count': unreadCount,
        });
      }

      setState(() {
        _conversations = finalList;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Inbox error: $e");
      setState(() => _loading = false);
    }
  }

  // ✅ Realtime inbox updates when last_message changes
  void _listenInboxRealtime() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _inboxChannel?.unsubscribe();

    _inboxChannel = _supabase.channel("inbox:$userId");

    // ✅ 1) when last_message updates (new message)
    _inboxChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: "public",
      table: "conversations",
      callback: (payload) {
        _loadInbox();
      },
    );

    // ✅ 2) when chat deleted (insert into conversation_deletes)
    _inboxChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: "public",
      table: "conversation_deletes",
      callback: (payload) {
        _loadInbox();
      },
    );

    // ✅ 3) when chat restored (delete from conversation_deletes)
    _inboxChannel!.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: "public",
      table: "conversation_deletes",
      callback: (payload) {
        _loadInbox();
      },
    );

    _inboxChannel!.subscribe();
  }

  Future<void> _deleteChat(String conversationId) async {
    await _messageService.deleteChatForMe(conversationId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat deleted")),
    );

    _loadInbox();
  }

  // ✅ Instagram style time formatter
  String _timeAgo(String? isoTime) {
    if (isoTime == null) return "";

    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return "now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m";
      if (diff.inHours < 24) return "${diff.inHours}h";
      if (diff.inDays < 7) return "${diff.inDays}d";

      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? const Center(child: Text("No conversations yet"))
          : RefreshIndicator(
        onRefresh: _loadInbox,
        child: ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (context, index) {
            final convo = _conversations[index];
            final other = convo['other_user'];

            final lastMessage = convo['last_message'] ?? "";
            final lastMessageAt = convo['last_message_at'];

            final int unreadCount = convo['unread_count'] ?? 0;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: convo['id'],
                      otherUser: other,
                    ),
                  ),
                ).then((_) => _loadInbox());
              },
              onLongPress: () async {
                final action = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("Delete Chat"),
                          onTap: () =>
                              Navigator.pop(context, "delete"),
                        ),
                      ],
                    ),
                  ),
                );

                if (action == "delete") {
                  _deleteChat(convo['id']);
                }
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: (other['avatar_url'] != null &&
                      other['avatar_url']
                          .toString()
                          .isNotEmpty)
                      ? NetworkImage(other['avatar_url'])
                      : null,
                  child: (other['avatar_url'] == null ||
                      other['avatar_url'].toString().isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(other['name'] ??
                    other['username'] ??
                    "User"),
                subtitle: Text(
                  "${other['username'] != null ? "@${other['username']} • " : ""}${lastMessage.toString().isEmpty ? "No messages yet" : lastMessage}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                // ✅ FIXED: no overflow (compact trailing)
                trailing: SizedBox(
                  width: 45,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _timeAgo(lastMessageAt?.toString()),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

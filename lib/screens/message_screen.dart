import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final supabase = Supabase.instance.client;
  final MessageService _messageService = MessageService();

  bool _loading = true;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    setState(() => _loading = true);

    final userId = supabase.auth.currentUser!.id;

    try {
      final convos = await supabase
          .from('conversations')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_at', ascending: false);

      final deleted = await supabase
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

        final otherProfile = await supabase
            .from('profiles')
            .select('id, name, username, avatar_url')
            .eq('id', otherId)
            .single();

        finalList.add({
          ...c,
          'other_user': otherProfile,
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

  Future<void> _deleteChat(String conversationId) async {
    await _messageService.deleteChatForMe(conversationId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat deleted")),
    );

    _loadInbox();
  }

  void _openChat(String conversationId, Map<String, dynamic> otherUser) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversationId,
          otherUser: otherUser,
        ),
      ),
    ).then((_) => _loadInbox());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        actions: [
          IconButton(
            onPressed: _loadInbox,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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

            return InkWell(
              onTap: () => _openChat(convo['id'], other),
              onLongPress: () async {
                final action = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) {
                    return SafeArea(
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
                    );
                  },
                );

                if (action == "delete") {
                  _deleteChat(convo['id']);
                }
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: (other['avatar_url'] != null &&
                      other['avatar_url'].toString().isNotEmpty)
                      ? NetworkImage(other['avatar_url'])
                      : null,
                  child: (other['avatar_url'] == null ||
                      other['avatar_url'].toString().isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(other['username'] ?? "User"),
                subtitle: Text(
                  lastMessage.toString().isEmpty
                      ? "No messages yet"
                      : lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

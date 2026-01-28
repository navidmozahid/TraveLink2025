import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/message_service.dart';
import 'post_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final supabase = Supabase.instance.client;
  final MessageService _messageService = MessageService();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  bool _loading = true;
  bool _uploadingImage = false;

  List<Map<String, dynamic>> _messages = [];

  RealtimeChannel? _channel;

  // ✅ Typing indicator variables
  bool _isOtherUserTyping = false;
  DateTime? _lastTypingTime;
  RealtimeChannel? _typingChannel;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _listenRealtime();

    // ✅ NEW: Restore chat when opening chat screen (bring back in inbox)
    _restoreChatForMe();

    // ✅ mark messages as read when chat opens (Instagram style)
    _markAsReadOnOpen();

    // ✅ typing listener + typing controller
    _listenTypingRealtime();
    _controller.addListener(_handleTyping);
  }

  // ✅ NEW: Restore chat for me
  Future<void> _restoreChatForMe() async {
    try {
      await _messageService.restoreChatForMe(widget.conversationId);
    } catch (e) {
      debugPrint("Restore chat error: $e");
    }
  }

  Future<void> _markAsReadOnOpen() async {
    try {
      await _messageService.markConversationAsRead(widget.conversationId);
    } catch (e) {
      debugPrint("Mark read error: $e");
    }
  }

  // ✅ handle typing events
  void _handleTyping() {
    final now = DateTime.now();

    if (_lastTypingTime == null ||
        now.difference(_lastTypingTime!).inMilliseconds > 800) {
      _lastTypingTime = now;

      _messageService.setTypingStatus(
        conversationId: widget.conversationId,
        isTyping: true,
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      final last = _lastTypingTime;
      if (last == null) return;

      final diff = DateTime.now().difference(last);
      if (diff.inSeconds >= 2) {
        _messageService.setTypingStatus(
          conversationId: widget.conversationId,
          isTyping: false,
        );
      }
    });
  }

  // ✅ listen typing status realtime
  void _listenTypingRealtime() {
    final myId = supabase.auth.currentUser?.id;
    if (myId == null) return;

    _typingChannel?.unsubscribe();

    _typingChannel = supabase.channel("typing:${widget.conversationId}");

    _typingChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: "public",
      table: "typing_status",
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: "conversation_id",
        value: widget.conversationId,
      ),
      callback: (payload) {
        final record = payload.newRecord;
        if (record['user_id'] == myId) return;

        setState(() {
          _isOtherUserTyping = record['is_typing'] == true;
        });
      },
    );

    _typingChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: "public",
      table: "typing_status",
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: "conversation_id",
        value: widget.conversationId,
      ),
      callback: (payload) {
        final record = payload.newRecord;
        if (record['user_id'] == myId) return;

        setState(() {
          _isOtherUserTyping = record['is_typing'] == true;
        });
      },
    );

    // ✅ FIX: subscribe only once
    _typingChannel!.subscribe();
  }

  @override
  void dispose() {
    // ✅ stop typing when leaving chat
    _messageService.setTypingStatus(
      conversationId: widget.conversationId,
      isTyping: false,
    );

    _controller.dispose();
    _scrollController.dispose();
    _channel?.unsubscribe();
    _typingChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);

    try {
      final data = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('created_at', ascending: true);

      setState(() {
        _messages = data.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("Load messages error: $e");
      setState(() => _loading = false);
    }
  }

  // ✅ FIXED: subscribe only ONCE
  void _listenRealtime() {
    _channel?.unsubscribe();

    _channel = supabase.channel("chat:${widget.conversationId}");

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: "public",
      table: "messages",
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: "conversation_id",
        value: widget.conversationId,
      ),
      callback: (payload) async {
        await _loadMessages();
        await _messageService.markConversationAsRead(widget.conversationId);
      },
    );

    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: "public",
      table: "messages",
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: "conversation_id",
        value: widget.conversationId,
      ),
      callback: (payload) async {
        await _loadMessages();
      },
    );

    // ✅ only one subscribe
    _channel!.subscribe();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    try {
      // ✅ NEW: restore chat before send (so inbox shows again)
      await _messageService.restoreChatForMe(widget.conversationId);

      await _messageService.setTypingStatus(
        conversationId: widget.conversationId,
        isTyping: false,
      );

      await _messageService.sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );

      await _loadMessages();
    } catch (e) {
      debugPrint("Send message error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Send failed: $e")),
      );
    }
  }

  // ✅ pick image + upload + send image message
  Future<void> _pickAndSendImage() async {
    if (_uploadingImage) return;

    try {
      // ✅ NEW: restore chat before upload (so inbox shows again)
      await _messageService.restoreChatForMe(widget.conversationId);

      final XFile? picked =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

      if (picked == null) return;

      setState(() => _uploadingImage = true);

      final file = File(picked.path);

      final fileExt = picked.path.split('.').last;
      final fileName = const Uuid().v4();
      final filePath =
          "${supabase.auth.currentUser!.id}/${widget.conversationId}/$fileName.$fileExt";

      await supabase.storage.from('chat-media').upload(filePath, file);

      final imageUrl = supabase.storage.from('chat-media').getPublicUrl(filePath);

      await _messageService.sendMediaMessage(
        conversationId: widget.conversationId,
        mediaUrl: imageUrl,
        mediaType: "image",
      );

      await _loadMessages();
    } catch (e) {
      debugPrint("Upload image error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image upload failed: $e")),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    await _messageService.deleteMessage(messageId);

    await _loadMessages();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message deleted")),
    );
  }

  // ✅ NEW: Unsend message (delete for everyone)
  Future<void> _unsendMessage(String messageId) async {
    await _messageService.unsendMessage(messageId);

    await _loadMessages();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Message unsent")),
    );
  }

  // ✅ delete chat inside ChatScreen
  Future<void> _deleteChat() async {
    await _messageService.deleteChatForMe(widget.conversationId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat deleted")),
    );

    Navigator.pop(context);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser!.id;

    // ✅ Find last message I sent
    Map<String, dynamic>? lastMyMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i]['sender_id'] == myId) {
        lastMyMessage = _messages[i];
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: (widget.otherUser['avatar_url'] != null &&
                  widget.otherUser['avatar_url'].toString().isNotEmpty)
                  ? NetworkImage(widget.otherUser['avatar_url'])
                  : null,
              child: (widget.otherUser['avatar_url'] == null ||
                  widget.otherUser['avatar_url'].toString().isEmpty)
                  ? const Icon(Icons.person, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser['name'] ??
                      widget.otherUser['username'] ??
                      "Chat",
                  style: const TextStyle(fontSize: 16),
                ),
                if (_isOtherUserTyping)
                  const Text(
                    "typing...",
                    style: TextStyle(fontSize: 12, color: Colors.green),
                  )
                else if (widget.otherUser['username'] != null)
                  Text(
                    "@${widget.otherUser['username']}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == "delete_chat") {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Delete chat?"),
                    content:
                    const Text("This will delete the chat only for you."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  _deleteChat();
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "delete_chat",
                child: Text("Delete Chat"),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
              child: Text(
                "No messages yet",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];

                final isMe = msg['sender_id'] == myId;
                final isDeleted = msg['is_deleted'] == true;

                final bool isUnsent =
                    msg['deleted_for_everyone'] == true;

                final String? text = msg['text'];
                final String? mediaUrl = msg['media_url'];
                final String? mediaType = msg['media_type'];

                // ✅ NEW: shared post id
                final String? sharedPostId =
                msg['shared_post_id']?.toString();

                final bool isSharedPost =
                    sharedPostId != null && sharedPostId.isNotEmpty;

                final bool isImage = mediaType == "image" &&
                    mediaUrl != null &&
                    mediaUrl.isNotEmpty;

                final bool showSeen = isMe &&
                    lastMyMessage != null &&
                    msg['id'] == lastMyMessage['id'] &&
                    msg['is_read'] == true;

                return Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () async {
                        if (!isMe) return;

                        final action =
                        await showModalBottomSheet<String>(
                          context: context,
                          builder: (_) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text("Delete for me"),
                                  onTap: () => Navigator.pop(
                                      context, "delete_me"),
                                ),
                                ListTile(
                                  leading: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                      "Unsend (delete for everyone)"),
                                  onTap: () => Navigator.pop(
                                      context, "unsend"),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (action == "delete_me") {
                          _deleteMessage(msg['id']);
                        }

                        if (action == "unsend") {
                          _unsendMessage(msg['id']);
                        }
                      },
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          padding: (isImage && !isUnsent)
                              ? const EdgeInsets.all(4)
                              : const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isImage && !isUnsent)
                                ? Colors.transparent
                                : (isMe
                                ? Colors.blue.withOpacity(0.8)
                                : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: isUnsent
                              ? Text(
                            "Message unsent",
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                              : isDeleted
                              ? Text(
                            "Message deleted",
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                              : isSharedPost
                              ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PostDetailScreen(
                                        postId:
                                        sharedPostId,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              width: 220,
                              padding:
                              const EdgeInsets.all(
                                  10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.white
                                    .withOpacity(
                                    0.15)
                                    : Colors.white,
                                borderRadius:
                                BorderRadius
                                    .circular(12),
                                border: Border.all(
                                  color: Colors.black12,
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Icon(
                                    Icons
                                        .share_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Shared a post",
                                      style: TextStyle(
                                        color: Colors
                                            .white,
                                        fontWeight:
                                        FontWeight
                                            .w500,
                                      ),
                                      overflow:
                                      TextOverflow
                                          .ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              : isImage
                              ? ClipRRect(
                            borderRadius:
                            BorderRadius
                                .circular(14),
                            child: Image.network(
                              mediaUrl!,
                              width: 220,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                  Container(
                                    width: 220,
                                    height: 220,
                                    color: Colors
                                        .grey[300],
                                    child: const Icon(Icons
                                        .broken_image),
                                  ),
                            ),
                          )
                              : Text(
                            text ?? "",
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (showSeen)
                      const Padding(
                        padding: EdgeInsets.only(
                            right: 16, top: 2, bottom: 6),
                        child: Text(
                          "Seen",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  IconButton(
                    icon: _uploadingImage
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.photo),
                    onPressed: _uploadingImage ? null : _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}


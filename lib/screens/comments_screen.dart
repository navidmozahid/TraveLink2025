import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/comment_service.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final CommentService _commentService = CommentService();
  final TextEditingController _controller = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  // ---------------- LOAD COMMENTS ----------------
  Future<void> _loadComments() async {
    final data = await _commentService.fetchComments(widget.postId);
    setState(() {
      _comments = data;
      _loading = false;
    });
  }

  // ---------------- SEND COMMENT ----------------
  Future<void> _sendComment() async {
    if (_controller.text.trim().isEmpty) return;

    await _commentService.addComment(
      postId: widget.postId,
      content: _controller.text.trim(),
    );

    _controller.clear();
    _loadComments(); // 🔁 refresh list
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? const Center(child: Text("No comments yet"))
                : ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final c = _comments[index];
                final profile = c['profiles'];
                final isMyComment =
                    c['user_id'] == currentUser?.id;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                    profile?['avatar_url'] != null
                        ? NetworkImage(
                        profile['avatar_url'])
                        : null,
                    child: profile?['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    profile?['name'] ?? 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(c['content']),
                  trailing: isMyComment
                      ? IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () async {
                      await _commentService
                          .deleteComment(c['id']);
                      _loadComments();
                    },
                  )
                      : null,
                );
              },
            ),
          ),

          // ---------- INPUT ----------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

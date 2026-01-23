import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/comment_service.dart';
import 'other_profile_screen.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final CommentService _commentService = CommentService();
  final TextEditingController _controller = TextEditingController();

  String? _replyToCommentId;
  String? _replyToName;
  String? _editingCommentId;

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          // ================= COMMENTS =================
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _commentService.streamComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!;
                final parents =
                comments.where((c) => c['parent_id'] == null).toList();
                final replies =
                comments.where((c) => c['parent_id'] != null).toList();

                return ListView.builder(
                  itemCount: parents.length,
                  itemBuilder: (_, index) {
                    final c = parents[index];
                    final profile = c['profiles'];

                    final commentReplies = replies
                        .where((r) => r['parent_id'] == c['id'])
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _commentTile(c, profile, currentUser),
                        ...commentReplies.map(
                              (r) => Padding(
                            padding: const EdgeInsets.only(left: 48),
                            child:
                            _commentTile(r, r['profiles'], currentUser),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ================= INPUT =================
          SafeArea(
            child: Column(
              children: [
                if (_replyToName != null || _editingCommentId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          _editingCommentId != null
                              ? "Editing comment"
                              : "Replying to $_replyToName",
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _replyToCommentId = null;
                              _replyToName = null;
                              _editingCommentId = null;
                              _controller.clear();
                            });
                          },
                        )
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          if (_controller.text.trim().isEmpty) return;

                          if (_editingCommentId != null) {
                            await _commentService.updateComment(
                              commentId: _editingCommentId!,
                              content: _controller.text.trim(),
                            );
                          } else {
                            await _commentService.addComment(
                              postId: widget.postId,
                              content: _controller.text.trim(),
                              parentId: _replyToCommentId,
                            );
                          }

                          _controller.clear();
                          setState(() {
                            _replyToCommentId = null;
                            _replyToName = null;
                            _editingCommentId = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= COMMENT TILE =================
  Widget _commentTile(
      Map<String, dynamic> c,
      Map<String, dynamic>? profile,
      User? currentUser,
      ) {
    final isMyComment = c['user_id'] == currentUser?.id;

    void openProfile() {
      if (!isMyComment) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherProfileScreen(
              userId: c['user_id'], // ✅ always valid
            ),
          ),
        );
      }
    }

    return ListTile(
      leading: InkWell(
        onTap: openProfile,
        child: CircleAvatar(
          backgroundImage: profile?['avatar_url'] != null
              ? NetworkImage(profile!['avatar_url'])
              : null,
          child: profile?['avatar_url'] == null
              ? const Icon(Icons.person)
              : null,
        ),
      ),
      title: InkWell(
        onTap: openProfile,
        child: Text(
          profile?['name'] ?? 'User',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c['content']),
          Row(
            children: [
              // ❤️ COMMENT LIKE
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _commentService.streamCommentLikes(c['id']),
                builder: (_, snap) {
                  final likes = snap.data ?? [];
                  final isLiked =
                  likes.any((l) => l['user_id'] == currentUser?.id);

                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          isLiked
                              ? _commentService.unlikeComment(c['id'])
                              : _commentService.likeComment(c['id']);
                        },
                      ),
                      if (likes.isNotEmpty)
                        Text(likes.length.toString()),
                    ],
                  );
                },
              ),

              // 💬 REPLY
              TextButton(
                onPressed: () {
                  setState(() {
                    _replyToCommentId = c['id'];
                    _replyToName = profile?['name'];
                    _editingCommentId = null;
                    _controller.clear();
                  });
                },
                child: const Text("Reply"),
              ),

              // ✏️ EDIT / 🗑 DELETE
              if (isMyComment)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      setState(() {
                        _editingCommentId = c['id'];
                        _controller.text = c['content'];
                        _replyToCommentId = null;
                        _replyToName = null;
                      });
                    } else if (value == 'delete') {
                      _commentService.deleteComment(c['id']);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text("Edit")),
                    PopupMenuItem(value: 'delete', child: Text("Delete")),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

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

  final Set<String> _expandedComments = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _commentService.streamComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allComments = snapshot.data!;

                // ✅ FIX: typed parent_id check
                final parentComments = allComments
                    .where((c) => (c['parent_id'] as String?) == null)
                    .toList();

                final Map<String, List<Map<String, dynamic>>> repliesMap = {};

                // ✅ FIX: typed parent_id check
                for (final c in allComments
                    .where((c) => (c['parent_id'] as String?) != null)) {
                  final parentId = c['parent_id'] as String;
                  repliesMap.putIfAbsent(parentId, () => []).add(c);
                }

                return ListView.builder(
                  itemCount: parentComments.length,
                  itemBuilder: (_, index) {
                    final parent = parentComments[index];
                    final replies = repliesMap[parent['id']] ?? [];

                    final bool isExpanded =
                    _expandedComments.contains(parent['id']);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _commentTile(
                          comment: parent,
                          isReply: false,
                          currentUser: currentUser,
                        ),

                        if (replies.isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets.only(left: 64, bottom: 4),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedComments.remove(parent['id']);
                                  } else {
                                    _expandedComments.add(parent['id']);
                                  }
                                });
                              },
                              child: Text(
                                isExpanded
                                    ? 'Hide replies'
                                    : 'View ${replies.length} replies',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                        if (isExpanded)
                          ...replies.map(
                                (reply) => _commentTile(
                              comment: reply,
                              isReply: true,
                              currentUser: currentUser,
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                if (_replyToName != null || _editingCommentId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(
                          _editingCommentId != null
                              ? "Editing comment"
                              : "Replying to $_replyToName",
                          style: const TextStyle(fontSize: 13),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
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
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: "Add a comment...",
                            border: InputBorder.none,
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

  Widget _commentTile({
    required Map<String, dynamic> comment,
    required bool isReply,
    required User? currentUser,
  }) {
    // ✅ FIX: typed user_type
    final String? userType = comment['user_type'] as String?;
    final bool isBusiness = userType == 'agency';

    // ✅ FIX: typed profile sources
    final Map<String, dynamic>? profile = isBusiness
        ? comment['author'] as Map<String, dynamic>?
        : comment['profiles'] as Map<String, dynamic>?;

    final bool isMyComment = comment['user_id'] == currentUser?.id;

    final String? avatarUrl = isBusiness
        ? profile?['logo_url']
        : profile?['avatar_url'];

    void openProfile() {
      if (!isMyComment) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherProfileScreen(userId: comment['user_id']),
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isReply ? 48 : 8,
        6,
        8,
        6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: openProfile,
            child: CircleAvatar(
              radius: isReply ? 14 : 18,
              backgroundImage:
              avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: isBusiness
                            ? (profile?['agency_name'] ?? 'Business')
                            : (profile?['name'] ?? 'User'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(text: comment['content']),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream:
                      _commentService.streamCommentLikes(comment['id']),
                      builder: (_, snap) {
                        final likes = snap.data ?? [];
                        final isLiked = likes.any(
                              (l) => l['user_id'] == currentUser?.id,
                        );

                        return Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                isLiked
                                    ? _commentService
                                    .unlikeComment(comment['id'])
                                    : _commentService
                                    .likeComment(comment['id']);
                              },
                              child: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 16,
                                color:
                                isLiked ? Colors.red : Colors.grey,
                              ),
                            ),
                            if (likes.isNotEmpty)
                              Padding(
                                padding:
                                const EdgeInsets.only(left: 4),
                                child: Text(
                                  likes.length.toString(),
                                  style:
                                  const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyToCommentId = comment['id'];
                          _replyToName = isBusiness
                              ? profile?['agency_name']
                              : profile?['name'];
                          _editingCommentId = null;
                          _controller.clear();
                        });
                      },
                      child: const Text(
                        "Reply",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    if (isMyComment)
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            setState(() {
                              _editingCommentId = comment['id'];
                              _controller.text = comment['content'];
                              _replyToCommentId = null;
                              _replyToName = null;
                            });
                          } else if (value == 'delete') {
                            _commentService
                                .deleteComment(comment['id']);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text("Edit"),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text("Delete"),
                          ),
                        ],
                      ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 👇 IMPORT YOUR SCREENS
import 'post_detail_screen.dart';
import 'other_profile_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: user == null
          ? const Center(child: Text("Not logged in"))
          : StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('notifications')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!
              .where((n) => n['user_id'] == user.id)
              .toList();

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              // ✅ SAFE sender id
              final senderId =
                  n['from_user_id'] ?? n['actor_id'];

              if (senderId == null) {
                return const SizedBox();
              }

              return FutureBuilder<Map<String, dynamic>>(
                future: supabase
                    .from('profiles')
                    .select()
                    .eq('id', senderId)
                    .single(),
                builder: (context, profileSnapshot) {
                  if (!profileSnapshot.hasData) {
                    return const SizedBox();
                  }

                  final profile = profileSnapshot.data!;
                  final username = profile['name'] ?? 'user';
                  final avatarUrl = profile['avatar_url'];

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: RichText(
                      text: TextSpan(
                        style:
                        DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: username,
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.bold),
                          ),
                          const TextSpan(text: " "),
                          TextSpan(
                            text: n['type'] == 'follow'
                                ? "followed you"
                                : n['type'] == 'like'
                                ? "liked your post"
                                : "commented on your post",
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ FOLLOW BACK BUTTON
                        if (n['type'] == 'follow')
                          FutureBuilder<bool>(
                            future: supabase
                                .from('follows')
                                .select('id')
                                .eq('follower_id', user.id)
                                .eq('following_id', senderId)
                                .maybeSingle()
                                .then((v) => v != null),
                            builder:
                                (context, followSnapshot) {
                              if (!followSnapshot.hasData ||
                                  followSnapshot.data ==
                                      true) {
                                return const SizedBox();
                              }

                              return TextButton(
                                onPressed: () async {
                                  await supabase
                                      .from('follows')
                                      .insert({
                                    'follower_id': user.id,
                                    'following_id': senderId,
                                  });

                                  await supabase
                                      .from('notifications')
                                      .update({
                                    'is_read': true
                                  })
                                      .eq('id', n['id']);
                                },
                                child: const Text(
                                    "Follow back"),
                              );
                            },
                          ),

                        if (n['is_read'] != true)
                          const Padding(
                            padding:
                            EdgeInsets.only(left: 6),
                            child: Icon(Icons.circle,
                                color: Colors.red,
                                size: 10),
                          ),
                      ],
                    ),
                    onTap: () async {
                      // mark as read
                      await supabase
                          .from('notifications')
                          .update({'is_read': true})
                          .eq('id', n['id']);

                      // ✅ SAFE NAVIGATION
                      if (n['type'] == 'follow') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OtherProfileScreen(
                                  userId: senderId,
                                ),
                          ),
                        );
                      } else if (n['post_id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PostDetailScreen(
                                  postId: n['post_id'],
                                ),
                          ),
                        );
                      }
                    },
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

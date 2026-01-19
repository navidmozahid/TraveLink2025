import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            return const Center(
              child: Text("No notifications yet"),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final n = notifications[index];

              return ListTile(
                leading: Icon(
                  n['type'] == 'like'
                      ? Icons.favorite
                      : n['type'] == 'comment'
                      ? Icons.comment
                      : Icons.person_add,
                  color: Colors.blue,
                ),
                title: Text(
                  n['type'] == 'follow'
                      ? "Someone followed you"
                      : n['type'] == 'like'
                      ? "Someone liked your post"
                      : "Someone commented on your post",
                ),
                trailing: n['is_read'] == true
                    ? null
                    : const Icon(Icons.circle,
                    color: Colors.red, size: 10),
                onTap: () async {
                  await supabase
                      .from('notifications')
                      .update({'is_read': true})
                      .eq('id', n['id']);
                },
              );
            },
          );
        },
      ),
    );
  }
}

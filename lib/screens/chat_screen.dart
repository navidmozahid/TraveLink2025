import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userName),
      ),
      body: const Center(
        child: Text(
          "Chat system coming soon 🚀",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

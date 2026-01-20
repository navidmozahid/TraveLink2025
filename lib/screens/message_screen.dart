import 'package:flutter/material.dart';

class MessageScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const MessageScreen({
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
          "Chat screen coming next 🚀",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

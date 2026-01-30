import 'package:flutter/material.dart';

class EmergencyHelpScreen extends StatelessWidget {
  const EmergencyHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Helps"),
      ),
      body: const Center(
        child: Text(
          "Emergency Helps (Coming Soon 🚨)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

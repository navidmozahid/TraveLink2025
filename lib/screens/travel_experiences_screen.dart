import 'package:flutter/material.dart';

class TravelExperiencesScreen extends StatelessWidget {
  const TravelExperiencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Experiences"),
      ),
      body: const Center(
        child: Text(
          "Travel Experiences (Coming Soon 🌍)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HotelsOffersScreen extends StatelessWidget {
  const HotelsOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hotels Offers"),
      ),
      body: const Center(
        child: Text(
          "Hotels Offers (Coming Soon 🚀)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

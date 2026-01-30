import 'package:flutter/material.dart';

class TravelAgenciesOffersScreen extends StatelessWidget {
  const TravelAgenciesOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Agencies Offers"),
      ),
      body: const Center(
        child: Text(
          "Travel Agencies Offers (Coming Soon ✈️)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

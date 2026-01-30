import 'package:flutter/material.dart';

class TicketAgenciesOffersScreen extends StatelessWidget {
  const TicketAgenciesOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ticket Agencies Offers"),
      ),
      body: const Center(
        child: Text(
          "Ticket Agencies Offers (Coming Soon 🎟️)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

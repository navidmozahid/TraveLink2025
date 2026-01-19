import 'package:flutter/material.dart';

class BookingScreen extends StatelessWidget {
  final String bookingType;

  const BookingScreen({super.key, required this.bookingType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${bookingType.toUpperCase()} Booking"),
        backgroundColor: const Color(0xFF023e8a),
      ),
      body: Center(
        child: Text(
          "Booking page for $bookingType",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

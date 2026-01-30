import 'package:flutter/material.dart';

class CarRentalsOffersScreen extends StatelessWidget {
  const CarRentalsOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Rentals Offers"),
      ),
      body: const Center(
        child: Text(
          "Car Rentals Offers (Coming Soon 🚗)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

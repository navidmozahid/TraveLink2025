import 'package:flutter/material.dart';
import 'agency_signup_screen.dart';

class BusinessLoginScreen extends StatelessWidget {
  const BusinessLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Account Login"),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo placeholder
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orangeAccent,
                child: Icon(
                  Icons.business_center,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Business Portal",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              // Business Email
              _buildInputField(
                hint: "Business Email",
                icon: Icons.email,
                obscure: false,
              ),
              const SizedBox(height: 15),

              // Business Password
              _buildInputField(
                hint: "Password",
                icon: Icons.lock,
                obscure: true,
              ),
              const SizedBox(height: 15),

              TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),

              const SizedBox(height: 20),

              // Login button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // TODO: Add business login backend
                },
                child: const Text(
                  "Login",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 25),
              const Text("or", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 25),

              // Signup button (goes to Agency Registration)
              OutlinedButton.icon(
                icon: const Icon(Icons.app_registration),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.orangeAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AgencySignupScreen(),
                    ),
                  );
                },
                label: const Text(
                  "Register Your Agency",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required IconData icon,
    required bool obscure,
  }) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[200],
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

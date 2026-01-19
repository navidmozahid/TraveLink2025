import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedCountry;

  final SupabaseService _supabaseService = SupabaseService();

  final List<String> _countries = [
    "Bangladesh",
    "India",
    "United States",
    "United Kingdom",
    "Canada",
    "Australia",
    "Germany",
    "France",
    "Japan",
  ];

  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Traveler Sign Up"),
        backgroundColor: const Color(0xFF0077b6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField(
                controller: _nameController,
                hint: "Full Name",
                icon: Icons.person,
                obscure: false,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 15),
              _buildInputField(
                controller: _emailController,
                hint: "Email Address",
                icon: Icons.email,
                obscure: false,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter your email";
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildInputField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock,
                obscure: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter a password";
                  }
                  if (value.length < 8) return "Password must be 8+ chars";
                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                    return "Must contain 1 uppercase & 1 number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildInputField(
                controller: _phoneController,
                hint: "Phone Number (+880123456789)",
                icon: Icons.phone,
                obscure: false,
                validator: (value) {
                  if (value == null || value.isEmpty) return "Enter phone";
                  if (!RegExp(r'^\+\d{7,15}$').hasMatch(value)) {
                    return "Enter valid number (+880...)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  prefixIcon: const Icon(Icons.public),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text("Select Country / Region"),
                value: _selectedCountry,
                onChanged: (value) => setState(() => _selectedCountry = value),
                validator: (value) =>
                value == null ? "Select your country" : null,
                items: _countries
                    .map((c) =>
                    DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _loading = true);

                  try {
                    await _supabaseService.signUpTraveler(
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      country: _selectedCountry!,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            "Signup successful. Please check your email."),
                      ),
                    );

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  } finally {
                    setState(() => _loading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077b6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Sign Up",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
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

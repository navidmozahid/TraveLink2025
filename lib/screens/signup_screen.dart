import 'package:flutter/material.dart';

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

  // Example country list
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
              // Full Name
              _buildInputField(
                controller: _nameController,
                hint: "Full Name",
                icon: Icons.person,
                obscure: false,
                validator: (value) =>
                value == null || value.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 15),

              // Email
              _buildInputField(
                controller: _emailController,
                hint: "Email Address",
                icon: Icons.email,
                obscure: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter your email";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Password
              _buildInputField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock,
                obscure: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter a password";
                  }
                  if (value.length < 8) {
                    return "Password must be at least 8 characters";
                  }
                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                    return "Must contain 1 uppercase & 1 number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Phone Number
              _buildInputField(
                controller: _phoneController,
                hint: "Phone Number (+880123456789)",
                icon: Icons.phone,
                obscure: false,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter your phone number";
                  }
                  if (!RegExp(r'^\+\d{7,15}$').hasMatch(value)) {
                    return "Enter with country code (e.g., +880...)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Country Dropdown
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
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value;
                  });
                },
                validator: (value) =>
                value == null ? "Select your country" : null,
                items: _countries
                    .map((country) =>
                    DropdownMenuItem(value: country, child: Text(country)))
                    .toList(),
              ),
              const SizedBox(height: 30),

              // Sign Up Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077b6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Call backend signup logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Form submitted successfully!"),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

import 'package:flutter/material.dart';

class AgencySignupScreen extends StatefulWidget {
  const AgencySignupScreen({super.key});

  @override
  State<AgencySignupScreen> createState() => _AgencySignupScreenState();
}

class _AgencySignupScreenState extends State<AgencySignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _agencyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();

  String? _agencyType;
  List<String> _uploadedDocs = [];

  final List<String> _agencyTypes = [
    "Tour Operator",
    "Hotel Partner",
    "Transport",
    "Mixed",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agency Registration"),
        backgroundColor: const Color(0xFF023e8a),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildInputField(
                controller: _agencyNameController,
                hint: "Agency / Company Name",
                icon: Icons.business,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                controller: _emailController,
                hint: "Official Business Email",
                icon: Icons.email,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                controller: _passwordController,
                hint: "Password",
                icon: Icons.lock,
                obscure: true,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                controller: _phoneController,
                hint: "Business Phone Number",
                icon: Icons.phone,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                controller: _addressController,
                hint: "Business Address",
                icon: Icons.location_city,
              ),
              const SizedBox(height: 15),

              _buildInputField(
                controller: _licenseController,
                hint: "Business Registration / License ID",
                icon: Icons.confirmation_number,
              ),
              const SizedBox(height: 15),

              // Agency Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text("Select Agency Type"),
                value: _agencyType,
                onChanged: (value) {
                  setState(() {
                    _agencyType = value;
                  });
                },
                items: _agencyTypes
                    .map((type) =>
                    DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
              ),
              const SizedBox(height: 15),

              // Upload Documents Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  // TODO: Implement file picker later
                  setState(() {
                    _uploadedDocs.add("Sample_Document.pdf");
                  });
                },
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Documents"),
              ),
              if (_uploadedDocs.isNotEmpty)
                Column(
                  children: _uploadedDocs
                      .map((doc) => ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(doc),
                  ))
                      .toList(),
                ),
              const SizedBox(height: 30),

              // Register Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF023e8a),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Hook backend later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Agency registered successfully!"),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Register Agency",
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
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
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

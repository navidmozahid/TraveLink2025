import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_agency_service.dart';
import 'business_login_screen.dart';

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

  // ✅ store uploaded storage paths
  List<String> _uploadedDocs = [];

  bool _isLoading = false;
  bool _obscurePassword = true;

  // ✅ clean business types (NO MIXED)
  final List<String> _agencyTypes = [
    "Travel Agency",
    "Hotel",
    "Car Rental",
    "Ticket Seller",
    "Experiences",
  ];

  final SupabaseAgencyService _agencyService = SupabaseAgencyService();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _docsBucket = "business-docs";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agency Registration"),
        backgroundColor: const Color(0xFF023e8a),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header
                  const SizedBox(height: 10),
                  const Text(
                    "Create Your Agency Account",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF023e8a),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    controller: _agencyNameController,
                    hint: "Agency / Company Name",
                    icon: Icons.business,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter agency name';
                      }
                      if (value.length < 2) {
                        return 'Agency name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildInputField(
                    controller: _emailController,
                    hint: "Business Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Password with toggle visibility
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: Icon(Icons.lock, color: Colors.grey[600]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF023e8a),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Colors.red, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  _buildInputField(
                    controller: _phoneController,
                    hint: "Phone Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      if (value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildInputField(
                    controller: _addressController,
                    hint: "Business Address",
                    icon: Icons.location_city,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      if (value.length < 10) {
                        return 'Please enter a complete address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildInputField(
                    controller: _licenseController,
                    hint: "Business Registration / License ID",
                    icon: Icons.confirmation_number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter license ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),

                  // Agency Type Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF023e8a),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Colors.red, width: 1),
                      ),
                    ),
                    hint: const Text("Select Agency Type"),
                    value: _agencyType,
                    validator: (value) {
                      if (value == null) {
                        return 'Please select agency type';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {
                        _agencyType = value;
                      });
                    },
                    items: _agencyTypes
                        .map(
                          (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // Upload Documents Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Upload Documents",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF023e8a),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Upload your business registration, license, and other relevant documents.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),

                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black87,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _uploadDocument,
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Upload Documents"),
                          ),

                          if (_uploadedDocs.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              "Uploaded Documents (${_uploadedDocs.length})",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._uploadedDocs.asMap().entries.map(
                                  (entry) => Card(
                                margin:
                                const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.insert_drive_file,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    entry.value,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                      setState(() {
                                        _uploadedDocs.removeAt(entry.key);
                                      });
                                      _showToast("Document removed");
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF023e8a),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _registerAgency,
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                          : const Text(
                        "Register Agency",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Login redirect
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const BusinessLoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Login here",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF023e8a),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF023e8a)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _registerAgency() async {
    if (!_formKey.currentState!.validate()) {
      _showToast("Please fix the errors above", isError: true);
      return;
    }

    if (_agencyType == null) {
      _showToast("Please select agency type", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _agencyService.signUpAgency(
        email: _emailController.text,
        password: _passwordController.text,
        agencyName: _agencyNameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        licenseId: _licenseController.text,
        agencyType: _agencyType!,
        documents: _uploadedDocs,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // ✅ Navigate to Agency Login Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BusinessLoginScreen()),
      );

      // ✅ Show message on login screen (like traveler signup flow)
      Future.delayed(const Duration(milliseconds: 300), () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please wait a minute and check your email for verification.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showToast("❌ ${e.toString()}", isError: true);
    }
  }

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result == null) {
        return;
      }

      final file = result.files.single;

      final Uint8List? bytes = file.bytes;
      final String originalName = file.name ?? "";

      if (bytes == null) {
        _showToast("❌ Failed to read file. Try again.", isError: true);
        return;
      }

      if (originalName.trim().isEmpty) {
        _showToast("❌ Invalid file selected.", isError: true);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final String extension = originalName.contains('.')
          ? originalName.split('.').last.toLowerCase()
          : "";

      final safeName = originalName.replaceAll(' ', '_');

      final String path =
          "agency_docs/${DateTime.now().millisecondsSinceEpoch}_$safeName";

      await _supabase.storage.from(_docsBucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: _getMimeType(extension),
        ),
      );

      setState(() {
        _uploadedDocs.add(path);
        _isLoading = false;
      });

      _showToast("✅ Document uploaded", isSuccess: true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showToast("❌ Upload failed: $e", isError: true);
    }
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  void _showToast(String message,
      {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor = const Color(0xFF023e8a);
    if (isError) backgroundColor = Colors.red;
    if (isSuccess) backgroundColor = Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF023e8a), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _agencyNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
}

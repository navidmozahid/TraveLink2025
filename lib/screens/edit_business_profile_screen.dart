import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_agency_service.dart';

class EditBusinessProfileScreen extends StatefulWidget {
  final Map<String, dynamic> business;

  const EditBusinessProfileScreen({
    super.key,
    required this.business,
  });

  @override
  State<EditBusinessProfileScreen> createState() =>
      _EditBusinessProfileScreenState();
}

class _EditBusinessProfileScreenState
    extends State<EditBusinessProfileScreen> {
  final SupabaseAgencyService _service = SupabaseAgencyService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _description;
  late TextEditingController _city;
  late TextEditingController _country;
  late TextEditingController _phone;
  late TextEditingController _email;
  late TextEditingController _address;

  bool _saving = false;
  bool _uploadingImage = false;

  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.business['logo_url'];

    _description =
        TextEditingController(text: widget.business['description'] ?? '');
    _city = TextEditingController(text: widget.business['city'] ?? '');
    _country = TextEditingController(text: widget.business['country'] ?? '');
    _phone = TextEditingController(text: widget.business['phone'] ?? '');
    _email = TextEditingController(text: widget.business['email'] ?? '');
    _address = TextEditingController(text: widget.business['address'] ?? '');
  }

  // ---------------- PROFILE IMAGE PICK ----------------
  Future<void> _pickAndUploadLogo() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _uploadingImage = true);

    await _service.uploadBusinessLogo(File(file.path));

    final updated =
    await _service.getBusinessProfileById(widget.business['id']);

    if (!mounted) return;

    setState(() {
      _logoUrl = updated?['logo_url'];
      _uploadingImage = false;
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await _service.updateBusinessProfile(
        description: _description.text.trim(),
        city: _city.text.trim(),
        country: _country.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update business profile')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Business Profile"),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              "Save",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= PROFILE IMAGE =================
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage:
                    _logoUrl != null && _logoUrl!.isNotEmpty
                        ? NetworkImage(_logoUrl!)
                        : null,
                    child: _logoUrl == null
                        ? const Icon(Icons.business, size: 36)
                        : null,
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _uploadingImage ? null : _pickAndUploadLogo,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: _uploadingImage
                            ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _field("Description", _description, maxLines: 3),
            _field("City", _city),
            _field("Country", _country),
            _field(
              "Phone",
              _phone,
              keyboardType: TextInputType.phone,
            ),
            _field(
              "Email",
              _email,
              keyboardType: TextInputType.emailAddress,
            ),
            _field("Address", _address, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ).copyWith(labelText: label),
      ),
    );
  }
}

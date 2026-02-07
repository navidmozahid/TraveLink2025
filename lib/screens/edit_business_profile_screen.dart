import 'package:flutter/material.dart';
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

  late TextEditingController _description;
  late TextEditingController _city;
  late TextEditingController _country;
  late TextEditingController _phone;
  late TextEditingController _email;
  late TextEditingController _address;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _description =
        TextEditingController(text: widget.business['description'] ?? '');
    _city = TextEditingController(text: widget.business['city'] ?? '');
    _country = TextEditingController(text: widget.business['country'] ?? '');
    _phone = TextEditingController(text: widget.business['phone'] ?? '');
    _email = TextEditingController(text: widget.business['email'] ?? '');
    _address = TextEditingController(text: widget.business['address'] ?? '');
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

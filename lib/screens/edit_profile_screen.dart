import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _homeCountryController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _interestsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadProfile() async {
    final profile = await _supabaseService.getMyProfile();

    if (profile != null) {
      _nameController.text = profile['name'] ?? '';
      _usernameController.text = profile['username'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _websiteController.text = profile['website'] ?? '';
      _locationController.text = profile['location'] ?? '';
      _homeCountryController.text = profile['home_country'] ?? '';

      if (profile['date_of_birth'] != null) {
        _dobController.text = profile['date_of_birth'];
      }

      if (profile['interests'] != null) {
        _interestsController.text =
            (profile['interests'] as List).join(', ');
      }

      _avatarUrl = profile['avatar_url'];
    }

    setState(() => _loading = false);
  }

  // ---------------- PICK & UPLOAD AVATAR ----------------
  Future<void> _changeAvatar() async {
    try {
      setState(() => _saving = true);

      final url = await _supabaseService.uploadAvatarFromGallery();

      if (url != null) {
        setState(() => _avatarUrl = url);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  // ---------------- SAVE PROFILE ----------------
  Future<void> _saveProfile() async {
    try {
      setState(() => _saving = true);

      await _supabaseService.updateProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        website: _websiteController.text.trim(),
        location: _locationController.text.trim(),
        homeCountry: _homeCountryController.text.trim(),
        dateOfBirth:
        _dobController.text.isEmpty ? null : _dobController.text.trim(),
        interests: _interestsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: const Text(
              "Save",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------- AVATAR ----------
            GestureDetector(
              onTap: _saving ? null : _changeAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _avatarUrl != null
                        ? NetworkImage(_avatarUrl!)
                        : null,
                    child: _avatarUrl == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black,
                    child:
                    Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildField(_nameController, "Name"),
            _buildField(_usernameController, "Nick name (@username)"),
            _buildField(_bioController, "Bio", maxLines: 3),
            _buildField(_websiteController, "Website / Social link"),
            _buildField(_locationController, "Location"),
            _buildField(_homeCountryController, "Home country / City"),
            _buildField(
              _dobController,
              "Date of Birth (YYYY-MM-DD)",
              keyboard: TextInputType.datetime,
            ),
            _buildField(
              _interestsController,
              "Travel Interests (comma separated)",
            ),

            const SizedBox(height: 24),

            if (_saving) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

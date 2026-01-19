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
  final TextEditingController _bioController = TextEditingController();

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
      _bioController.text = profile['bio'] ?? '';
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
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // refresh profile screen
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
                    child: Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------- NAME ----------
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ---------- BIO ----------
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            if (_saving) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

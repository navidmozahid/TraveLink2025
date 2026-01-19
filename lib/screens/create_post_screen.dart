import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _posting = false;

  Map<String, dynamic>? _profile;

  bool get _canPost =>
      _image != null && _captionController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    setState(() => _profile = data);
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> _pickImage() async {
    final picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  // ---------------- CREATE POST ----------------
  Future<void> _createPost() async {
    if (!_canPost) return;

    setState(() => _posting = true);

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1️⃣ Upload image to EXISTING bucket
      final fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('post-images') // ✅ MUST EXIST
          .upload(fileName, _image!);

      final imageUrl = supabase.storage
          .from('post-images')
          .getPublicUrl(fileName);

      // 2️⃣ Insert post row
      await supabase.from('posts').insert({
        'user_id': user.id,
        'caption': _captionController.text.trim(),
        'location': _locationController.text.trim(),
        'media_url': imageUrl,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name =
    (_profile?['name'] as String?)?.isNotEmpty == true
        ? _profile!['name']
        : 'User';

    final String? avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _canPost && !_posting ? _createPost : null,
            child: _posting
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              'POST',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USER INFO
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child:
                  avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CAPTION
            TextField(
              controller: _captionController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _image == null
                    ? const Center(
                  child: Icon(Icons.photo_library, size: 40),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // LOCATION
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined),
                hintText: 'Add location',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

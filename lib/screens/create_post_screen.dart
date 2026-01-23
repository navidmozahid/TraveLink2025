import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PostService _postService = PostService();

  List<File> _mediaFiles = [];
  bool _posting = false;

  Map<String, dynamic>? _profile;

  bool get _canPost => _mediaFiles.isNotEmpty && !_posting;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    setState(() => _profile = data);
  }

  // ---------------- PICK FROM GALLERY (MULTI) ----------------
  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultipleMedia();
    if (picked.isEmpty) return;

    setState(() {
      _mediaFiles.addAll(picked.map((e) => File(e.path)));
    });
  }

  // ---------------- PICK FROM CAMERA (SINGLE IMAGE) ----------------
  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _mediaFiles.add(File(picked.path));
      });
    }
  }

  // ---------------- CREATE POST ----------------
  Future<void> _createPost() async {
    if (!_canPost) return;

    setState(() => _posting = true);

    try {
      await _postService.createPostWithMultipleMedia(
        mediaFiles: _mediaFiles,
        caption: _captionController.text.trim(),
        location: _locationController.text.trim(),
      );

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  bool _isVideo(File file) {
    final ext = file.path.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.mkv');
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?['name'] ?? 'User';
    final avatarUrl = _profile?['avatar_url'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _canPost ? _createPost : null,
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
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 16),

            // CAPTION
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(
                hintText: "Write a caption (optional)",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 16),

            // MEDIA PREVIEW (UPDATED ✅ REMOVE BUTTON)
            SizedBox(
              height: 200,
              child: _mediaFiles.isEmpty
                  ? const Center(child: Text("No media selected"))
                  : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaFiles.length,
                itemBuilder: (_, i) {
                  final file = _mediaFiles[i];
                  final isVideo = _isVideo(file);

                  return Padding(
                    padding: const EdgeInsets.all(6),
                    child: Stack(
                      children: [
                        Container(
                          width: 160,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isVideo
                              ? const Icon(
                            Icons.videocam,
                            size: 50,
                            color: Colors.black54,
                          )
                              : ClipRRect(
                            borderRadius:
                            BorderRadius.circular(12),
                            child: Image.file(
                              file,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // ▶ Video icon
                        if (isVideo)
                          const Positioned.fill(
                            child: Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),

                        // ❌ REMOVE BUTTON
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _mediaFiles.removeAt(i);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

            const SizedBox(height: 16),

            // PICK BUTTONS
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

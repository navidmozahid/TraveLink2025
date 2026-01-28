import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/post_service.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final String? initialCaption;   // kept (UNTUOUCHED)
  final String? initialLocation;  // kept (UNTUOUCHED)

  const EditPostScreen({
    super.key,
    required this.postId,
    this.initialCaption,
    this.initialLocation,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final PostService _postService = PostService();

  bool _saving = false;
  bool _loadingPost = true;

  // MEDIA STATE
  List<Map<String, dynamic>> _existingMedia = [];
  List<Map<String, dynamic>> _removedMedia = [];
  List<File> _newMediaFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPostAndMedia(); // 🔥 FIX
  }

  // ---------------- LOAD POST + MEDIA (FIX) ----------------
  Future<void> _loadPostAndMedia() async {
    final supabase = Supabase.instance.client;

    // 🔥 FETCH POST FRESH
    final post = await supabase
        .from('posts')
        .select('caption, location')
        .eq('id', widget.postId)
        .maybeSingle();

    if (post != null) {
      _captionController.text = post['caption'] ?? '';
      _locationController.text = post['location'] ?? '';
    }

    // LOAD MEDIA (OLD LOGIC — UNTOUCHED)
    final media = await _postService.fetchPostMedia(widget.postId);

    if (!mounted) return;
    setState(() {
      _existingMedia = media;
      _loadingPost = false;
    });
  }

  // ---------------- PICK MEDIA ----------------
  Future<void> _pickMedia() async {
    final picked = await _picker.pickMultipleMedia();
    if (picked.isEmpty) return;

    setState(() {
      _newMediaFiles.addAll(picked.map((e) => File(e.path)));
    });
  }

  bool _isVideo(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp4') ||
        p.endsWith('.mov') ||
        p.endsWith('.avi') ||
        p.endsWith('.mkv');
  }

  // ---------------- SAVE POST ----------------
  Future<void> _save() async {
    if (_saving) return;

    final String caption = _captionController.text.trim();
    final String location = _locationController.text.trim();

    setState(() => _saving = true);

    try {
      await _postService.updatePostWithMedia(
        postId: widget.postId,
        caption: caption,
        location: location,
        removedMedia: _removedMedia,
        newMediaFiles: _newMediaFiles,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update post')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPost) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Post"),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text(
              "SAVE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- MEDIA ----------
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._existingMedia.map((m) {
                    return _mediaTile(
                      child: m['media_type'] == 'video'
                          ? const Icon(Icons.videocam,
                          size: 40, color: Colors.white)
                          : Image.network(m['media_url'], fit: BoxFit.cover),
                      onRemove: () {
                        setState(() {
                          _existingMedia.remove(m);
                          _removedMedia.add(m);
                        });
                      },
                    );
                  }),
                  ..._newMediaFiles.map((f) {
                    return _mediaTile(
                      child: _isVideo(f.path)
                          ? const Icon(Icons.videocam,
                          size: 40, color: Colors.white)
                          : Image.file(f, fit: BoxFit.cover),
                      onRemove: () {
                        setState(() => _newMediaFiles.remove(f));
                      },
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.add),
              label: const Text("Add media"),
            ),

            const SizedBox(height: 20),

            // ---------- CAPTION ----------
            TextField(
              controller: _captionController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Edit caption",
                border: InputBorder.none,
              ),
            ),

            const SizedBox(height: 16),

            // ---------- LOCATION ----------
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Edit location",
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

  // ---------------- MEDIA TILE ----------------
  Widget _mediaTile({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            width: 140,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: child,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black,
                child:
                Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

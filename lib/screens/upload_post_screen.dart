import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_service.dart';

class UploadPostScreen extends StatefulWidget {
  const UploadPostScreen({super.key});

  @override
  State<UploadPostScreen> createState() => _UploadPostScreenState();
}

class _UploadPostScreenState extends State<UploadPostScreen> {
  final picker = ImagePicker();
  final captionCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  File? mediaFile;
  bool loading = false;

  Future pickMedia() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => mediaFile = File(picked.path));
    }
  }

  Future uploadPost() async {
    if (mediaFile == null) return;

    setState(() => loading = true);

    final service = PostService();
    final mediaUrl = await service.uploadMedia(mediaFile!);

    await service.createPost(
      mediaUrl: mediaUrl,
      caption: captionCtrl.text,
      location: locationCtrl.text,
    );

    setState(() => loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Post")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickMedia,
              child: Container(
                height: 200,
                color: Colors.grey[300],
                child: mediaFile == null
                    ? const Icon(Icons.add_a_photo, size: 40)
                    : Image.file(mediaFile!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            TextField(controller: captionCtrl, decoration: const InputDecoration(labelText: "Caption")),
            TextField(controller: locationCtrl, decoration: const InputDecoration(labelText: "Location")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : uploadPost,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Post"),
            )
          ],
        ),
      ),
    );
  }
}

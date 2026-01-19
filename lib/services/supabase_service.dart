import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  // Supabase client
  final SupabaseClient client = Supabase.instance.client;

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // ======================================================
  // AUTH
  // ======================================================

  /// TRAVELER SIGN UP
  /// - Creates auth user
  /// - Sends name & country as metadata
  /// - Ensures profile row exists (upsert safety)
  Future<void> signUpTraveler({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String country,
  }) async {
    // 1️⃣ Sign up user with metadata
    final AuthResponse response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'country': country,
        'phone': phone,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Signup failed: user is null');
    }

    // 2️⃣ Safety net: ensure profile exists (upsert)
    await client.from('profiles').upsert({
      'id': user.id,
      'email': email,
      'name': name,
      'country': country,
      'phone': phone,
      'bio': '',
      'avatar_url': null,
    });
  }

  /// LOGIN
  Future<AuthResponse> loginTraveler({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// LOGOUT
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// CURRENT USER
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  // ======================================================
  // PROFILE
  // ======================================================

  /// GET CURRENT PROFILE
  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    return await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  /// UPDATE PROFILE (TEXT DATA)
  Future<void> updateProfile({
    String? name,
    String? bio,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final updates = <String, dynamic>{};

    if (name != null && name.isNotEmpty) {
      updates['name'] = name;
    }
    if (bio != null) {
      updates['bio'] = bio;
    }

    if (updates.isNotEmpty) {
      await client.from('profiles').update(updates).eq('id', user.id);
    }
  }

  // ======================================================
  // AVATAR IMAGE UPLOAD
  // ======================================================

  /// PICK IMAGE FROM GALLERY + UPLOAD TO STORAGE
  /// - Uploads image
  /// - Saves public URL to profile
  Future<String?> uploadAvatarFromGallery() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // 1️⃣ Pick image
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return null;

    final file = File(image.path);
    final fileExt = image.path.split('.').last;
    final fileName = '${user.id}_${_uuid.v4()}.$fileExt';
    final filePath = 'avatars/$fileName';

    // 2️⃣ Upload to Supabase Storage
    await client.storage.from('avatars').upload(
      filePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    // 3️⃣ Get public URL
    final avatarUrl =
    client.storage.from('avatars').getPublicUrl(filePath);

    // 4️⃣ Save URL to profile
    await client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', user.id);

    return avatarUrl;
  }

  // ======================================================
  // PASSWORD
  // ======================================================

  /// RESET PASSWORD
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }
}

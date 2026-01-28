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
  Future<void> signUpTraveler({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String country,
  }) async {
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

  /// UPDATE PROFILE (EXTENDED – SAFE)
  Future<void> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? website,
    String? location,
    String? homeCountry,
    String? dateOfBirth,
    List<String>? interests,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final updates = <String, dynamic>{};

    if (name != null && name.isNotEmpty) {
      updates['name'] = name;
    }

    if (username != null && username.isNotEmpty) {
      updates['username'] = username;
    }

    if (bio != null) {
      updates['bio'] = bio;
    }

    if (website != null && website.isNotEmpty) {
      updates['website'] = website;
    }

    if (location != null && location.isNotEmpty) {
      updates['location'] = location;
    }

    if (homeCountry != null && homeCountry.isNotEmpty) {
      updates['home_country'] = homeCountry;
    }

    if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
      updates['date_of_birth'] = dateOfBirth;
    }

    if (interests != null) {
      updates['interests'] = interests;
    }

    if (updates.isNotEmpty) {
      await client.from('profiles').update(updates).eq('id', user.id);
    }
  }

  // ======================================================
  // AVATAR IMAGE UPLOAD
  // ======================================================

  /// PICK IMAGE FROM GALLERY + UPLOAD TO STORAGE
  Future<String?> uploadAvatarFromGallery() async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return null;

    final file = File(image.path);
    final fileExt = image.path.split('.').last;
    final fileName = '${user.id}_${_uuid.v4()}.$fileExt';
    final filePath = 'avatars/$fileName';

    await client.storage.from('avatars').upload(
      filePath,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final avatarUrl =
    client.storage.from('avatars').getPublicUrl(filePath);

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

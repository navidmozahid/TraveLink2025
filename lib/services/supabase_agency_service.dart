import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAgencyService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> signUpAgency({
    required String email,
    required String password,
    required String agencyName,
    required String phone,
    required String address,
    required String licenseId,
    required String agencyType,
    required List<String> documents,
  }) async {
    try {
      final validAgencyTypes = [
        'Travel Agency',
        'Hotel',
        'Car Rental',
        'Ticket Seller',
        'Experiences',
      ];

      if (!validAgencyTypes.contains(agencyType)) {
        throw Exception('Invalid agency type');
      }

      // ✅ Only create Auth user
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'user_type': 'business',
          'agency_name': agencyName.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
          'license_id': licenseId.trim(),
          'agency_type': agencyType,
          'documents': documents,
        },
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception("User creation failed");
      }

      return {
        'success': true,
        'user': user,
        'message':
        'Registration successful! Please check your email for verification.',
      };
    } on AuthException catch (e) {
      throw Exception("Authentication error: ${e.message}");
    } catch (e) {
      throw Exception("Registration failed: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> loginAgency({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse authResponse = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception("Login failed");
      }

      final businessAccount = await supabase
          .from('business_accounts')
          .select()
          .eq('id', authResponse.user!.id)
          .single();

      final status = (businessAccount['status'] ?? 'pending') as String;

      if (status == 'rejected') {
        await supabase.auth.signOut();
        throw Exception('Account has been rejected. Please contact support.');
      }

      if (status == 'suspended') {
        await supabase.auth.signOut();
        throw Exception('Account suspended. Please contact support.');
      }

      return {
        'success': true,
        'user': authResponse.user,
        'businessAccount': businessAccount,
        'message': status == 'pending'
            ? 'Login successful! Your account is pending approval.'
            : 'Login successful!',
      };
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception(
            "Business account profile not found. Please signup again.");
      }
      throw Exception("Database error: ${e.message}");
    } on AuthException catch (e) {
      throw Exception("Login failed: ${e.message}");
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  Future<Map<String, dynamic>> getCurrentAgency() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final businessAccount = await supabase
        .from('business_accounts')
        .select()
        .eq('id', user.id)
        .single();

    return businessAccount;
  }

  // =========================================================
  // BUSINESS PROFILE
  // =========================================================

  Future<Map<String, dynamic>> getMyBusinessProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    return await supabase
        .from('business_accounts')
        .select()
        .eq('id', user.id)
        .single();
  }

  Future<Map<String, dynamic>> getBusinessProfileById(String businessId) async {
    return await supabase
        .from('business_accounts')
        .select()
        .eq('id', businessId)
        .single();
  }

  Future<void> updateBusinessProfile({
    String? description,
    String? city,
    String? country,
    String? phone,
    String? email,
    String? address,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final updates = <String, dynamic>{};

    if (description != null) updates['description'] = description;
    if (city != null) updates['city'] = city;
    if (country != null) updates['country'] = country;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (address != null) updates['address'] = address;

    if (updates.isEmpty) return;

    await supabase
        .from('business_accounts')
        .update(updates)
        .eq('id', user.id);
  }

  /// ✅ Upload business LOGO (WORKING FIX)
  Future<String> uploadBusinessLogo(File file) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final path = 'logos/${user.id}.jpg';

    await supabase.storage
        .from('business-media')
        .upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final url =
    supabase.storage.from('business-media').getPublicUrl(path);

    await supabase
        .from('business_accounts')
        .update({'logo_url': url})
        .eq('id', user.id);

    return url;
  }

  Future<String> uploadBusinessCover(File file) async {
    throw Exception(
        'Cover image is not supported for business accounts.');
  }
}

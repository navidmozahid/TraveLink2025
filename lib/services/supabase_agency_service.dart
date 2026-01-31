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

      // ✅ Signup user (store business info inside user metadata)
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

      if (authResponse.user == null) {
        throw Exception("User creation failed");
      }

      // ✅ IMPORTANT:
      // We do NOT insert into business_accounts here anymore.
      // Because email confirmation ON + RLS blocks insert.
      // Trigger will auto insert.

      return {
        'success': true,
        'user': authResponse.user,
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
}

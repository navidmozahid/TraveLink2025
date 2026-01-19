// services/supabase_agency_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAgencyService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Agency Signup
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
      // Validate agency type
      final validAgencyTypes = ['Tour Operator', 'Hotel Partner', 'Transport', 'Mixed'];
      if (!validAgencyTypes.contains(agencyType)) {
        throw Exception('Invalid agency type');
      }

      // Create auth user
      final AuthResponse authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'user_type': 'agency',
        },
      );

      if (authResponse.user != null) {
        // Insert into business_accounts table
        final response = await supabase
            .from('business_accounts')
            .insert({
          'id': authResponse.user!.id,
          'agency_name': agencyName,
          'email': email,
          'phone': phone,
          'address': address,
          'license_id': licenseId,
          'agency_type': agencyType,
          'documents': documents,
          'status': 'pending',
          'user_type': 'agency',
        })
            .select()
            .single();

        return {
          'success': true,
          'user': authResponse.user,
          'businessAccount': response,
          'message': 'Registration successful! Please check your email for verification.',
        };
      } else {
        throw Exception('User creation failed');
      }
    } on PostgrestException catch (e) {
      // Handle specific Supabase errors
      if (e.code == '23505') { // Unique violation
        if (e.message.contains('email')) {
          throw Exception('Email already registered. Please use a different email or login.');
        } else if (e.message.contains('license_id')) {
          throw Exception('License ID already registered. Please check your license number.');
        }
      }
      throw Exception('Registration failed: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('Authentication error: ${e.message}');
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Agency Login
  Future<Map<String, dynamic>> loginAgency({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse authResponse = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Get business account details
        final businessAccount = await supabase
            .from('business_accounts')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        // Check account status
        final status = businessAccount['status'] as String;
        switch (status) {
          case 'rejected':
            await supabase.auth.signOut();
            throw Exception('Account has been rejected. Please contact support for more information.');
          case 'suspended':
            await supabase.auth.signOut();
            throw Exception('Account suspended. Please contact support to reactivate your account.');
          case 'pending':
          // Allow login but show pending message
            break;
          case 'approved':
          // Everything is good
            break;
          default:
            throw Exception('Unknown account status');
        }

        return {
          'success': true,
          'user': authResponse.user,
          'businessAccount': businessAccount,
          'message': status == 'pending'
              ? 'Login successful! Your account is pending approval.'
              : 'Login successful!',
        };
      } else {
        throw Exception('Login failed - no user returned');
      }
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') { // No rows returned
        throw Exception('No agency account found for this user. Please contact support.');
      }
      throw Exception('Database error: ${e.message}');
    } on AuthException catch (e) {
      switch (e.message) {
        case 'Invalid login credentials':
          throw Exception('Invalid email or password. Please try again.');
        case 'Email not confirmed':
          throw Exception('Please verify your email before logging in.');
        case 'Too many requests':
          throw Exception('Too many login attempts. Please try again later.');
        default:
          throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Get current agency profile
  Future<Map<String, dynamic>> getCurrentAgency() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final businessAccount = await supabase
          .from('business_accounts')
          .select()
          .eq('id', user.id)
          .single();

      return businessAccount;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('No agency profile found. Please contact support.');
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Update agency profile (only allowed when status is pending)
  Future<void> updateAgencyProfile(Map<String, dynamic> updates) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Check if agency can update (only when pending)
      final currentAccount = await supabase
          .from('business_accounts')
          .select('status')
          .eq('id', user.id)
          .single();

      if (currentAccount['status'] != 'pending') {
        throw Exception('Cannot update profile after approval. Contact support for changes.');
      }

      // Remove fields that shouldn't be updated
      updates.remove('id');
      updates.remove('email');
      updates.remove('status');
      updates.remove('user_type');
      updates.remove('created_at');
      updates.remove('updated_at');

      await supabase
          .from('business_accounts')
          .update(updates)
          .eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    try {
      final businessAccount = await getCurrentAgency();
      return businessAccount['user_type'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Check if user is logged in and has an agency account
  Future<bool> isAgencyLoggedIn() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await getCurrentAgency();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'yourapp://reset-password', // Update with your app's redirect URL
      );
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }
}
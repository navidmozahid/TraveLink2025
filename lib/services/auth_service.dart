import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> checkExistingSession() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return {'isLoggedIn': false};
      }

      // Check if it's a business user using your existing service
      final businessAccount = await _supabase
          .from('business_accounts')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (businessAccount != null) {
        return {
          'isLoggedIn': true,
          'userType': 'business',
          'user': user,
          'businessAccount': businessAccount,
        };
      } else {
        // It's a traveler user
        return {
          'isLoggedIn': true,
          'userType': 'traveler',
          'user': user,
        };
      }
    } catch (e) {
      return {'isLoggedIn': false};
    }
  }
}
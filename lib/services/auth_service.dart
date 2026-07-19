import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Signs in a user with email and password.
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Registers a new user with metadata (first_name, surname, rank).
  Future<AuthResponse> signUp(String email, String password, {required String firstName, required String surname, required String rank}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'surname': surname,
        'rank': rank,
      },
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Returns the currently logged in Supabase user.
  User? get currentUser => _client.auth.currentUser;

  /// Stream of authentication state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

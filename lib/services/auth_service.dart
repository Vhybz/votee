import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // UI-ONLY MOCK AUTH - ACCEPTS ANY CREDENTIALS

  Future<AuthResponse> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Accept any credentials for testing
    return AuthResponse(
      session: Session(
        accessToken: 'mock-token',
        tokenType: 'bearer',
        user: User(
          id: 'mock-admin-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: email,
        ),
      ),
      user: User(
        id: 'mock-admin-id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: email,
      ),
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    throw Exception('Sign up disabled in UI-only mode');
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  User? get currentUser => null;

  Stream<AuthState> get authStateChanges => const Stream.empty();
}

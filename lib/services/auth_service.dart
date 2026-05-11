// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Get auth state changes stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
      try {
        await _client.auth.signOut();
      } catch (e) {
        rethrow;
      }
    }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
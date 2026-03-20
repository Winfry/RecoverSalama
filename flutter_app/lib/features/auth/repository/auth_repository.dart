import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Sign up with phone number
  Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      phone: phone,
      password: password,
      data: {'full_name': fullName},
    );
  }

  /// Sign in with phone number
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  /// Verify OTP
  Future<AuthResponse> verifyOTP({
    required String phone,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Check if user is logged in
  bool get isLoggedIn => _client.auth.currentUser != null;
}

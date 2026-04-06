import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Convert a Kenyan phone number to a deterministic fake email.
  /// Users only ever see/enter their phone number — the email is internal only.
  String _phoneToEmail(String phone) {
    // Normalise: strip spaces, leading 0, ensure +254 prefix
    final digits = phone.replaceAll(RegExp(r'\s+'), '');
    final normalised = digits.startsWith('+')
        ? digits.replaceAll('+', '')
        : digits.startsWith('0')
            ? '254${digits.substring(1)}'
            : '254$digits';
    return '$normalised@salamarecover.app';
  }

  /// Sign up with phone number (email auth under the hood)
  Future<AuthResponse> signUpWithPhone({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: _phoneToEmail(phone),
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
  }

  /// Sign in with phone number (email auth under the hood)
  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: _phoneToEmail(phone),
      password: password,
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

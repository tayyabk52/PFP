import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

/// Auth operations and input validators.
///
/// Static validators are pure functions — no Supabase dependency — fully unit-testable.
/// Instance methods call Supabase and should be tested via integration tests.
class AuthRepository {
  // ---------------------------------------------------------------------------
  // Validators (pure, static)
  // ---------------------------------------------------------------------------

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name must be 50 characters or fewer';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Phone is optional. If provided, must match +923XXXXXXXXX (Pakistani mobile).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final phoneRegex = RegExp(r'^\+923[0-9]{9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter phone as +923XXXXXXXXX (e.g. +923001234567)';
    }
    return null;
  }

  /// Converts 03XXXXXXXXX → +923XXXXXXXXX. Returns null for empty input.
  static String? normalizePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final v = value.trim();
    if (v.startsWith('0') && v.length == 11) {
      return '+92${v.substring(1)}';
    }
    return v;
  }

  // ---------------------------------------------------------------------------
  // Supabase auth calls
  // ---------------------------------------------------------------------------

  /// Step 1 of register: creates auth.users record, triggers OTP email.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
  }

  /// Step 2 of register: verifies OTP and establishes a session.
  /// Uses OtpType.email (NOT OtpType.signup — deprecated and server-rejected in v2).
  Future<void> verifySignUpOtp({
    required String email,
    required String token,
  }) async {
    await supabase.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

  /// Resends the signup confirmation OTP.
  /// Uses auth.resend() — calling signUp() again would throw "User already registered".
  Future<void> resendSignUpOtp({required String email}) async {
    await supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  /// Login with email + password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  /// Creates or updates the profiles row after OTP verification.
  /// Uses upsert so it is safe to call even if a DB trigger already created the row.
  Future<void> upsertProfile({
    required String userId,
    required String displayName,
    required String email,
    String? phone,
  }) async {
    await supabase.from('profiles').upsert({
      'id': userId,
      'display_name': displayName.trim(),
      'email_address': email.trim(),
      if (phone != null) 'phone_number': phone,
    });
  }

  /// Called after role selection for members: marks profile setup complete.
  Future<void> completeProfileSetup(String userId) async {
    await supabase
        .from('profiles')
        .update({'profile_setup_complete': true})
        .eq('id', userId);
  }
}

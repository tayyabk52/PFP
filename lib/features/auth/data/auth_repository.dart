import 'dart:typed_data';

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
  Future<void> verifySignUpOtp({
    required String email,
    required String token,
  }) async {
    await supabase.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.signup,
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

  /// Updates the profiles row after OTP verification.
  /// The DB trigger always creates the row at signup (SECURITY DEFINER), so
  /// we use update() — not upsert() — to avoid the INSERT RLS check.
  Future<void> upsertProfile({
    required String userId,
    required String displayName,
    required String email,
    String? phone,
    String? city,
  }) async {
    await supabase.from('profiles').update({
      'display_name': displayName.trim(),
      'email_address': email.trim(),
      if (phone != null) 'phone_number': phone,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
    }).eq('id', userId);
  }

  /// Called after role selection for members: marks profile setup complete.
  Future<void> completeProfileSetup(String userId) async {
    await supabase
        .from('profiles')
        .update({'profile_setup_complete': true})
        .eq('id', userId);
  }

  // ---------------------------------------------------------------------------
  // Password change
  // ---------------------------------------------------------------------------

  /// Validates a new password value (min 8 chars).
  static String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'New password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Updates the current user's password via Supabase Auth.
  ///
  /// If "Secure password change" is enabled in the Supabase dashboard and the
  /// session is older than 24 hours, this will throw an [AuthException] with
  /// message containing "reauthentication".  In that case the caller should
  /// use [reauthenticate] + [updatePasswordWithNonce] instead.
  Future<void> updatePassword({required String newPassword}) async {
    final error = validateNewPassword(newPassword);
    if (error != null) throw Exception(error);

    await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sends a reauthentication OTP to the user's email.
  /// Required when "Secure password change" is enabled and session > 24h.
  Future<void> reauthenticate() async {
    await supabase.auth.reauthenticate();
  }

  /// Updates password using the reauthentication nonce/OTP.
  Future<void> updatePasswordWithNonce({
    required String newPassword,
    required String nonce,
  }) async {
    final error = validateNewPassword(newPassword);
    if (error != null) throw Exception(error);

    await supabase.auth.updateUser(
      UserAttributes(password: newPassword, nonce: nonce),
    );
  }

  // ---------------------------------------------------------------------------
  // Password reset (forgot password — user is NOT logged in)
  // ---------------------------------------------------------------------------

  /// Sends a password recovery OTP email.
  Future<void> sendPasswordResetOtp({required String email}) async {
    await supabase.auth.resetPasswordForEmail(email.trim());
  }

  /// Verifies the recovery OTP and establishes a session.
  /// After this succeeds, call [updatePassword] to set the new password.
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    await supabase.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
  }

  // ---------------------------------------------------------------------------
  // Avatar upload
  // ---------------------------------------------------------------------------

  /// Uploads avatar bytes to the `avatars` storage bucket and updates the
  /// profile row with the resulting public URL.
  ///
  /// NOTE: The Supabase project must have an `avatars` bucket. If uploads fail
  /// with a "bucket not found" error, create the bucket in the Supabase
  /// dashboard (Storage → New bucket → name: "avatars", public: true).
  Future<String> uploadAvatar({
    required String userId,
    required List<int> bytes,
  }) async {
    final path = '$userId/avatar.jpg';

    await supabase.storage.from('avatars').uploadBinary(
          path,
          bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);

    await supabase
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    return publicUrl;
  }
}

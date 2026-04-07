import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import 'auth_provider.dart';

/// Full profile row for the current user.
final currentProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return response;
});

/// Whether the current user has completed profile setup (role selection).
final profileSetupCompleteProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return true; // unauthenticated — don't trigger setup redirect

  final response = await supabase
      .from('profiles')
      .select('profile_setup_complete')
      .eq('id', user.id)
      .maybeSingle();

  return response?['profile_setup_complete'] as bool? ?? false;
});

/// The current user's most relevant seller application (Approved first, then most recent).
final sellerApplicationProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final approved = await supabase
      .from('seller_applications')
      .select()
      .eq('applicant_id', user.id)
      .eq('status', 'Approved')
      .maybeSingle();
  if (approved != null) return approved;

  return await supabase
      .from('seller_applications')
      .select()
      .eq('applicant_id', user.id)
      .order('submitted_at', ascending: false)
      .limit(1)
      .maybeSingle();
});

/// Application status string: 'Pending', 'Approved', 'Rejected', or null.
final sellerApplicationStatusProvider = Provider<String?>((ref) {
  return ref.watch(sellerApplicationProvider).valueOrNull?['status'] as String?;
});

/// Whether the current user has a pending/active seller application.
final hasSellerApplicationProvider = Provider<bool>((ref) {
  return ref.watch(sellerApplicationStatusProvider) != null;
});

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

/// Whether the current user has a pending/active seller application.
final hasSellerApplicationProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;

  final response = await supabase
      .from('seller_applications')
      .select('id')
      .eq('applicant_id', user.id)
      .maybeSingle();

  return response != null;
});

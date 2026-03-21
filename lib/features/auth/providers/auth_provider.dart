import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

/// Current Supabase auth session stream.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

/// Current user (null if unauthenticated).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

/// Current user role from profiles table.
/// Returns null if unauthenticated or profile not loaded.
final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await supabase
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

  return response['role'] as String?;
});

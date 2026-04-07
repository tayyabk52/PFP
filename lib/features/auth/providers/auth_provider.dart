import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

/// Current Supabase auth session stream.
///
/// `onAuthStateChange` is a broadcast stream — the `initialSession` event
/// fires during `Supabase.initialize()` (awaited in main) which is *before*
/// the Riverpod provider tree exists.  By the time this StreamProvider
/// subscribes, the event is already gone and the provider would stay in
/// `AsyncLoading` forever.
///
/// Fix: emit the current session synchronously first, then forward all
/// subsequent stream events.
final authStateProvider = StreamProvider<AuthState>((ref) async* {
  // Emit the already-restored session so the router can evaluate immediately.
  yield AuthState(
    AuthChangeEvent.initialSession,
    supabase.auth.currentSession,
  );

  // Forward every subsequent auth change (sign-in, sign-out, token refresh…).
  await for (final event in supabase.auth.onAuthStateChange) {
    yield event;
  }
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
      .maybeSingle();

  return response?['role'] as String?;
});

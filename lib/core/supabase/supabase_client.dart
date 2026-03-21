import 'package:supabase_flutter/supabase_flutter.dart';

/// Global Supabase client accessor.
/// Supabase.initialize() must be called in main() before use.
SupabaseClient get supabase => Supabase.instance.client;

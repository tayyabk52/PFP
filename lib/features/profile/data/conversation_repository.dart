import '../../../core/supabase/supabase_client.dart';

class ConversationRepository {
  /// Returns the conversation ID between the current user and [otherUserId].
  /// Creates a new conversation if one doesn't exist.
  /// Returns null if not authenticated.
  Future<String?> getOrCreateConversation(String otherUserId) async {
    try {
      final result = await supabase.rpc(
        'get_or_create_conversation',
        params: {'p_other_user_id': otherUserId},
      );
      return result as String?;
    } catch (_) {
      return null;
    }
  }
}

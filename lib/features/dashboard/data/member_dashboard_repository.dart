import '../../../core/supabase/supabase_client.dart';

/// Lightweight data class for a recent conversation preview.
class ConversationPreview {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessageBody;
  final DateTime lastMessageAt;
  final bool isUnread;

  const ConversationPreview({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessageBody,
    required this.lastMessageAt,
    required this.isUnread,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(lastMessageAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class MemberDashboardRepository {
  /// Fetch the 3 most recent conversations with last message preview.
  Future<List<ConversationPreview>> getRecentConversations(String userId) async {
    try {
      final convos = await supabase
          .from('conversations')
          .select('id, buyer_id, seller_id, last_message_at')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .not('last_message_at', 'is', null)
          .order('last_message_at', ascending: false)
          .limit(3);

      final list = <ConversationPreview>[];

      for (final c in (convos as List<dynamic>)) {
        final convoId = c['id'] as String;
        final buyerId = c['buyer_id'] as String;
        final sellerId = c['seller_id'] as String;
        final otherUserId = buyerId == userId ? sellerId : buyerId;

        // Fetch other user's profile
        final profile = await supabase
            .from('profiles')
            .select('display_name, avatar_url')
            .eq('id', otherUserId)
            .maybeSingle();

        // Fetch last message
        final msg = await supabase
            .from('messages')
            .select('body, sent_at, sender_id, read_at')
            .eq('conversation_id', convoId)
            .order('sent_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (msg == null) continue;

        final isUnread = msg['sender_id'] != userId && msg['read_at'] == null;

        list.add(ConversationPreview(
          conversationId: convoId,
          otherUserId: otherUserId,
          otherUserName: profile?['display_name'] as String? ?? 'PFC Member',
          otherUserAvatar: profile?['avatar_url'] as String?,
          lastMessageBody: msg['body'] as String? ?? '',
          lastMessageAt: DateTime.parse(msg['sent_at'] as String),
          isUnread: isUnread,
        ));
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  /// Count of ISO listings posted by this member.
  Future<int> getIsoCount(String userId) async {
    try {
      final result = await supabase
          .from('listings')
          .select('id')
          .eq('seller_id', userId)
          .eq('listing_type', 'ISO');
      return (result as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Count of reviews given by this member.
  Future<int> getReviewsGivenCount(String userId) async {
    try {
      final result = await supabase
          .from('reviews')
          .select('id')
          .eq('reviewer_id', userId);
      return (result as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Active ISO listings by this member.
  Future<List<Map<String, dynamic>>> getActiveIsos(String userId) async {
    try {
      final result = await supabase
          .from('listings')
          .select('id, fragrance_name, brand, created_at, status')
          .eq('seller_id', userId)
          .eq('listing_type', 'ISO')
          .neq('status', 'Deleted')
          .order('created_at', ascending: false)
          .limit(5);
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}

import '../../../core/supabase/supabase_client.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class ConversationItem {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;
  final bool isUnread;

  const ConversationItem({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    this.lastMessageBody,
    this.lastMessageAt,
    required this.isUnread,
  });

  String get timeAgo {
    if (lastMessageAt == null) return '';
    final diff = DateTime.now().difference(lastMessageAt!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime sentAt;
  final DateTime? readAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        conversationId: m['conversation_id'] as String,
        senderId: m['sender_id'] as String,
        body: m['body'] as String? ?? '',
        sentAt: DateTime.parse(m['sent_at'] as String),
        readAt: m['read_at'] != null
            ? DateTime.parse(m['read_at'] as String)
            : null,
      );
}

/// A listing reference attached to a conversation thread (FR-014/015).
class ConversationListingRef {
  final String listingId;
  final String listingSellerId;
  final String fragranceName;
  final String brand;
  final int pricePkr;
  final String salePostNumber;
  final String? photoUrl;
  final bool isAvailable; // false when sold / expired / deleted / removed

  const ConversationListingRef({
    required this.listingId,
    required this.listingSellerId,
    required this.fragranceName,
    required this.brand,
    required this.pricePkr,
    required this.salePostNumber,
    this.photoUrl,
    required this.isAvailable,
  });

  factory ConversationListingRef.fromMap(Map<String, dynamic> m) {
    final listing = m['listings'] as Map<String, dynamic>?;
    if (listing == null) {
      return ConversationListingRef(
        listingId: m['listing_id'] as String,
        listingSellerId: '',
        fragranceName: 'Unknown',
        brand: '',
        pricePkr: 0,
        salePostNumber: '',
        isAvailable: false,
      );
    }
    final status = listing['status'] as String? ?? 'deleted';
    final available = status == 'Published' || status == 'Draft';

    // Pick lowest display_order photo as thumbnail
    final photosRaw = listing['listing_photos'] as List<dynamic>? ?? [];
    String? photoUrl;
    if (photosRaw.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(
        photosRaw.map((p) => p as Map<String, dynamic>),
      )..sort((a, b) =>
          (a['display_order'] as int? ?? 0)
              .compareTo(b['display_order'] as int? ?? 0));
      photoUrl = sorted.first['file_url'] as String?;
    }

    return ConversationListingRef(
      listingId: m['listing_id'] as String,
      listingSellerId: listing['seller_id'] as String? ?? '',
      fragranceName: listing['fragrance_name'] as String? ?? 'Unknown',
      brand: listing['brand'] as String? ?? '',
      pricePkr: listing['price_pkr'] as int? ?? 0,
      salePostNumber: listing['sale_post_number'] as String? ?? '',
      photoUrl: photoUrl,
      isAvailable: available,
    );
  }
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class ConversationRepository {
  /// Returns the conversation ID between the current user and [otherUserId].
  /// Creates a new conversation if one doesn't exist (one per buyer-seller pair).
  /// Returns null if not authenticated or on error.
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

  /// Attaches [listingId] to [conversationId] as a listing reference (FR-003).
  /// Server enforces: caller=buyer, listing belongs to thread seller, max 10 refs.
  /// Silently ignores duplicates (FR-003 dedup rule).
  Future<void> addListingToConversation(
      String conversationId, String listingId) async {
    await supabase.rpc(
      'add_listing_to_conversation',
      params: {
        'p_conversation_id': conversationId,
        'p_listing_id': listingId,
      },
    );
  }

  /// Fetch listing references for a conversation, with live status from listings
  /// table (FR-014/015). Returns empty list on error.
  Future<List<ConversationListingRef>> getConversationListings(
      String conversationId) async {
    try {
      final data = await supabase
          .from('conversation_listings')
          .select(
            'listing_id, listings('
            'seller_id, fragrance_name, brand, price_pkr, sale_post_number, status, '
            'listing_photos(file_url, display_order)'
            ')',
          )
          .eq('conversation_id', conversationId)
          .order('added_at', ascending: true);

      return (data as List)
          .map((m) => ConversationListingRef.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch all active (non-deleted) conversations for [userId], most recent first.
  /// Filters out conversations where the user has set their deleted_at (FR-016).
  Future<List<ConversationItem>> getConversations(String userId) async {
    try {
      final convos = await supabase
          .from('conversations')
          .select(
            'id, buyer_id, seller_id, last_message_at, '
            'buyer_deleted_at, seller_deleted_at',
          )
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .not('last_message_at', 'is', null)
          .order('last_message_at', ascending: false);

      final list = <ConversationItem>[];

      for (final c in (convos as List<dynamic>)) {
        final buyerId = c['buyer_id'] as String;
        final sellerId = c['seller_id'] as String;
        final isBuyer = buyerId == userId;

        // FR-016: skip conversations the current user has soft-deleted
        final deletedAt = isBuyer
            ? c['buyer_deleted_at']
            : c['seller_deleted_at'];
        if (deletedAt != null) continue;

        final convoId = c['id'] as String;
        final otherUserId = isBuyer ? sellerId : buyerId;

        final profile = await supabase
            .from('profiles')
            .select('display_name, avatar_url')
            .eq('id', otherUserId)
            .maybeSingle();

        final msg = await supabase
            .from('messages')
            .select('body, sent_at, sender_id, read_at')
            .eq('conversation_id', convoId)
            .order('sent_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (msg == null) continue;

        final isUnread =
            msg['sender_id'] != userId && msg['read_at'] == null;

        list.add(ConversationItem(
          id: convoId,
          otherUserId: otherUserId,
          otherUserName:
              profile?['display_name'] as String? ?? 'PFC Member',
          otherUserAvatarUrl: profile?['avatar_url'] as String?,
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

  /// Fetch messages for a conversation, oldest first (newest at bottom).
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: true);
    return (data as List)
        .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Send a message in a conversation (max 1 000 chars per spec FR-010).
  Future<void> sendMessage(String conversationId, String body) async {
    final userId = supabase.auth.currentUser!.id;
    final trimmed = body.trim();
    await supabase.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'body': trimmed.length > 1000 ? trimmed.substring(0, 1000) : trimmed,
    });
  }

  /// Mark all unread messages in [conversationId] as read for [userId].
  Future<void> markMessagesRead(
      String conversationId, String userId) async {
    await supabase
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .isFilter('read_at', null);
  }

  /// Soft-delete a conversation from the current user's view (FR-016).
  /// Sets buyer_deleted_at or seller_deleted_at depending on the user's role.
  Future<void> deleteConversation(String conversationId) async {
    final userId = supabase.auth.currentUser!.id;

    final convo = await supabase
        .from('conversations')
        .select('buyer_id, seller_id')
        .eq('id', conversationId)
        .maybeSingle();
    if (convo == null) return;

    final isBuyer = convo['buyer_id'] == userId;
    final field = isBuyer ? 'buyer_deleted_at' : 'seller_deleted_at';

    await supabase
        .from('conversations')
        .update({field: DateTime.now().toIso8601String()})
        .eq('id', conversationId);
  }

  /// Returns listing_ids that have a confirmed sale in [conversationId].
  Future<Set<String>> getConfirmedSaleListingIds(String conversationId) async {
    try {
      final data = await supabase
          .from('sale_confirmations')
          .select('listing_id')
          .eq('conversation_id', conversationId);
      return (data as List)
          .map((m) => m['listing_id'] as String)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Confirms a sale for [listingId] in [conversationId] (seller only).
  /// Marks listing sold / decrements qty, bumps both parties' transaction_count,
  /// and posts a system message in the thread.
  Future<void> confirmSale(String conversationId, String listingId) async {
    await supabase.rpc('confirm_sale', params: {
      'p_conversation_id': conversationId,
      'p_listing_id': listingId,
    });
  }

  /// Returns true if the current user has already reviewed [listingId].
  Future<bool> hasUserReviewedListing(String listingId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final data = await supabase
          .from('reviews')
          .select('id')
          .eq('listing_id', listingId)
          .eq('reviewer_id', userId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  /// Submits (or updates) a review for a confirmed purchase.
  /// The DB enforces that caller was the buyer in a sale_confirmation.
  Future<void> submitReview({
    required String listingId,
    required String sellerId,
    required int rating,
    required String comment,
  }) async {
    await supabase.rpc('submit_review', params: {
      'p_listing_id': listingId,
      'p_seller_id': sellerId,
      'p_rating': rating,
      'p_comment': comment,
    });
  }

  /// Get conversation detail (other party's name/avatar) for [conversationId].
  Future<ConversationItem?> getConversationDetail(
      String conversationId) async {
    final userId = supabase.auth.currentUser!.id;
    final convo = await supabase
        .from('conversations')
        .select('id, buyer_id, seller_id')
        .eq('id', conversationId)
        .maybeSingle();
    if (convo == null) return null;

    final otherUserId = convo['buyer_id'] == userId
        ? convo['seller_id']
        : convo['buyer_id'];

    final profile = await supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', otherUserId as String)
        .maybeSingle();

    return ConversationItem(
      id: conversationId,
      otherUserId: otherUserId,
      otherUserName:
          profile?['display_name'] as String? ?? 'PFC Member',
      otherUserAvatarUrl: profile?['avatar_url'] as String?,
      lastMessageBody: null,
      lastMessageAt: null,
      isUnread: false,
    );
  }
}

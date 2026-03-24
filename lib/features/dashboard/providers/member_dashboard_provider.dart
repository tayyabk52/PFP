import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../marketplace/data/models/listing_model.dart';
import '../data/member_dashboard_repository.dart';

/// Aggregated stats for the member dashboard.
class MemberDashboardStats {
  final int conversationCount;
  final int unreadMessageCount;
  final int bidsPlacedCount;
  final int activeBidsCount;
  final int notificationsUnreadCount;
  final DateTime? memberSince;

  const MemberDashboardStats({
    this.conversationCount = 0,
    this.unreadMessageCount = 0,
    this.bidsPlacedCount = 0,
    this.activeBidsCount = 0,
    this.notificationsUnreadCount = 0,
    this.memberSince,
  });
}

/// Fetches aggregated member dashboard stats from Supabase.
final memberDashboardStatsProvider =
    FutureProvider<MemberDashboardStats>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const MemberDashboardStats();

  final uid = user.id;

  // Run all queries in parallel for speed
  final results = await Future.wait([
    // 0: conversation count (as buyer or seller)
    supabase
        .from('conversations')
        .select('id')
        .or('buyer_id.eq.$uid,seller_id.eq.$uid'),
    // 1: unread messages (messages in my conversations where I'm not the sender and read_at is null)
    supabase.rpc('get_unread_message_count', params: {'p_user_id': uid}).then(
      (v) => v,
      onError: (_) => 0,
    ),
    // 2: bids placed count
    supabase.from('bids').select('id').eq('bidder_id', uid),
    // 3: unread notifications
    supabase
        .from('auction_notifications')
        .select('id')
        .eq('recipient_id', uid)
        .isFilter('read_at', null),
    // 4: profile created_at
    supabase.from('profiles').select('created_at').eq('id', uid).single(),
  ]);

  final conversations = results[0] as List<dynamic>;
  // RPC may return int or fall back to 0
  int unreadCount = 0;
  if (results[1] is int) {
    unreadCount = results[1] as int;
  } else if (results[1] is List) {
    // Fallback: count unread from conversations manually
    unreadCount = 0;
  }
  final bids = results[2] as List<dynamic>;
  final notifications = results[3] as List<dynamic>;
  final profileData = results[4] as Map<String, dynamic>;

  return MemberDashboardStats(
    conversationCount: conversations.length,
    unreadMessageCount: unreadCount,
    bidsPlacedCount: bids.length,
    activeBidsCount: bids.length, // All bids for now
    notificationsUnreadCount: notifications.length,
    memberSince: profileData['created_at'] != null
        ? DateTime.tryParse(profileData['created_at'] as String)
        : null,
  );
});

/// Fetches the latest published marketplace listings for the member dashboard.
final featuredListingsProvider =
    FutureProvider<List<Listing>>((ref) async {
  final response = await supabase
      .from('listings')
      .select('''
        id,
        sale_post_number,
        seller_id,
        listing_type,
        fragrance_name,
        brand,
        size_ml,
        condition,
        price_pkr,
        delivery_details,
        status,
        created_at,
        published_at,
        auction_end_at,
        quantity_available,
        fragrance_family,
        fragrance_notes,
        condition_notes,
        listing_photos(id, file_url, display_order),
        profiles(id, display_name, avatar_url, city, role, transaction_count, pfc_seller_code)
      ''')
      .eq('status', 'Published')
      .neq('listing_type', 'ISO')
      .order('published_at', ascending: false)
      .limit(6);

  return (response as List<dynamic>)
      .map((m) => Listing.fromMap(m as Map<String, dynamic>))
      .toList();
});

/// Fetches unread message count via a simple query
/// (fallback since RPC may not exist yet).
final unreadMessagesCountProvider =
    FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  try {
    // Get all conversation IDs where user is a participant
    final convos = await supabase
        .from('conversations')
        .select('id')
        .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}');

    if ((convos as List).isEmpty) return 0;

    final convoIds = convos.map((c) => c['id'] as String).toList();

    // Count unread messages in those conversations (not sent by me)
    final messages = await supabase
        .from('messages')
        .select('id')
        .inFilter('conversation_id', convoIds)
        .neq('sender_id', user.id)
        .isFilter('read_at', null);

    return (messages as List).length;
  } catch (_) {
    return 0;
  }
});

final memberDashboardRepositoryProvider = Provider<MemberDashboardRepository>(
  (_) => MemberDashboardRepository(),
);

/// Recent conversations with last message preview.
final recentConversationsProvider =
    FutureProvider<List<ConversationPreview>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(memberDashboardRepositoryProvider).getRecentConversations(user.id);
});

/// ISO listings count for the current member.
final memberIsoCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(memberDashboardRepositoryProvider).getIsoCount(user.id);
});

/// Reviews given count for the current member.
final memberReviewsGivenProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.read(memberDashboardRepositoryProvider).getReviewsGivenCount(user.id);
});

/// Active ISO posts by the current member.
final memberActiveIsosProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.read(memberDashboardRepositoryProvider).getActiveIsos(user.id);
});

/// Marketplace stats: total published listings, total sellers, etc.
final marketplaceOverviewProvider =
    FutureProvider<Map<String, int>>((ref) async {
  try {
    final results = await Future.wait([
      supabase.from('listings').select('id').eq('status', 'Published'),
      supabase.from('profiles').select('id').eq('role', 'seller'),
    ]);

    final listings = results[0] as List<dynamic>;
    final sellers = results[1] as List<dynamic>;

    return {
      'totalListings': listings.length,
      'verifiedSellers': sellers.length,
    };
  } catch (_) {
    return {'totalListings': 0, 'verifiedSellers': 0};
  }
});

/// Real marketplace pulse data: trending family, weekly activity change, totals.
class MarketplacePulseData {
  final int totalActive;
  final int verifiedSellers;
  final int thisWeekListings;
  final int lastWeekListings;
  final String? trendingFamily;

  const MarketplacePulseData({
    required this.totalActive,
    required this.verifiedSellers,
    required this.thisWeekListings,
    required this.lastWeekListings,
    this.trendingFamily,
  });

  /// Week-over-week change string, e.g. "+24%", "-5%", "New"
  String get weeklyChangeLabel {
    if (lastWeekListings == 0 && thisWeekListings == 0) return '—';
    if (lastWeekListings == 0) return 'New';
    final pct = ((thisWeekListings - lastWeekListings) / lastWeekListings * 100)
        .round();
    return pct >= 0 ? '+$pct%' : '$pct%';
  }

  bool get isPositive => thisWeekListings >= lastWeekListings;
}

final marketplacePulseProvider =
    FutureProvider<MarketplacePulseData>((ref) async {
  try {
    final now = DateTime.now().toUtc().toIso8601String();
    final weekAgo = DateTime.now().toUtc()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    final twoWeeksAgo = DateTime.now().toUtc()
        .subtract(const Duration(days: 14))
        .toIso8601String();

    final results = await Future.wait([
      // 0: total active
      supabase.from('listings').select('id').eq('status', 'Published'),
      // 1: this week new listings
      supabase
          .from('listings')
          .select('id')
          .eq('status', 'Published')
          .gte('published_at', weekAgo)
          .lte('published_at', now),
      // 2: last week new listings
      supabase
          .from('listings')
          .select('id')
          .eq('status', 'Published')
          .gte('published_at', twoWeeksAgo)
          .lt('published_at', weekAgo),
      // 3: top fragrance family
      supabase
          .from('listings')
          .select('fragrance_family')
          .eq('status', 'Published')
          .not('fragrance_family', 'is', null),
      // 4: verified sellers
      supabase.from('profiles').select('id').eq('role', 'seller'),
    ]);

    final totalActive = (results[0] as List).length;
    final thisWeek = (results[1] as List).length;
    final lastWeek = (results[2] as List).length;
    final sellers = (results[4] as List).length;

    // Compute top fragrance family client-side
    final families = (results[3] as List<dynamic>)
        .map((r) => (r as Map<String, dynamic>)['fragrance_family'] as String?)
        .where((f) => f != null && f.isNotEmpty)
        .cast<String>()
        .toList();

    String? topFamily;
    if (families.isNotEmpty) {
      final freq = <String, int>{};
      for (final f in families) {
        freq[f] = (freq[f] ?? 0) + 1;
      }
      topFamily = freq.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return MarketplacePulseData(
      totalActive: totalActive,
      verifiedSellers: sellers,
      thisWeekListings: thisWeek,
      lastWeekListings: lastWeek,
      trendingFamily: topFamily,
    );
  } catch (_) {
    return const MarketplacePulseData(
      totalActive: 0,
      verifiedSellers: 0,
      thisWeekListings: 0,
      lastWeekListings: 0,
    );
  }
});

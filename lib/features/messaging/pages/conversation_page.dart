import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/data/conversation_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _convRepoProvider = Provider<ConversationRepository>(
  (_) => ConversationRepository(),
);

final _conversationDetailProvider =
    FutureProvider.autoDispose.family<ConversationItem?, String>(
  (ref, conversationId) async {
    final repo = ref.read(_convRepoProvider);
    return repo.getConversationDetail(conversationId);
  },
);

final _listingRefsProvider =
    FutureProvider.autoDispose.family<List<ConversationListingRef>, String>(
  (ref, conversationId) async {
    final repo = ref.read(_convRepoProvider);
    return repo.getConversationListings(conversationId);
  },
);

final _confirmedSalesProvider =
    FutureProvider.autoDispose.family<Set<String>, String>(
  (ref, conversationId) async {
    final repo = ref.read(_convRepoProvider);
    return repo.getConfirmedSaleListingIds(conversationId);
  },
);

final _reviewedListingsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return {};
  try {
    final data = await supabase
        .from('reviews')
        .select('listing_id')
        .eq('reviewer_id', userId);
    return (data as List).map((m) => m['listing_id'] as String).toSet();
  } catch (_) {
    return {};
  }
});

// ---------------------------------------------------------------------------
// Conversation Page
// ---------------------------------------------------------------------------

class ConversationPage extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationPage({super.key, required this.conversationId});

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _deleting = false;

  late final StreamController<List<Map<String, dynamic>>> _msgStreamCtrl;
  late final RealtimeChannel _msgChannel;
  Stream<List<Map<String, dynamic>>> get _messageStream => _msgStreamCtrl.stream;

  @override
  void initState() {
    super.initState();
    _msgStreamCtrl = StreamController.broadcast();
    _fetchMessages();

    _msgChannel = supabase
        .channel('conv_${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (_) => _fetchMessages(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (_) => _fetchMessages(),
        )
        .subscribe();

    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _fetchMessages() async {
    if (_msgStreamCtrl.isClosed) return;
    try {
      final data = await supabase
          .from('messages')
          .select()
          .eq('conversation_id', widget.conversationId)
          .order('sent_at', ascending: true);
      if (!_msgStreamCtrl.isClosed) {
        _msgStreamCtrl.add(List<Map<String, dynamic>>.from(
          (data as List).map((m) => Map<String, dynamic>.from(m as Map)),
        ));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _msgStreamCtrl.close();
    supabase.removeChannel(_msgChannel);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    final repo = ref.read(_convRepoProvider);
    await repo.markMessagesRead(widget.conversationId, userId);
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final repo = ref.read(_convRepoProvider);
      await repo.sendMessage(widget.conversationId, text);
      _msgCtrl.clear();
      await _fetchMessages();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Delete conversation?',
          style: GoogleFonts.notoSerif(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onBackground,
          ),
        ),
        content: Text(
          'This removes the conversation from your inbox only. '
          'The other party\'s messages are unaffected.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final repo = ref.read(_convRepoProvider);
      await repo.deleteConversation(widget.conversationId);
      if (!mounted) return;
      context.go('/dashboard/messages');
    } catch (_) {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final detailAsync =
        ref.watch(_conversationDetailProvider(widget.conversationId));
    final listingRefsAsync =
        ref.watch(_listingRefsProvider(widget.conversationId));
    final confirmedSalesAsync =
        ref.watch(_confirmedSalesProvider(widget.conversationId));
    final reviewedAsync = ref.watch(_reviewedListingsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard/messages');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surfaceContainerLow,
        appBar: AppBar(
          backgroundColor:
              AppColors.surfaceContainerLow.withValues(alpha: 0.92),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard/messages');
              }
            },
          ),
          title: detailAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => Text(
              'Conversation',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
            data: (detail) => detail == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.otherUserName,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground,
                        ),
                      ),
                      Text(
                        'PFC Member',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            if (_deleting)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.textMuted,
                tooltip: 'Delete conversation',
                onPressed: _deleteConversation,
              ),
          ],
        ),
        body: Column(
          children: [
            // Listing refs panel (FR-014)
            listingRefsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (refs) {
                if (refs.isEmpty) return const SizedBox.shrink();
                final confirmedSales =
                    confirmedSalesAsync.valueOrNull ?? {};
                final reviewedListings =
                    reviewedAsync.valueOrNull ?? {};
                return _ListingRefsPanel(
                  refs: refs,
                  conversationId: widget.conversationId,
                  currentUserId: user?.id ?? '',
                  confirmedSaleIds: confirmedSales,
                  reviewedListingIds: reviewedListings,
                );
              },
            ),

            // Message list
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _messageStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Say hello!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollCtrl.hasClients) {
                      _scrollCtrl
                          .jumpTo(_scrollCtrl.position.maxScrollExtent);
                    }
                  });

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = ChatMessage.fromMap(
                          messages[i].cast<String, dynamic>());
                      final isMine = msg.senderId == user?.id;
                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                      );
                    },
                  );
                },
              ),
            ),

            // Input bar
            _InputBar(
              controller: _msgCtrl,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Listing refs panel (FR-014/015)
// ---------------------------------------------------------------------------

class _ListingRefsPanel extends StatelessWidget {
  final List<ConversationListingRef> refs;
  final String conversationId;
  final String currentUserId;
  final Set<String> confirmedSaleIds;
  final Set<String> reviewedListingIds;

  const _ListingRefsPanel({
    required this.refs,
    required this.conversationId,
    required this.currentUserId,
    required this.confirmedSaleIds,
    required this.reviewedListingIds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(
            color: AppColors.ghostBorderBase.withValues(alpha: 0.15),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined,
                  size: 11, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                refs.length == 1
                    ? 'LISTING IN THIS CONVERSATION'
                    : '${refs.length} LISTINGS IN THIS CONVERSATION',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: refs
                  .map((r) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _ListingRefCard(
                          listingRef: r,
                          conversationId: conversationId,
                          currentUserId: currentUserId,
                          isSaleConfirmed:
                              confirmedSaleIds.contains(r.listingId),
                          hasReviewed:
                              reviewedListingIds.contains(r.listingId),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingRefCard extends ConsumerStatefulWidget {
  final ConversationListingRef listingRef;
  final String conversationId;
  final String currentUserId;
  final bool isSaleConfirmed;
  final bool hasReviewed;

  const _ListingRefCard({
    required this.listingRef,
    required this.conversationId,
    required this.currentUserId,
    required this.isSaleConfirmed,
    required this.hasReviewed,
  });

  @override
  ConsumerState<_ListingRefCard> createState() => _ListingRefCardState();
}

class _ListingRefCardState extends ConsumerState<_ListingRefCard> {
  bool _confirming = false;

  Future<void> _confirmSale() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Confirm Sale?',
            style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w700, color: AppColors.onBackground)),
        content: Text(
          'This will mark ${widget.listingRef.fragranceName} as sold, '
          'update both your transaction counts, and unlock a review for the buyer.',
          style: GoogleFonts.inter(
              fontSize: 13, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
            child: const Text('Confirm Sale'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _confirming = true);
    try {
      final repo = ref.read(_convRepoProvider);
      await repo.confirmSale(widget.conversationId, widget.listingRef.listingId);
      if (!mounted) return;
      // Refresh providers
      ref.invalidate(_confirmedSalesProvider(widget.conversationId));
      ref.invalidate(_listingRefsProvider(widget.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _openReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => _ReviewSheet(
        listingRef: widget.listingRef,
        onSubmitted: () {
          ref.invalidate(_reviewedListingsProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lr = widget.listingRef; // 'lr' avoids shadowing ConsumerState.ref
    final isSeller = widget.currentUserId == lr.listingSellerId;

    if (!lr.isAvailable && !widget.isSaleConfirmed) {
      return Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        color: AppColors.surfaceContainerHighest,
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Listing no longer available',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        border: Border.all(
            color: AppColors.ghostBorderBase.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: photo + details + tap to view
          InkWell(
            onTap: lr.isAvailable
                ? () => context.push('/marketplace/${lr.listingId}')
                : null,
            mouseCursor: lr.isAvailable
                ? SystemMouseCursors.click
                : MouseCursor.defer,
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: lr.photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: lr.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ColoredBox(
                              color: AppColors.surfaceContainerHighest),
                          errorWidget: (_, __, ___) =>
                              const _PhotoPlaceholder(),
                        )
                      : const _PhotoPlaceholder(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: AppColors.surfaceContainerHighest,
                          child: Text(
                            '#${lr.salePostNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lr.fragranceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSerif(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          lr.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PKR ${NumberFormat('#,###').format(lr.pricePkr)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: widget.isSaleConfirmed
                                ? AppColors.textMuted
                                : AppColors.primary,
                            decoration: widget.isSaleConfirmed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.isSaleConfirmed)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.success),
                  )
                else if (lr.isAvailable)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.chevron_right,
                        size: 16, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),

          // Action row
          if (widget.isSaleConfirmed && !isSeller && !widget.hasReviewed)
            _ActionDivider(
              label: 'LEAVE A REVIEW',
              icon: Icons.star_outline_rounded,
              color: AppColors.goldAccent,
              onTap: _openReviewSheet,
            )
          else if (widget.isSaleConfirmed)
            _ActionDivider(
              label: isSeller
                  ? 'SALE CONFIRMED'
                  : widget.hasReviewed
                      ? 'REVIEW SUBMITTED'
                      : 'SALE CONFIRMED',
              icon: Icons.check_rounded,
              color: AppColors.success,
              onTap: null,
            )
          else if (isSeller && lr.isAvailable)
            _ActionDivider(
              label: _confirming ? 'CONFIRMING...' : 'CONFIRM SALE',
              icon: _confirming
                  ? Icons.hourglass_empty_rounded
                  : Icons.handshake_outlined,
              color: AppColors.primary,
              onTap: _confirming ? null : _confirmSale,
            ),
        ],
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionDivider({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border(
            top: BorderSide(color: color.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review bottom sheet
// ---------------------------------------------------------------------------

class _ReviewSheet extends ConsumerStatefulWidget {
  final ConversationListingRef listingRef;
  final VoidCallback onSubmitted;

  const _ReviewSheet({required this.listingRef, required this.onSubmitted});

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a star rating.')));
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please write a short comment.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = ref.read(_convRepoProvider);
      await repo.submitReview(
        listingId: widget.listingRef.listingId,
        sellerId: widget.listingRef.listingSellerId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );
      widget.onSubmitted();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to submit review: $e',
              style: GoogleFonts.inter()),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leave a Review',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              )),
          const SizedBox(height: 4),
          Text(
            widget.listingRef.fragranceName,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Star picker
          Text('Rating',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starIndex),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    starIndex <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 32,
                    color: starIndex <= _rating
                        ? AppColors.goldAccent
                        : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Comment field
          Text('Comment',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            style:
                GoogleFonts.inter(fontSize: 14, color: AppColors.onBackground),
            decoration: InputDecoration(
              hintText: 'Describe your experience with this seller...',
              hintStyle:
                  GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceContainerHighest,
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none),
              enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                    color: AppColors.ghostBorderBase.withValues(alpha: 0.2)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Submit Review',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 22,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceContainerHighest,
                child: Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.card,
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.body,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isMine
                          ? AppColors.onPrimary
                          : AppColors.onBackground,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeLabel(message.sentAt),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isMine
                              ? AppColors.onPrimary.withValues(alpha: 0.6)
                              : AppColors.textMuted,
                        ),
                      ),
                      // FR-009: read indicator for sender
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead
                              ? Icons.done_all
                              : Icons.done,
                          size: 12,
                          color: message.isRead
                              ? AppColors.onPrimary
                              : AppColors.onPrimary.withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input bar
// ---------------------------------------------------------------------------

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        8,
        8 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onBackground,
              ),
              minLines: 1,
              maxLines: 4,
              maxLength: 1000, // FR-010: 1 000 char cap
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                counterText: '', // hide character counter
                filled: true,
                fillColor: AppColors.surfaceContainerHighest,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(
                    color: AppColors.ghostBorderBase.withValues(alpha: 0.15),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: sending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 18,
                      color: AppColors.onPrimary,
                    ),
                    onPressed: onSend,
                  ),
          ),
        ],
      ),
    );
  }
}

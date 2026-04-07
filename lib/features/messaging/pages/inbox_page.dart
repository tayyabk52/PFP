import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/data/conversation_repository.dart';

// ---------------------------------------------------------------------------
// Real-time inbox provider (FR-013)
// Streams a fresh fetch whenever a message is inserted or updated in any
// conversation the user participates in.
// ---------------------------------------------------------------------------

final _convRepoProvider = Provider<ConversationRepository>(
  (_) => ConversationRepository(),
);

final inboxStreamProvider =
    StreamProvider.autoDispose<List<ConversationItem>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final repo = ref.read(_convRepoProvider);
  final controller = StreamController<List<ConversationItem>>();

  Future<void> fetch() async {
    if (controller.isClosed) return;
    final items = await repo.getConversations(user.id);
    if (!controller.isClosed) controller.add(items);
  }

  // Initial load
  fetch();

  // Subscribe to message changes for real-time unread updates (FR-013)
  final channel = supabase
      .channel('inbox_${user.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (_) => fetch(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        callback: (_) => fetch(),
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

// ---------------------------------------------------------------------------
// Inbox Page
// ---------------------------------------------------------------------------

class InboxPage extends ConsumerWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxStreamProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor:
                AppColors.surfaceContainerLow.withValues(alpha: 0.92),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'MESSAGES',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INBOX',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your Conversations',
                    style: GoogleFonts.notoSerif(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Content
          if (user == null)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Please log in to view messages.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            inboxAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Failed to load messages.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              data: (convos) {
                if (convos.isEmpty) {
                  return SliverFillRemaining(child: _EmptyInbox());
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ConversationRow(
                      convo: convos[i],
                      onTap: () => ctx
                          .push('/dashboard/messages/${convos[i].id}'),
                      onDelete: () async {
                        final repo = ref.read(_convRepoProvider);
                        await repo.deleteConversation(convos[i].id);
                        // Stream will auto-refresh via postgres_changes
                      },
                    ),
                    childCount: convos.length,
                  ),
                );
              },
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation row with swipe-to-delete (FR-016)
// ---------------------------------------------------------------------------

class _ConversationRow extends StatelessWidget {
  final ConversationItem convo;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  const _ConversationRow({
    required this.convo,
    required this.onTap,
    required this.onDelete,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(convo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              'Delete conversation?',
              style: GoogleFonts.notoSerif(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.onBackground,
              ),
            ),
            content: Text(
              'Removed from your inbox only. The other party\'s thread is unaffected.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style:
                        GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: GoogleFonts.inter(color: AppColors.error)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        hoverColor: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
        child: Container(
          color: AppColors.card,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              // Avatar with unread dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      _initials(convo.otherUserName),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (convo.isUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Name + preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      convo.otherUserName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: convo.isUnread
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: AppColors.onBackground,
                      ),
                    ),
                    if (convo.lastMessageBody != null &&
                        convo.lastMessageBody!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        convo.lastMessageBody!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: convo.isUnread
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                          fontWeight: convo.isUnread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Time
              Text(
                convo.timeAgo,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyInbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Message a seller from their profile or a listing to get started.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/marketplace'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
              child: Text(
                'Browse Marketplace',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

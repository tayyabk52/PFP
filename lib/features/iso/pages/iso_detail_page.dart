import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/profile_provider.dart';
import '../../marketplace/data/models/listing_model.dart';
import '../data/iso_model.dart';
import '../providers/iso_provider.dart';

class IsoDetailPage extends ConsumerStatefulWidget {
  const IsoDetailPage({super.key, required this.isoId});

  final String isoId;

  @override
  ConsumerState<IsoDetailPage> createState() => _IsoDetailPageState();
}

class _IsoDetailPageState extends ConsumerState<IsoDetailPage> {
  bool _notificationsMarked = false;

  @override
  Widget build(BuildContext context) {
    final isoAsync = ref.watch(isoDetailProvider(widget.isoId));

    // Mark notifications read once when ISO data arrives (owner only)
    ref.listen(isoDetailProvider(widget.isoId), (_, next) {
      next.whenData((iso) {
        if (iso == null) return;
        final currentUser = ref.read(currentUserProvider);
        if (!_notificationsMarked && currentUser != null && iso.sellerId == currentUser.id) {
          _notificationsMarked = true;
          ref.read(isoWriteRepositoryProvider).markNotificationsRead(currentUser.id);
        }
      });
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/iso');
          }
        }
      },
      child: isoAsync.when(
        loading: () => const Scaffold(
          backgroundColor: AppColors.surface,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (error, _) => Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load ISO',
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/iso'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Go Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.ghostBorderBase),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        data: (iso) {
          if (iso == null) {
            return Scaffold(
              backgroundColor: AppColors.surface,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_outlined,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'ISO not found',
                          style: GoogleFonts.notoSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This ISO request may have been removed.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.canPop() ? context.pop() : context.go('/iso'),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.ghostBorderBase),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final currentUser = ref.watch(currentUserProvider);
          final isOwner = currentUser != null && iso.sellerId == currentUser.id;

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: ClipRect(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.85),
                  ),
                  child: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.primary,
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go('/iso'),
                    ),
                    title: Text(
                      'ISO REQUEST',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    actions: [
                      if (isOwner)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          color: AppColors.primary,
                          onPressed: () =>
                              context.push('/dashboard/iso/${iso.id}/edit'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 1024;

                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 48 : 24,
                          32,
                          isDesktop ? 48 : 24,
                          80,
                        ),
                        child: isDesktop
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildIsoHeader(iso),
                                  ),
                                  const SizedBox(width: 48),
                                  Expanded(
                                    flex: 2,
                                    child: _buildOffersPanel(iso),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildIsoHeader(iso),
                                  _buildOffersPanel(iso),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1 — ISO Header
  // ---------------------------------------------------------------------------

  Widget _buildIsoHeader(IsoPost iso) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge
        _buildStatusBadge(iso.status),

        // Fulfilled banner
        if (iso.status == ListingStatus.sold) ...[
          const SizedBox(height: 8),
          Container(
            color: AppColors.surfaceContainerLow,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'This ISO has been fulfilled',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Fragrance name
        Text(
          iso.fragranceName,
          style: GoogleFonts.notoSerif(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            height: 1.1,
          ),
        ),

        // Brand
        Text(
          iso.brand,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 16),

        // Detail chips row — size + budget
        Row(
          children: [
            // Size chip
            Container(
              color: AppColors.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(
                '${iso.sizeMl % 1 == 0 ? iso.sizeMl.toInt() : iso.sizeMl} ML',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Budget chip
            if (iso.budgetPkr > 0)
              Container(
                color: AppColors.surfaceContainerLow,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'PKR ${iso.budgetPkr}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.surfaceContainerLow,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  'BUDGET: FLEXIBLE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Notes
        if (iso.notes != null && iso.notes!.isNotEmpty) ...[
          Text(
            iso.notes!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Posted-by row
        GestureDetector(
          onTap: () => context.push('/u/${iso.sellerId}'),
          child: _buildPostedByRow(iso),
        ),

        Divider(
          color: AppColors.ghostBorderBase.withValues(alpha: 0.15),
          height: 40,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(ListingStatus status) {
    final (label, color, bgColor) = switch (status) {
      ListingStatus.published => ('PUBLISHED', AppColors.success, AppColors.successContainer),
      ListingStatus.sold => ('FULFILLED', AppColors.textMuted, AppColors.surfaceContainerHighest),
      ListingStatus.draft => ('DRAFT', AppColors.warning, AppColors.warningContainer),
      _ => ('UNKNOWN', AppColors.textMuted, AppColors.surfaceContainerLow),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: bgColor,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildPostedByRow(IsoPost iso) {
    final poster = iso.poster;
    final name = poster?.displayNameOrFallback ?? 'PFC Member';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final timeAgo = _timeAgo(iso.createdAt);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.surfaceContainerLow,
          child: Text(
            initials,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
                ),
                if (poster != null && poster.isVerifiedSeller) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: AppColors.surfaceContainerHighest,
                    child: Text(
                      'SELLER',
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (poster?.city != null)
              Text(
                poster!.city!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const Spacer(),
        Text(
          timeAgo,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2 — Offers Panel
  // ---------------------------------------------------------------------------

  Widget _buildOffersPanel(IsoPost iso) {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final role = profileAsync.valueOrNull?['role'] as String? ?? '';
    final isOwner = currentUser != null && iso.sellerId == currentUser.id;
    final isSeller = role == 'seller' || role == 'admin';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OFFERS',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),

        // ISO is no longer accepting offers
        if (iso.status != ListingStatus.published) ...[
          Text(
            'This ISO is no longer accepting offers.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Owner can still see offers (read-only)
          if (isOwner) _buildOwnerOfferList(iso, readOnly: true),
        ] else if (isOwner) ...[
          _buildOwnerOfferList(iso, readOnly: false),
        ] else if (isSeller) ...[
          _buildSellerOfferSection(iso),
        ] else ...[
          Container(
            color: AppColors.surfaceContainerLow,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Only verified sellers can submit offers on ISO requests.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOwnerOfferList(IsoPost iso, {required bool readOnly}) {
    final offersAsync = ref.watch(isoOffersProvider(widget.isoId));

    return offersAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) =>
          Text(e.toString(), style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
      data: (offers) {
        if (offers.isEmpty) {
          return Text(
            'No offers yet.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _OfferCard(
              offer: offer,
              showActions: !readOnly && iso.status == ListingStatus.published,
              onAccept: !readOnly ? (id) => _acceptOffer(id) : null,
              onDecline: !readOnly ? (id) => _declineOffer(id) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildSellerOfferSection(IsoPost iso) {
    final myOfferAsync = ref.watch(myIsoOfferProvider(widget.isoId));

    return myOfferAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) =>
          Text(e.toString(), style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
      data: (myOffer) {
        if (myOffer != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OfferCard(offer: myOffer, showActions: false),
              if (myOffer.status == IsoOfferStatus.pending) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () async {
                      await ref.read(isoWriteRepositoryProvider).withdrawOffer(myOffer.id);
                      if (!mounted) return;
                      ref.invalidate(myIsoOfferProvider(widget.isoId));
                      ref.invalidate(isoOffersProvider(widget.isoId));
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      minimumSize: const Size(140, 44),
                    ),
                    child: Text(
                      'Withdraw Offer',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: _showOfferBottomSheet,
            child: Text(
              'Submit an Offer',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Accept / Decline handlers
  // ---------------------------------------------------------------------------

  Future<void> _acceptOffer(String offerId) async {
    await ref.read(isoWriteRepositoryProvider).acceptOffer(offerId, widget.isoId);
    if (!mounted) return;
    ref.invalidate(isoDetailProvider(widget.isoId));
    ref.invalidate(isoOffersProvider(widget.isoId));
  }

  Future<void> _declineOffer(String offerId) async {
    await ref.read(isoWriteRepositoryProvider).declineOffer(offerId);
    if (!mounted) return;
    ref.invalidate(isoOffersProvider(widget.isoId));
  }

  // ---------------------------------------------------------------------------
  // Offer bottom sheet
  // ---------------------------------------------------------------------------

  void _showOfferBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => _OfferBottomSheet(
        onSend: (message, amount) async {
          final user = ref.read(currentUserProvider);
          if (user == null) return;
          await ref.read(isoWriteRepositoryProvider).submitOffer(
                isoId: widget.isoId,
                sellerId: user.id,
                message: message,
                offerAmount: amount,
              );
          if (!mounted) return;
          ref.invalidate(isoOffersProvider(widget.isoId));
          ref.invalidate(myIsoOfferProvider(widget.isoId));
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) {
      return DateFormat('d MMM yyyy').format(dt);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

// ---------------------------------------------------------------------------
// _OfferBottomSheet — StatefulWidget that owns its TextEditingControllers
// ---------------------------------------------------------------------------

class _OfferBottomSheet extends StatefulWidget {
  final Future<void> Function(String? message, int? amount) onSend;

  const _OfferBottomSheet({required this.onSend});

  @override
  State<_OfferBottomSheet> createState() => _OfferBottomSheetState();
}

class _OfferBottomSheetState extends State<_OfferBottomSheet> {
  final _msgCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'SUBMIT AN OFFER',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let the member know you have what they're looking for.",
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _msgCtrl,
            decoration: const InputDecoration(
              hintText: 'Your message (optional)',
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amtCtrl,
            decoration: const InputDecoration(
              hintText: 'Your asking price in PKR (optional)',
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero),
              ),
              onPressed: _sending
                  ? null
                  : () async {
                      setState(() => _sending = true);
                      final message = _msgCtrl.text.trim().isEmpty
                          ? null
                          : _msgCtrl.text.trim();
                      final amount = int.tryParse(_amtCtrl.text.trim());
                      Navigator.of(context).pop();
                      await widget.onSend(message, amount);
                    },
              child: Text(
                'SEND OFFER',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OfferCard — private widget
// ---------------------------------------------------------------------------

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    this.onAccept,
    this.onDecline,
    this.showActions = false,
  });

  final IsoOffer offer;
  final void Function(String offerId)? onAccept;
  final void Function(String offerId)? onDecline;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final seller = offer.seller;
    final name = seller?.displayNameOrFallback ?? 'PFC Seller';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller info row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceContainerHighest,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: seller?.id != null
                    ? () => context.push('/u/${seller!.id}')
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                    ),
                    if (seller?.city != null)
                      Text(
                        seller!.city!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              _buildStatusBadge(offer.status),
            ],
          ),

          // Message
          if (offer.message != null) ...[
            const SizedBox(height: 10),
            Text(
              offer.message!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],

          // Offer amount
          if (offer.offerAmount != null) ...[
            const SizedBox(height: 6),
            Text(
              'Offered: PKR ${offer.offerAmount}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],

          // Action buttons (owner view only, ISO still published)
          if (showActions) ...[
            const SizedBox(height: 12),
            if (offer.status == IsoOfferStatus.pending)
              Row(
                children: [
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => onAccept?.call(offer.id),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.success,
                        minimumSize: const Size(80, 44),
                      ),
                      child: Text(
                        'Accept',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => onDecline?.call(offer.id),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        minimumSize: const Size(80, 44),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              )
            else if (offer.status == IsoOfferStatus.accepted)
              Text(
                '✓ Accepted',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              )
            else if (offer.status == IsoOfferStatus.declined)
              Text(
                'Declined',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IsoOfferStatus status) {
    final (label, color, bgColor) = switch (status) {
      IsoOfferStatus.pending => ('PENDING', AppColors.warning, AppColors.warningContainer),
      IsoOfferStatus.accepted => ('ACCEPTED', AppColors.success, AppColors.successContainer),
      IsoOfferStatus.declined => ('DECLINED', AppColors.textMuted, AppColors.surfaceContainerHighest),
      IsoOfferStatus.withdrawn => ('WITHDRAWN', AppColors.textMuted, AppColors.surfaceContainerHighest),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      color: bgColor,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../marketplace/data/models/listing_model.dart';
import '../data/iso_model.dart';
import '../providers/iso_provider.dart';

class MyIsoPostsPage extends ConsumerStatefulWidget {
  const MyIsoPostsPage({super.key});

  @override
  ConsumerState<MyIsoPostsPage> createState() => _MyIsoPostsPageState();
}

class _MyIsoPostsPageState extends ConsumerState<MyIsoPostsPage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/dashboard');
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text(
            'My ISO Posts',
            style: GoogleFonts.notoSerif(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton.icon(
                onPressed: () => context.push('/iso/create'),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'NEW',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/iso/create'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: const Icon(Icons.add_rounded),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final isosAsync = ref.watch(myIsoPostsProvider);

    return isosAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load ISO posts',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(myIsoPostsProvider),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      data: (isos) {
        final published = isos
            .where((i) => i.status == ListingStatus.published)
            .toList();
        final drafts = isos
            .where((i) => i.status == ListingStatus.draft)
            .toList();

        if (published.isEmpty && drafts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            if (published.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ...published.map((iso) => _MyIsoCard(iso: iso)),
            ],
            if (drafts.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'DRAFTS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ...drafts.map((iso) => _MyIsoCard(
                    iso: iso,
                    onPublish: (isoId) async {
                      await ref
                          .read(isoWriteRepositoryProvider)
                          .publishIso(isoId);
                      ref.invalidate(myIsoPostsProvider);
                    },
                  )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No ISO posts yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/iso/create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                'Post your first ISO',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MyIsoCard — private card widget
// ---------------------------------------------------------------------------

class _MyIsoCard extends StatelessWidget {
  const _MyIsoCard({required this.iso, this.onPublish});

  final IsoPost iso;
  final void Function(String isoId)? onPublish;

  @override
  Widget build(BuildContext context) {
    final sizeLabel =
        '${iso.sizeMl % 1 == 0 ? iso.sizeMl.toInt() : iso.sizeMl} ml';
    final budgetLabel =
        iso.budgetPkr > 0 ? 'PKR ${iso.budgetPkr}' : 'Flexible';
    final dateLabel = DateFormat('dd MMM yyyy').format(iso.createdAt);

    final isDraft = iso.status == ListingStatus.draft;

    return InkWell(
      onTap: () => context.push('/iso/${iso.id}'),
      child: Container(
        color: AppColors.surfaceContainerLow,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: fragrance name + status chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    iso.fragranceName,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip(iso.status),
              ],
            ),

            const SizedBox(height: 4),

            // Mid row: brand · size
            Text(
              '${iso.brand} · $sizeLabel',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 6),

            // Bottom row: budget + date
            Row(
              children: [
                Text(
                  budgetLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: iso.budgetPkr > 0
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Text(
                  dateLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            // Publish button for drafts
            if (isDraft && onPublish != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onPublish!(iso.id),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Publish',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ListingStatus status) {
    final (label, color, bgColor) = switch (status) {
      ListingStatus.published => ('ACTIVE', AppColors.success, AppColors.successContainer),
      ListingStatus.sold => ('FULFILLED', AppColors.textMuted, AppColors.surfaceContainerHighest),
      ListingStatus.draft => ('DRAFT', AppColors.warning, AppColors.warningContainer),
      _ => ('UNKNOWN', AppColors.textMuted, AppColors.surfaceContainerLow),
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

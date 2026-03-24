import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/iso_model.dart';
import '../providers/iso_provider.dart';

// ---------------------------------------------------------------------------
// Time-ago helper
// ---------------------------------------------------------------------------

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 0) return '${diff.inDays}d ago';
  if (diff.inHours > 0) return '${diff.inHours}h ago';
  return '${diff.inMinutes}m ago';
}

// ---------------------------------------------------------------------------
// ISO Card
// ---------------------------------------------------------------------------

class _IsoCard extends StatelessWidget {
  final IsoPost iso;

  const _IsoCard({required this.iso});

  @override
  Widget build(BuildContext context) {
    final isVerified = iso.poster?.isVerifiedSeller ?? false;

    return InkWell(
      onTap: () => context.push('/iso/${iso.id}'),
      child: Container(
        color: AppColors.surfaceContainerLow,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: fragrance name + budget chip ──────────────────────
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
                _buildBudgetChip(),
              ],
            ),
            const SizedBox(height: 4),
            // ── Middle row: brand + size ───────────────────────────────────
            Text(
              '${iso.brand} · ${_sizeLabel(iso.sizeMl)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            // ── Bottom row: poster + city + time ──────────────────────────
            Row(
              children: [
                Text(
                  iso.poster?.displayNameOrFallback ?? 'Anonymous',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                if (iso.poster?.city != null &&
                    iso.poster!.city!.isNotEmpty) ...[
                  Text(
                    ' · ${iso.poster!.city}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _timeAgo(iso.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            // ── Verified seller chip ──────────────────────────────────────
            if (isVerified) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Text(
                  'VERIFIED SELLER',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetChip() {
    if (iso.budgetPkr > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        color: AppColors.primary,
        child: Text(
          'PKR ${iso.budgetPkr}',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimary,
          ),
        ),
      );
    }
    return Text(
      'Flexible',
      style: GoogleFonts.inter(
        fontSize: 10,
        color: AppColors.textSecondary,
      ),
    );
  }

  String _sizeLabel(double ml) {
    if (ml == ml.roundToDouble()) {
      return '${ml.toInt()} ml';
    }
    return '$ml ml';
  }
}

// ---------------------------------------------------------------------------
// ISO Board Page
// ---------------------------------------------------------------------------

class IsoBoardPage extends ConsumerStatefulWidget {
  const IsoBoardPage({super.key});

  @override
  ConsumerState<IsoBoardPage> createState() => _IsoBoardPageState();
}

class _IsoBoardPageState extends ConsumerState<IsoBoardPage> {
  final _searchController = TextEditingController();
  String? _keyword;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(bool isAuthenticated) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No ISO requests found',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (isAuthenticated) ...[
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  onPressed: () => context.push('/iso/create'),
                  child: Text(
                    'Be the first to post',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isosAsync = ref.watch(isoBoardProvider(_keyword));

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () => context.push('/iso/create'),
              icon: const Icon(Icons.add),
              label: Text(
                'Post ISO Request',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar with search ────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            pinned: true,
            floating: false,
            title: Text(
              'ISO BOARD',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.5,
                color: AppColors.textSecondary,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onBackground,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search fragrance or brand...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_outlined,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    setState(() =>
                        _keyword = value.trim().isEmpty ? null : value.trim());
                  },
                ),
              ),
            ),
          ),

          // ── Header section ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SEEKING',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ISO Board',
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'What the community is looking for.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── ISO list / states ───────────────────────────────────────────
          isosAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Text(
                    'Failed to load',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            data: (isos) {
              if (isos.isEmpty) {
                return SliverToBoxAdapter(
                  child: _buildEmptyState(user != null),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _IsoCard(iso: isos[i]),
                  childCount: isos.length,
                ),
              );
            },
          ),

          // ── Bottom padding ───────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

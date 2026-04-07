import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/my_listings_provider.dart';
import 'widgets/my_listing_card.dart';

class MyListingsPage extends ConsumerStatefulWidget {
  const MyListingsPage({super.key});

  @override
  ConsumerState<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends ConsumerState<MyListingsPage> {
  int _selectedTab = 0;

  static const _tabs = ['All', 'Draft', 'Published', 'Sold', 'Expired'];

  void _onTabTapped(int index) {
    setState(() => _selectedTab = index);
    final tab = _tabs[index];
    ref.read(myListingsStatusFilterProvider.notifier).state =
        tab == 'All' ? null : tab;
  }

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
          'My Listings',
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
              onPressed: () => context.go('/dashboard/create-listing'),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: _buildTabBar(),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/dashboard/create-listing'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: const Icon(Icons.add),
      ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isSelected = _selectedTab == i;
            return GestureDetector(
              onTap: () => _onTabTapped(i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final listingsAsync = ref.watch(myListingsProvider);

    return listingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load listings',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(myListingsProvider),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      data: (listings) {
        if (listings.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (context, i) => MyListingCard(listing: listings[i]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final tab = _tabs[_selectedTab];

    final (icon, message, subtitle, showButton) = switch (tab) {
      'All' => (
          Icons.inventory_2_outlined,
          'No listings yet',
          'Create your first listing',
          true,
        ),
      'Draft' => (
          Icons.drafts_outlined,
          'No saved drafts',
          null,
          false,
        ),
      'Published' => (
          Icons.storefront_outlined,
          'Nothing listed yet',
          'Create a Listing',
          true,
        ),
      'Sold' => (
          Icons.check_circle_outline,
          'No sold listings yet',
          'Mark a listing as sold from My Listings',
          false,
        ),
      'Expired' => (
          Icons.schedule_outlined,
          'No expired listings',
          null,
          false,
        ),
      _ => (
          Icons.inventory_2_outlined,
          'No listings yet',
          null,
          false,
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showButton) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/dashboard/create-listing'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text(
                  tab == 'All'
                      ? 'Create your first listing \u2192'
                      : 'Create a Listing',
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
}

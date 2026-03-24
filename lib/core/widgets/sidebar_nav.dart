import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/auth/data/auth_repository.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

const _sellerItems = [
  _NavItem('Market', Icons.storefront_outlined, '/marketplace'),
  _NavItem('Dashboard', Icons.grid_view_outlined, '/dashboard'),
  _NavItem('My Listings', Icons.list_alt_outlined, '/dashboard/my-listings'),
  _NavItem('Messages', Icons.mail_outline_rounded, '/dashboard/messages'),
  _NavItem('ISO Board', Icons.search_outlined, '/iso'),
  _NavItem('My ISO Posts', Icons.inbox_outlined, '/dashboard/iso'),
  _NavItem('Reports', Icons.flag_outlined, '/dashboard/reports'),
  _NavItem('Knowledge', Icons.menu_book_outlined, '/knowledge'),
  _NavItem('Sellers', Icons.verified_outlined, '/sellers'),
];

const _adminItems = [
  _NavItem('Overview', Icons.dashboard_outlined, '/admin'),
  _NavItem('Users', Icons.people_outline, '/admin/users'),
  _NavItem('Sellers', Icons.verified_outlined, '/admin/sellers'),
  _NavItem('Listings', Icons.storefront_outlined, '/admin/listings'),
  _NavItem('Reports', Icons.flag_outlined, '/admin/reports'),
  _NavItem('Knowledge', Icons.menu_book_outlined, '/admin/knowledge'),
];

class SidebarNav extends StatelessWidget {
  final bool isAdmin;
  final bool isSeller;
  final bool collapsed; // tablet: icon-only mode
  /// 'Pending', 'Approved', 'Rejected', or null (no application).
  final String? applicationStatus;
  const SidebarNav({
    super.key,
    this.isAdmin = false,
    this.isSeller = false,
    this.collapsed = false,
    this.applicationStatus,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    String location = '';
    try {
      location = GoRouterState.of(context).uri.toString();
    } on Error {
      // No GoRouter in tree (e.g. during tests)
    }

    return Container(
      width: collapsed ? 64 : 220,
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: collapsed
                ? Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('P',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text('P',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('PFC',
                          style: AppTextStyles.headlineSm
                              .copyWith(color: AppColors.primary)),
                      Text('Pakistan Fragrance\nCommunity',
                          style: AppTextStyles.bodySm),
                    ],
                  ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: items.map((item) {
                final isActive = (item.route == '/dashboard' || item.route == '/admin')
                    ? location == item.route
                    : location.startsWith(item.route);
                return _SidebarItem(
                    item: item, isActive: isActive, collapsed: collapsed);
              }).toList(),
            ),
          ),

          // Profile shortcut
          Padding(
            padding: const EdgeInsets.all(8),
            child: _SidebarItem(
              item: const _NavItem(
                  'Profile', Icons.person_outline, '/dashboard/profile'),
              isActive: location.startsWith('/dashboard/profile'),
              collapsed: collapsed,
            ),
          ),

          // Sign out
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: collapsed
                ? IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        size: 20, color: AppColors.textMuted),
                    tooltip: 'Sign out',
                    onPressed: () => _signOut(context),
                  )
                : ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout_rounded,
                        size: 20, color: AppColors.textMuted),
                    title: Text(
                      'Sign out',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.textMuted),
                    ),
                    onTap: () => _signOut(context),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthRepository().signOut();
    if (context.mounted) context.go('/');
  }

  List<_NavItem> _buildItems() {
    if (isAdmin) return _adminItems;

    if (isSeller) return _sellerItems;

    // Member items — no "My Listings"; only show verification when applied
    final items = <_NavItem>[
      const _NavItem('Market', Icons.storefront_outlined, '/marketplace'),
      const _NavItem('Dashboard', Icons.grid_view_outlined, '/dashboard'),
      if (applicationStatus != null) _verificationNavItem(),
      const _NavItem('Messages', Icons.mail_outline_rounded, '/dashboard/messages'),
      const _NavItem('ISO Board', Icons.search_outlined, '/iso'),
      const _NavItem('My ISO Posts', Icons.inbox_outlined, '/dashboard/iso'),
      const _NavItem('Reports', Icons.flag_outlined, '/dashboard/reports'),
      const _NavItem('Knowledge', Icons.menu_book_outlined, '/knowledge'),
      const _NavItem('Sellers', Icons.verified_outlined, '/sellers'),
    ];
    return items;
  }

  _NavItem _verificationNavItem() {
    return switch (applicationStatus) {
      'Pending' => const _NavItem(
          'Verification', Icons.hourglass_top_rounded, '/dashboard/verification'),
      'Rejected' => const _NavItem(
          'Reapply', Icons.refresh_rounded, '/dashboard/verification'),
      _ => const _NavItem(
          'Become Seller', Icons.storefront_outlined, '/register/seller-apply'),
    };
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool collapsed;
  const _SidebarItem(
      {required this.item, required this.isActive, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(4),
        border: isActive
            ? const Border(left: BorderSide(color: AppColors.primary, width: 3))
            : null,
      ),
      child: collapsed
          ? IconButton(
              icon: Icon(item.icon,
                  size: 20,
                  color:
                      isActive ? AppColors.primary : AppColors.onBackground),
              tooltip: item.label,
              onPressed: () => context.go(item.route),
            )
          : ListTile(
              dense: true,
              leading: Icon(
                item.icon,
                size: 20,
                color: isActive ? AppColors.primary : AppColors.onBackground,
              ),
              title: Text(
                item.label,
                style: AppTextStyles.bodyMd.copyWith(
                  color: isActive ? AppColors.primary : AppColors.onBackground,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              onTap: () => context.go(item.route),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

const _memberItems = [
  _NavItem('Marketplace', Icons.storefront_outlined, '/marketplace'),
  _NavItem('Dashboard', Icons.grid_view_outlined, '/dashboard'),
  _NavItem('My Listings', Icons.list_alt_outlined, '/dashboard/my-listings'),
  _NavItem('Messages', Icons.mail_outline_rounded, '/dashboard/messages'),
  _NavItem('ISO Posts', Icons.search_outlined, '/dashboard/iso'),
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
  final bool collapsed; // tablet: icon-only mode
  const SidebarNav({super.key, this.isAdmin = false, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final items = isAdmin ? _adminItems : _memberItems;
    String location = '';
    try {
      location = GoRouterState.of(context).uri.toString();
    } catch (_) {
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
                final isActive = location.startsWith(item.route);
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
        ],
      ),
    );
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

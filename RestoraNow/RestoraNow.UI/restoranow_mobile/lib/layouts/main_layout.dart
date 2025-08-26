import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme.dart';
import '../providers/base/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/avatar_view.dart';
import '../widgets/menu_dialogs.dart';

class MainLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  /// If you’re in a reservation context and want checkout to attach to it.
  final int? cartReservationId;

  /// Force a back button even if the navigator can't pop.
  final bool forceBack;

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.cartReservationId,
    this.forceBack = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _mePrefetched = false;
  bool _authRedirected = false;

  // Top-level destinations shown in the drawer.
  static const _navItems = <_NavItem>[
    _NavItem(
      label: 'Home',
      route: '/home',
      icon: Icons.space_dashboard_outlined,
    ),
    _NavItem(label: 'Menu', route: '/menu', icon: Icons.menu_book_outlined),
    _NavItem(
      label: 'Reservations',
      route: '/reservations',
      icon: Icons.event_seat_outlined,
    ),
    _NavItem(
      label: 'Orders',
      route: '/orders',
      icon: Icons.receipt_long_outlined,
    ),
  ];

  Set<String> get _topLevelRoutes => _navItems.map((e) => e.route).toSet();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();

    // Auth guard (run once)
    if (!auth.isAuthenticated && !_authRedirected) {
      _authRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return;
    }

    // Prefetch "me" (once after auth)
    if (auth.isAuthenticated && !_mePrefetched) {
      _mePrefetched = true;
      context.read<UserProvider>().fetchMe();
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  void _toggleDrawer() {
    final isOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
    if (isOpen) {
      Navigator.of(context).pop();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  Future<void> _navigateTo(String route) async {
    // close drawer first if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;

    // Small delay for smoother drawer close -> page transition
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    // For top-level destinations, replace to avoid stacking duplicates.
    if (_topLevelRoutes.contains(route)) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final me = userProvider.currentUser;

    final initials = _initialsFrom(me?.firstName, me?.lastName);
    final fullName = _fullNameFrom(me?.firstName, me?.lastName);

    final currentRoute = ModalRoute.of(context)?.settings.name;
    final canPop = Navigator.of(context).canPop() || widget.forceBack;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.title),

        // Back if there is a stack to pop; otherwise menu.
        leading: canPop
            ? BackButton(
                onPressed: () {
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                    return;
                  }
                  Navigator.maybePop(context);
                },
              )
            : IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: _toggleDrawer,
              ),

        actions: [
          ...(widget.actions ?? const []),

          // Cart button with badge
          _CartAction(reservationId: widget.cartReservationId),

          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
            onPressed: () => _navigateTo('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),

      // Drawer only matters on top-level pages.
      drawer: Drawer(
        child: SafeArea(
          child: _AppDrawer(
            initials: initials,
            fullName: fullName,
            avatarBytes: userProvider.avatarBytes,
            avatarUrl: userProvider.avatarUrl,
            currentRoute: currentRoute,
            items: _navItems,
            onSelect: _navigateTo,
          ),
        ),
      ),

      body: SafeArea(child: widget.child),
    );
  }

  String _fullNameFrom(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    final full = '$f $l'.trim();
    return full.isEmpty ? 'My Profile' : full;
  }

  String _initialsFrom(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    if (f.isEmpty && l.isEmpty) return '?';
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    final one = f.isNotEmpty ? f : l;
    return one[0].toUpperCase();
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.initials,
    required this.fullName,
    required this.avatarBytes,
    required this.avatarUrl,
    required this.currentRoute,
    required this.items,
    required this.onSelect,
  });

  final String initials;
  final String fullName;
  final Uint8List? avatarBytes;
  final String? avatarUrl;
  final String? currentRoute;
  final List<_NavItem> items;
  final void Function(String route) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'RestoraNow',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        // User header
        InkWell(
          onTap: () => onSelect('/profile'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                AvatarView(
                  initials: initials,
                  imageBytes: avatarBytes,
                  imageUrl: avatarUrl,
                  size: 40,
                  showCameraBadge: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fullName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // Nav items
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final item = items[i];
              final selected = currentRoute == item.route;

              final bg = selected
                  ? AppTheme.primaryColor.withOpacity(0.08)
                  : Colors.transparent;
              final fg = selected ? AppTheme.primaryColor : Colors.black87;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelect(item.route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, color: fg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: fg,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'v1.0.0',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}

/// Cart action with live badge; opens bottom sheet cart on tap.
class _CartAction extends StatelessWidget {
  final int? reservationId;
  const _CartAction({this.reservationId});

  @override
  Widget build(BuildContext context) {
    final totalQty = context.select<CartProvider, int>((c) => c.totalQty);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Cart',
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: () {
            showCartSheet(context, reservationId: reservationId);
          },
        ),
        if (totalQty > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$totalQty',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  const _NavItem({
    required this.label,
    required this.route,
    required this.icon,
  });
}

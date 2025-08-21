import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme.dart';
import '../providers/base/auth_provider.dart';
import '../providers/user_provider.dart';

class MainLayout extends StatefulWidget {
  final String title;
  final Widget child;

  const MainLayout({super.key, required this.title, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _mePrefetched = false;
  bool _authRedirected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();

    // Auth guard: redirect once if unauthenticated
    if (!auth.isAuthenticated && !_authRedirected) {
      _authRedirected = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
      return;
    }

    // Prefetch profile once when authenticated
    if (auth.isAuthenticated && !_mePrefetched) {
      _mePrefetched = true;
      context.read<UserProvider>().fetchMe();
    }
  }

  Future<void> _go(String route) async {
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;

    // Small delay for smoother drawer -> route transition
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    Navigator.pushNamed(context, route); // <-- push (keeps back stack)
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<UserProvider>().currentUser;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          onPressed: () {
            final isOpen = _scaffoldKey.currentState?.isDrawerOpen ?? false;
            if (isOpen) {
              Navigator.of(context).pop();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
            onPressed: () => _go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: _AppDrawer(
            meInitials: _initialsFromMe(me?.firstName, me?.lastName),
            meFullName: _fullNameFromMe(me?.firstName, me?.lastName),
            meImageUrl: me?.imageUrl,
            onSelect: _go,
          ),
        ),
      ),
      body: SafeArea(child: widget.child),
    );
  }

  String _fullNameFromMe(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    final full = '$f $l'.trim();
    return full.isEmpty ? 'My Profile' : full;
  }

  String _initialsFromMe(String? first, String? last) {
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
    required this.meInitials,
    required this.meFullName,
    required this.meImageUrl,
    required this.onSelect,
  });

  final String meInitials;
  final String meFullName;
  final String? meImageUrl;
  final void Function(String route) onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem('Home', '/home', Icons.space_dashboard_outlined),
      _NavItem('Menu', '/menu', Icons.menu_book_outlined),
      _NavItem('Reservations', '/reservations', Icons.event_seat_outlined),
      _NavItem('Orders', '/orders', Icons.receipt_long_outlined),

      // _NavItem('Settings',  '/settings',     Icons.settings_outlined),
    ];

    final currentRoute = ModalRoute.of(context)?.settings.name;

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
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      (meImageUrl != null && meImageUrl!.isNotEmpty)
                      ? NetworkImage(meImageUrl!)
                      : null,
                  child: (meImageUrl == null || meImageUrl!.isEmpty)
                      ? Text(meInitials)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    meFullName,
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

class _NavItem {
  final String label;
  final String route;
  final IconData icon;
  const _NavItem(this.label, this.route, this.icon);
}

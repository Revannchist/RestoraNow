import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/base/auth_provider.dart';

class MainLayout extends StatefulWidget {
  final String title;
  final Widget child;

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Auth guard: redirect to login if not authenticated
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      });
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;

    Future<void> go(String route) async {
      // Close drawer first
      if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
        Navigator.of(context).pop();
      }
      if (currentRoute == route) return;
      await Future<void>.delayed(const Duration(milliseconds: 50)); // smoother transition
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, route);
    }

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
            onPressed: () => go('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: _NavList(
            currentRoute: currentRoute,
            onSelect: go,
          ),
        ),
      ),
      body: SafeArea(child: widget.child),
    );
  }
}

class _NavList extends StatelessWidget {
  final String? currentRoute;
  final void Function(String route) onSelect;

  const _NavList({
    required this.currentRoute,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem('Home',         '/home',         Icons.space_dashboard_outlined),
      _NavItem('Menu',         '/menu',         Icons.menu_book_outlined),
      _NavItem('Reservations', '/reservations', Icons.event_seat_outlined),
      _NavItem('Orders',       '/orders',       Icons.receipt_long_outlined),
      _NavItem('Settings',     '/settings',     Icons.settings_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand header
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
                child: const Icon(Icons.restaurant, color: AppTheme.primaryColor),
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

              final bg = selected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent;
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Icon(item.icon, color: fg),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: fg,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.chevron_right, size: 18, color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Footers
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'v1.0.0',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
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
  _NavItem(this.label, this.route, this.icon);
}

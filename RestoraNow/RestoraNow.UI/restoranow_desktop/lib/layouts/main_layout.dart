import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/base/auth_provider.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Auth guard: kick to login if token missing/expired
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated) {
      // Avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      });
    }

    final currentRoute = ModalRoute.of(context)?.settings.name;

    void go(String routeName) {
      if (currentRoute == routeName) return;
      Navigator.pushReplacementNamed(context, routeName);
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
        elevation: 2,
        titleSpacing: 0,
        title: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavLink(
                    label: 'Home',
                    route: '/home',
                    currentRoute: currentRoute,
                    onTap: go,
                  ),
                  _NavLink(
                    label: 'Restaurant',
                    route: '/restaurant',
                    currentRoute: currentRoute,
                    onTap: go,
                  ),
                  const SizedBox(width: 16),
                  _NavLink(
                    label: 'Users',
                    route: '/users',
                    currentRoute: currentRoute,
                    onTap: go,
                  ),
                  const SizedBox(width: 16),
                  _NavLink(
                    label: 'Menu',
                    route: '/menu',
                    currentRoute: currentRoute,
                    onTap: go,
                  ),
                  _NavLink(
                    label: 'Reviews',
                    route: '/reviews',
                    currentRoute: currentRoute,
                    onTap: go,
                  ),
                  const SizedBox(width: 16),
                  _NavLink(
                    label: 'Reservations',
                    route: '/reservations',
                    currentRoute: currentRoute,
                    onTap: go,
                  ),
                  _NavLink(
                    label: 'Orders',
                    route: '/orders',
                    currentRoute: currentRoute,
                    onTap: go,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 26),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthProvider>().logout(); // clear token/expiry
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: child,
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final String route;
  final String? currentRoute;
  final void Function(String) onTap;

  const _NavLink({
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: () => onTap(route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: selected
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white, width: 2),
                  ),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(selected ? 1 : 0.9),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

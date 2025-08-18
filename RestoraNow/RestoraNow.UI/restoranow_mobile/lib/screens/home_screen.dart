import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../layouts/main_layout.dart';
import '../providers/base/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MainLayout(
      title: 'Home',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Welcome ${auth.username ?? 'there'}!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Dashboard placeholder for quick access to key features.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Quick cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickCard(
                title: 'Orders',
                subtitle: 'View and manage',
                icon: Icons.receipt_long_outlined,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/orders');
                },
              ),
              _QuickCard(
                title: 'Reservations',
                subtitle: 'Today’s bookings',
                icon: Icons.event_seat_outlined,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/reservations');
                },
              ),
              _QuickCard(
                title: 'Menu',
                subtitle: 'Items & categories',
                icon: Icons.menu_book_outlined,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/menu');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

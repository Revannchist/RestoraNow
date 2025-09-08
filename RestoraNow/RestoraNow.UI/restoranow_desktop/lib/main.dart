import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/base/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/user_image_provider.dart';
import 'providers/menu_item_image_provider.dart';
import 'providers/menu_category_provider.dart';
import 'providers/menu_item_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/table_provider.dart';
import 'providers/review_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/order_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/menu_item_review_provider.dart';

import 'screens/login_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/user_screen/user_list_screen.dart';
import 'screens/menu_item_screen/menu_item_list_screen.dart';
import 'screens/restaurant_screen/restaurant_screen.dart';
import 'screens/review_screen/review_screen.dart';
import 'screens/reservation_screen/reservation_screen.dart';
import 'screens/order_screen/orders_screen.dart';
import 'screens/user_profile_screen.dart';

import 'theme/theme.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
}

/// A simple, reusable gate that checks auth + route permissions
/// using AuthProvider.canAccessRoute and redirects if needed.
class RouteGate extends StatelessWidget {
  final String route;
  final Widget child;
  const RouteGate({super.key, required this.route, required this.child});

  void _redirect(BuildContext context, String target, [String? snack]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (snack != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(snack)));
      }
      Navigator.pushReplacementNamed(context, target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      _redirect(context, '/login');
      return const SizedBox.shrink();
    }

    if (!auth.canAccessRoute(route)) {
      _redirect(context, '/home', 'Access denied');
      return const SizedBox.shrink();
    }

    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => UserImageProvider()),
        ChangeNotifierProvider(create: (_) => MenuItemImageProvider()),
        ChangeNotifierProvider(create: (_) => MenuCategoryProvider()),
        ChangeNotifierProvider(create: (_) => MenuItemProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => TableProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => MenuItemReviewProvider()),
      ],
      child: MaterialApp(
        title: 'RestoraNow Admin',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),

          // Guard everything else with RouteGate using the same route key
          '/home': (context) => const RouteGate(
            route: '/home',
            child: AnalyticsDashboardScreen(),
          ),
          '/users': (context) =>
              const RouteGate(route: '/users', child: UserListScreen()),
          '/menu': (context) =>
              const RouteGate(route: '/menu', child: MenuItemListScreen()),
          '/restaurant': (context) =>
              const RouteGate(route: '/restaurant', child: RestaurantScreen()),
          '/reviews': (context) =>
              const RouteGate(route: '/reviews', child: ReviewScreen()),
          '/reservations': (context) => const RouteGate(
            route: '/reservations',
            child: ReservationListScreen(),
          ),
          '/orders': (context) =>
              const RouteGate(route: '/orders', child: OrdersScreen()),
          '/profile': (context) =>
              const RouteGate(route: '/profile', child: UserProfileScreen()),
        },
      ),
    );
  }
}

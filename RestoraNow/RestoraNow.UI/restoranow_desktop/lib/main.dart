import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restoranow_desktop/providers/menu_category_provider.dart';
import 'package:restoranow_desktop/providers/menu_item_image_provider.dart';
import 'package:restoranow_desktop/providers/menu_item_provider.dart';
import 'package:restoranow_desktop/providers/reservation_provider.dart';
import 'package:restoranow_desktop/providers/restaurant_provider.dart';
import 'package:restoranow_desktop/providers/review_provider.dart';
import 'package:restoranow_desktop/providers/table_provider.dart';
import 'package:restoranow_desktop/providers/order_provider.dart';
import 'package:restoranow_desktop/providers/analytics_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'layouts/main_layout.dart';
import 'screens/user_screen/user_list_screen.dart';
import 'screens/menu_item_screen/menu_item_list_screen.dart';
import 'screens/restaurant_screen/restaurant_screen.dart';
import 'screens/review_screen/review_screen.dart';
import 'screens/reservation_screen/reservation_screen.dart';
import 'screens/order_screen/orders_screen.dart';
import 'screens/analytics_dashboard_screen.dart';
import 'screens/user_profile_screen.dart';

import 'screens/login_screen.dart';

import 'providers/base/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/user_image_provider.dart';
import 'theme/theme.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());

  //debugPrint("Loaded API_URL: ${dotenv.env['API_URL']}");
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
      ],
      child: MaterialApp(
        title: 'RestoraNow Admin',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const AnalyticsDashboardScreen(),
          '/users': (context) => const UserListScreen(),
          '/menu': (context) => const MenuItemListScreen(),
          '/restaurant': (context) => const RestaurantScreen(),
          '/reviews': (context) => const ReviewScreen(),
          '/reservations': (context) => const ReservationListScreen(),
          '/orders': (context) => const OrdersScreen(),
          '/profile': (context) => const UserProfileScreen(),
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authProvider.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/login');
      } else if (userProvider.users.isEmpty) {
        userProvider.fetchUsers();
      }
    });

    return MainLayout(
      child: Center(
        child: Text(
          'Dashboard content goes here',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

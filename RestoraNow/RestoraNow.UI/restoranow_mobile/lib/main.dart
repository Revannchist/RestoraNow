import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:restoranow_mobile/providers/menu_item_review_provider.dart';
import 'package:restoranow_mobile/screens/addresses_screen.dart';
import 'package:restoranow_mobile/screens/menu_screen.dart';

import 'theme/theme.dart';
import 'providers/base/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/menu_item_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/order_list_provider.dart';
import 'providers/menu_item_image_provider.dart';
import 'providers/address_provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/restaurant_review_provider.dart';
import 'providers/recommendations_provider.dart';
import 'providers/payment_provider.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reservations_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/restaurant_info_screen.dart';

class Env {
  static String get apiUrl {
    final value = dotenv.env['API_URL'];
    if (value == null || value.isEmpty) {
      return 'http://10.0.2.2:5294/api/';
    }
    return value.endsWith('/') ? value : '$value/';
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => MenuItemProvider()),
        ChangeNotifierProvider(create: (_) => MenuItemImageProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => OrderListProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantReviewProvider()),
        ChangeNotifierProvider(create: (_) => MenuItemReviewProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationsProvider()),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(
            getJwt: () async => AuthProvider.token, // <-- static getter
          ),
        ),
      ],
      child: MaterialApp(
        title: 'RestoraNow Mobile',
        theme: AppTheme.mobileLightTheme,
        initialRoute: '/home',
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/reservations': (_) => const ReservationsScreen(),
          '/menu': (_) => const MenuScreen(),
          '/orders': (_) => const OrdersScreen(),
          '/addresses': (_) => const AddressesScreen(),
          '/restaurant': (_) => const RestaurantInfoScreen(),
        },
      ),
    );
  }
}

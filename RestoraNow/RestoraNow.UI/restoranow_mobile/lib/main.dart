import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'theme/theme.dart';
import 'providers/base/auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/reservation_provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reservations_screen.dart';

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

      ],
      child: MaterialApp(
        title: 'RestoraNow Mobile',
        theme: AppTheme.mobileLightTheme,

        initialRoute: '/home',

        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/reservations': (_) => const ReservationsScreen(),
          
        },
      ),
    );
  }
}

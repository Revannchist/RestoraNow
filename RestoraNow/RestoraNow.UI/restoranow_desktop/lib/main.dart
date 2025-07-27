import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'layouts/main_layout.dart';
import 'screens/user_screen/user_list_screen.dart';
import 'screens/login_screen.dart';

import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'theme/theme.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'RestoraNow Admin',
        theme: AppTheme.lightTheme,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MyHomePage(title: 'RestoraNow Admin Panel'),
          '/users': (context) => const UserListScreen(),
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

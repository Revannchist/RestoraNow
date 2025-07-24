import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'layouts/main_layout.dart';
import 'screens/user_list_screen.dart';
import 'providers/user_provider.dart';
import 'theme/theme.dart'; // 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..fetchUsers()),
      ],
      child: MaterialApp(
        title: 'RestoraNow Admin',
        theme: AppTheme.lightTheme, // 
        initialRoute: '/home',
        routes: {
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
    return MainLayout(
      child: Center(
        child: Text(
          'Dashboard content goes here',
          style: Theme.of(context).textTheme.titleLarge, //
        ),
      ),
    );
  }
}

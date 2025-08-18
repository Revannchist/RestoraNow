import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/base/auth_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // If the authentication state is still being restored, show a loading indicator
    if (auth.restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // After the authentication state is restored, navigate to home or login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final next = auth.isAuthenticated ? '/home' : '/login';
      if (ModalRoute.of(context)?.settings.name != next) {
        Navigator.pushReplacementNamed(context, next);
      }
    });

    return const SizedBox.shrink();
  }
}

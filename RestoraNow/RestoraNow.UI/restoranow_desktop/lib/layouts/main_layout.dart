import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          backgroundColor: Colors.indigo[900],
          foregroundColor: Colors.white,
          elevation: 2,
          flexibleSpace: Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
                    child: const Text(
                      "Home",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/restaurant');
                    },
                    child: const Text(
                      "Restaurant",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/users');
                    },
                    child: const Text(
                      "Users",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/menu');
                    },
                    child: const Text(
                      "Menu",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reviews');
                    },
                    child: const Text(
                      "Reviews",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/reservations');
                    },
                    child: const Text(
                      "Reservations",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/orders');
                    },
                    child: const Text(
                      "Orders",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle, size: 28),
              tooltip: 'Profile',
              onPressed: () {
                print("Profile clicked");
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 26),
              tooltip: 'Logout',
              onPressed: () {
                // Clear auth and go back to login screen
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

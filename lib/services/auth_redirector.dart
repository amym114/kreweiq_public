import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AuthRedirector extends StatelessWidget {
  final Widget child;

  const AuthRedirector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // ✅ Listen to auth state
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ✅ Show loading screen while checking auth state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isUserLoggedIn = snapshot.hasData; // ✅ If snapshot has data, user is logged in

        if (!isUserLoggedIn) {
          // ✅ If user is NOT logged in, send them to login page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            GoRouter.of(context).go('/login');
          });
        }

        return child; // ✅ Continue rendering the app
      },
    );
  }
}

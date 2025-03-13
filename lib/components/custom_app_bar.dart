import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final bool isLoggedIn = snapshot.hasData;
        final currentLocation =
            GoRouter.of(context).routeInformationProvider.value.location;
        final noBackRoutes = [
          "/",
          "/login",
          "/register",
          "/home",
          "/payment-success"
        ];
        final showBackButton = !noBackRoutes.contains(currentLocation);

        // Build the popup menu items dynamically.
        final List<PopupMenuEntry<String>> menuItems = [];

        // Only add Login if not logged in.
        if (!isLoggedIn) {
          menuItems.add(
            const PopupMenuItem<String>(
              value: '/login',
              child: Text('Login'),
            ),
          );
        }

        // Common menu items.
        menuItems.addAll([
          const PopupMenuItem<String>(
            value: '/home',
            child: Text('Home'),
          ),
          const PopupMenuItem<String>(
            value: '/trivia',
            child: Text('Solo Trivia'),
          ),
          const PopupMenuItem<String>(
            value: '/trivia/untimed',
            child: Text('Solo Trivia - Untimed'),
          ),
          const PopupMenuItem<String>(
            value: '/pass-and-play-setup',
            child: Text('Pass and Play Trivia'),
          ),
          const PopupMenuItem<String>(
            value: '/about',
            child: Text('About'),
          ),
          const PopupMenuItem<String>(
            value: '/contact',
            child: Text('Contact + Legal'),
          ),
        ]);

        // Only add Logout if logged in.
        if (isLoggedIn) {
          menuItems.add(
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(
                    Icons.logout,
                    color: Color.fromRGBO(244, 184, 96, 1.0),
                  ),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: AppBar(
            // Add the home icon on the far left.
            leading: IconButton(
              icon: const Icon(Icons.home, color: Color.fromRGBO(244, 184, 96, 1.0)),
              onPressed: () {
                GoRouter.of(context).go('/home');
              },
            ),
            centerTitle: true,
            title: (currentLocation == "/login" ||
                    currentLocation == "/register" ||
                    currentLocation == "/")
                ? null // Hide the logo on login and register pages.
                : GestureDetector(
                    onTap: () => GoRouter.of(context).go('/home'),
                    child: Image.asset("images/kiq-horizontal-inverted.png",
                        height: 36),
                  ),
            backgroundColor: const Color(0xFF9D00CC),
            elevation: 0,
            actions: <Widget>[
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.menu,
                  color: Color.fromRGBO(244, 184, 96, 1.0),
                ),
                onSelected: (String value) async {
                  if (value == 'logout') {
                    await FirebaseAuth.instance.signOut();
                    // Give a short delay for the auth state change to propagate.
                    await Future.delayed(const Duration(milliseconds: 100));
                    GoRouter.of(context).go('/login');
                  } else {
                    GoRouter.of(context).go(value);
                  }
                },
                itemBuilder: (BuildContext context) => menuItems,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

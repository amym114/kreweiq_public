import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart'; // ✅ Import Provider
import 'package:krewe_iq/app_router.dart';

/// ✅ Global navigation key for GoRouter
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables
  await dotenv.load(fileName: "/dotenv");

  // ✅ Initialize Firebase safely
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      authDomain: "kreweiq.firebaseapp.com",
      measurementId: "G-YTNGS7DX42",
      storageBucket: "kreweiq.firebasestorage.app",
    ),
  );

  // FirebaseFirestore.instance.settings = const Settings(
  //   persistenceEnabled: true,
  // );
  // ✅ Stripe Configuration
  Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamProvider<User?>.value(
      value: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      catchError: (_, __) => null,
      child: Consumer<User?>(
        builder: (context, user, child) {
          // ✅ Determine login state dynamically
          bool isLoggedIn = user != null;

          return ChangeNotifierProvider(
            create: (context) => RouterNotifier(), // ✅ Provide Router State
            child: Consumer<RouterNotifier>(
              builder: (context, routerNotifier, child) {
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'Krewe IQ',
                  routerConfig: appRouter(
                      isLoggedIn, navigatorKey), // ✅ Use Navigator Key
                );
              },
            ),
          );
        },
      ),
    );
  }
}

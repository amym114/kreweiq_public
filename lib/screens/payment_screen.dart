import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:krewe_iq/extensions/hover_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:krewe_iq/router_notifier.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  late final StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {}); // Force a rebuild when auth state changes.
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<String?> _waitForCheckoutUrl(DocumentReference docRef) async {
    for (int i = 0; i < 10; i++) {
      // Tries 10 times with a short delay
      DocumentSnapshot snapshot = await docRef.get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        if (data.containsKey('url')) {
          return data['url'];
        }
      }
      await Future.delayed(Duration(seconds: 1));
    }
    return null; // If still null after 10 attempts
  }

  Future<void> _startCheckoutSession() async {
    // print("Starting checkout session...");
    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorMessage("Please log in to continue.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      // print("Creating checkout session...");
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('customers')
          .doc(user.uid)
          .collection('checkout_sessions')
          .add({
        'price': 'price_1Qt9BYLPTUNqg4c2F9acz74E',
        'success_url': 'https://kreweiq.com/#/payment-success',
        'cancel_url': 'https://kreweiq.com/#/trivia',
        'status': 'pending',
        'mode': 'payment',
        'scope': 'CROSS_DEVICE',
        'allow_promotion_codes': true,
        'payment_method_collection': 'if_required',
        'customer_creation': 'always'
      });

      // print("Waiting for checkout URL...");
      String? checkoutUrl = await _waitForCheckoutUrl(docRef);
      if (checkoutUrl == null) {
        throw Exception("No checkout URL received.");
      }

      // print("Checkout URL: $checkoutUrl");
      // Open the URL in an in-app webview instead of an external browser.
      if (!await launchUrl(Uri.parse(checkoutUrl),
          mode: LaunchMode.inAppWebView, webOnlyWindowName: '_self')) {
        throw Exception("Could not launch checkout URL.");
      }

      // Listen for updates in case the payment completes.
      late final StreamSubscription<DocumentSnapshot> subscription;
      subscription = docRef.snapshots().listen((snapshot) {
        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;
          if (data['status'] == 'complete') {
            subscription.cancel();
            if (mounted) {
              GoRouter.of(context).push('/payment-success');
              Provider.of<RouterNotifier>(context, listen: false).refresh();
            }
          } else if (data['status'] == 'canceled') {
            subscription.cancel();
            if (mounted) {
              _showErrorMessage("Payment was canceled.");
            }
          }
        }
      });
    } catch (e) {
      // print("🔥 Error processing payment: $e");
      _showErrorMessage("Error processing payment. Try again.");
    }

    setState(() => _isLoading = false);
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Main content.
            SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(maxWidth: 600),
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _startCheckoutSession,
                        child: Image.asset(
                            "/images/mardi-gras-2025-trivia-pack.jpg"),
                      ).showCursorOnHover,
                      const SizedBox(height: 10),
                      Text(
                        "Unlock the Mardi Gras Trivia Pack!",
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF4A148C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "You're about to purchase Mardi Gras Trivia, a plug-in pack for KreweIQ! Once you buy it, it's yours forever—no expiration, no worries. You'll get access to a treasure trove of Mardi Gras knowledge, from historic traditions to quirky parade facts.\n\n"
                        "Plus, you can tailor your gameplay to suit your style—challenge yourself with categorized questions in solo mode, or invite friends to join the fun with Pass-and-Play mode.\n\n"
                        "And who knows? We might just drop some new trivia packs in the future, so stay tuned!",
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF4A148C)),
                      ),
                      const SizedBox(height: 20),
                      if (isLoggedIn)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A148C),
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                          ),
                          onPressed: _startCheckoutSession,
                          child: Text(
                            "Buy it Now!",
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          ),
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 20),
                                ),
                                onPressed: null,
                                child: Text(
                                  "Buy it Now!",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Please log in to purchase.",
                                    style: TextStyle(
                                        fontSize: 16, color: Color(0xFF4A148C)),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF4A148C),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 20),
                                          ),
                                          onPressed: () => GoRouter.of(context)
                                              .push('/login'),
                                          child: Text(
                                            "Login",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF4A148C),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 20),
                                          ),
                                          onPressed: () => GoRouter.of(context)
                                              .push('/register'),
                                          child: Text(
                                            "Register",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            // Loading spinner overlay.
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

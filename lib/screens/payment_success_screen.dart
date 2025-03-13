import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';

class PaymentSuccessScreen extends StatefulWidget {
  const PaymentSuccessScreen({Key? key}) : super(key: key);

  @override
  _PaymentSuccessScreenState createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _markUserAsPaid();
  }

  Future<void> _markUserAsPaid() async {
    setState(() => _isUpdating = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // print("❌ User is not authenticated!");
      return;
    }

    String userId = user.uid;

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(userId)
          .set({'hasPurchased': true}, SetOptions(merge: true));

      // print("✅ User purchase status updated successfully!");
    } catch (e) {
      // print("🔥 Error updating user purchase status: $e");
    }

    setState(() => _isUpdating = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: const CustomAppBar(),
          body: Container(
            width: double.infinity,
            height:
                MediaQuery.of(context).size.height, // Forces full screen height
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset("/images/mardi-gras-2025-trivia-pack.jpg"),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Purchase Complete!",
                              style: TextStyle(
                                color: Color(0xFF4A148C),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "You now have permanent access to Mardi Gras 2025 Trivia on KreweIQ. Time to test your knowledge and see how much you really know about Carnival!\n\n"
                              "Stay tuned—more trivia packs may be available in the future!\n\n"
                              "Thanks for your support, and enjoy the game!",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A148C),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                ),
                                onPressed: () =>
                                    GoRouter.of(context).go('/trivia'),
                                icon: const Icon(
                                  Icons.play_arrow_sharp,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Go Play Trivia',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

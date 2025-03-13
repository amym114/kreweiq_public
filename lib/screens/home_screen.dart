import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/extensions/hover_extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hasPurchased = false;

  @override
  void initState() {
    super.initState();
    _fetchPurchaseStatus();
  }

  void _fetchPurchaseStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()?['hasPurchased'] == true) {
        setState(() {
          _hasPurchased = true;
        });
      }
    });
  }

  /// Build a clickable pair (icon and label) as one unit.
  Widget buildClickablePair(
      String iconAsset, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "images/$iconAsset.png",
              height: 80,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget for the three icon/button pairs.
  /// On desktop, arranged in a row with each taking 1/3 of 600px minus 20px gutters.
  /// On mobile, in a column with full-width pairs.
  Widget _buildIconButtonPairs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double containerWidth = 600;
        if (constraints.maxWidth >= 600) {
          // Calculate each pair width: total width = 600, with 2 gutters of 20px (total 40px)
          // so available width = 560; each pair is 560/3.
          final double pairWidth = 560 / 3;
          return Row(
            children: [
              SizedBox(
                width: pairWidth,
                child: buildClickablePair("hand", "Pass and Play", () {
                  GoRouter.of(context).go('/pass-and-play-setup');
                }),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: pairWidth,
                child: buildClickablePair("hourglass", "Solo (Timed)", () {
                  GoRouter.of(context).go('/trivia');
                }),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: pairWidth,
                child: buildClickablePair("clock", "Solo (Untimed)", () {
                  GoRouter.of(context).go('/trivia/untimed');
                }),
              ),
            ],
          );
        } else {
          // Mobile: full-width pairs stacked in a column.
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: buildClickablePair("hand", "Pass and Play", () {
                  GoRouter.of(context).go('/pass-and-play-setup');
                }),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: buildClickablePair("hourglass", "Solo (Timed)", () {
                  GoRouter.of(context).go('/trivia');
                }),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: buildClickablePair("clock", "Solo (Untimed)", () {
                  GoRouter.of(context).go('/trivia/untimed');
                }),
              ),
            ],
          );
        }
      },
    );
  }

  /// Build the extra small button (no icon) for /scavenger-hunt.
  Widget _buildScavengerHuntButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            GoRouter.of(context).go('/scavenger-hunt');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16), // Adjust padding as desired
          ),
          child: const Text(
            "Scavenger Hunt",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadToHeadButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            GoRouter.of(context).go('/challenge');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            side: const BorderSide(color: Colors.white, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16), // Adjust padding as desired
          ),
          child: const Text(
            "Head-to-Head Challenge",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // White box with Mardi Gras graphic and purchase logic.
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _hasPurchased
                      ? Image.asset("/images/mg-header-new.jpg")
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => GoRouter.of(context).go('/payment'),
                              child: Image.asset("/images/mg-header-new.jpg"),
                            ).showCursorOnHover,
                            ElevatedButton(
                              onPressed: () =>
                                  GoRouter.of(context).go('/payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(244, 184, 96, 1.0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 24, horizontal: 24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.lock_outline),
                                  SizedBox(width: 4),
                                  Text(
                                    "Unlock - \$2.99",
                                    style: TextStyle(
                                        fontSize: 20, color: Color(0xFF4A148C)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                // Icon/button pairs section.
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: _buildIconButtonPairs(),
                ),
                const SizedBox(height: 40),
                const Text("BONUS GAMES",
                    style: TextStyle(
                        color: Color.fromRGBO(231, 207, 248, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 20),
                // Additional smaller Scavenger Hunt button.
                _buildScavengerHuntButton(),
                const SizedBox(height: 20),
                _buildHeadToHeadButton()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

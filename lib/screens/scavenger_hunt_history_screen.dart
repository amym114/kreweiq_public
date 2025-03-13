import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class ScavengerHuntHistoryPage extends StatefulWidget {
  const ScavengerHuntHistoryPage({Key? key}) : super(key: key);

  @override
  _ScavengerHuntHistoryPageState createState() =>
      _ScavengerHuntHistoryPageState();
}

class _ScavengerHuntHistoryPageState extends State<ScavengerHuntHistoryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _loading = true;
  List<Map<String, dynamic>> _hunts = [];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkUserLogin();
    _loadHunts();
  }

  /// Check if a user is logged in
  void _checkUserLogin() {
    setState(() {
      _isLoggedIn = FirebaseAuth.instance.currentUser != null;
    });
  }

  /// Fetch past scavenger hunts from Firestore
  void _loadHunts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    List<Map<String, dynamic>> hunts =
        await _firestoreService.fetchUserScavengerHunts(user.uid);

    setState(() {
      _hunts = hunts;
      _loading = false;
    });
  }

  /// Duplicate the scavenger hunt and navigate to the new one
  Future<void> _duplicateHunt(Map<String, dynamic> huntData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentReference newHuntRef = await FirebaseFirestore.instance
          .collection('user_scavenger_hunts')
          .doc(user.uid)
          .collection('hunts')
          .add({
        ...huntData,
        "createdAt": FieldValue.serverTimestamp(),
        "items": huntData["items"]
            .map((item) => {...item, "completed": false})
            .toList(),
      });

      print("✅ Hunt duplicated with new ID: ${newHuntRef.id}");
      if (mounted) {
        GoRouter.of(context).go('/scavenger-hunt/play/${newHuntRef.id}');
      }
    } catch (e) {
      print("❌ Error duplicating hunt: $e");
    }
  }

  /// Build the list of past scavenger hunts
  Widget _buildHuntList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _hunts.length,
      itemBuilder: (context, index) {
        var hunt = _hunts[index];
        bool isCompleted =
            hunt["items"].every((item) => item["completed"] == true);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(
              hunt["name"],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(isCompleted ? "✅ Completed" : "⏳ In Progress"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCompleted)
                  ElevatedButton(
                      onPressed: () => GoRouter.of(context)
                          .go('/scavenger-hunt/play/${hunt["id"]}'),
                      child: const Text("Resume", style: TextStyle(color: Colors.white),),
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all(Color(0xFF4A148C)),
                      )),
                if (isCompleted)
                  ElevatedButton(
                    onPressed: () => _duplicateHunt(hunt),
                    child: const Text("Play Again"),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the main content for history tab
  Widget _buildHistoryContent() {
    if (!_isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Log in to save and access your past scavenger hunts.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/login'),
              child: const Text("Login"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/register'),
              child: const Text("Register"),
            ),
          ],
        ),
      );
    } else if (_loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_hunts.isEmpty) {
      return const Center(child: Text("No past scavenger hunts found."));
    } else {
      return _buildHuntList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: 600,
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _isLoggedIn ? _buildHuntList() : _buildHistoryContent(),
        ),
      ),
    );
  }
}

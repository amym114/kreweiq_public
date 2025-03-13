import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:krewe_iq/components/custom_app_bar.dart';
import 'package:krewe_iq/services/firestore_service.dart';

class ScavengerHuntPage extends StatefulWidget {
  final String huntId;

  const ScavengerHuntPage({Key? key, required this.huntId}) : super(key: key);

  @override
  _ScavengerHuntPageState createState() => _ScavengerHuntPageState();
}

class _ScavengerHuntPageState extends State<ScavengerHuntPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? _huntData;
  bool _loading = true;
  bool _huntCompleted = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkUserLogin();
    _loadHunt();
  }

  /// Check if a user is logged in
  void _checkUserLogin() {
    setState(() {
      _isLoggedIn = FirebaseAuth.instance.currentUser != null;
    });
  }

  /// Fetch scavenger hunt data
  void _loadHunt() async {
    print("🧐 Fetching scavenger hunt for ID: ${widget.huntId}");
    Map<String, dynamic>? huntData =
        await _firestoreService.fetchScavengerHunt(widget.huntId);

    if (huntData != null) {
      print("✅ Scavenger Hunt Data: $huntData");
      setState(() {
        _huntData = huntData;
        _loading = false;
        _checkCompletion(); // Check if hunt is already completed
      });
    } else {
      print("❌ Failed to load scavenger hunt.");
      setState(() => _loading = false);
    }
  }

  /// Toggle completion of an item and check if all are completed
  void _toggleCompletion(String itemId, bool isCompleted) async {
    await _firestoreService.updateScavengerHuntItem(
        widget.huntId, itemId, isCompleted);
    setState(() {
      _huntData!["items"] = _huntData!["items"].map((item) {
        if (item["id"] == itemId) {
          item["completed"] = isCompleted;
        }
        return item;
      }).toList();
    });
    _checkCompletion();
  }

  /// Check if all items in the hunt are completed
  void _checkCompletion() {
    bool allCompleted =
        _huntData!["items"].every((item) => item["completed"] == true);
    setState(() {
      _huntCompleted = allCompleted;
    });
  }

  /// Duplicate the scavenger hunt in Firestore and navigate to the new one
  Future<void> _duplicateHunt() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      DocumentReference newHuntRef = await FirebaseFirestore.instance
          .collection('user_scavenger_hunts')
          .doc(user.uid)
          .collection('hunts')
          .add({
        ..._huntData!,
        "createdAt": FieldValue.serverTimestamp(),
        "items": _huntData!["items"]
            .map((item) => {...item, "completed": false})
            .toList(),
      });
      print("✅ Hunt duplicated with new ID: ${newHuntRef.id}");
      if (mounted) {
        GoRouter.of(context).go('/scavenger-hunt/play/${newHuntRef.id}');
        Future.delayed(const Duration(milliseconds: 100), () {
          GoRouter.of(context).refresh();
        });
      }
    } catch (e) {
      print("❌ Error duplicating hunt: $e");
    }
  }

  /// Build the success screen when the hunt is completed
  Widget _buildSuccessScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset("images/friedchicken.jpg", width: 400),
        SizedBox(height: 20),
        Text("Winner, winner, fried chicken dinner!",
            style: GoogleFonts.shrikhand(
                textStyle: TextStyle(fontSize: 36, color: Color(0xFF4A148C)),
                height: 1)),
        const SizedBox(height: 20),
        Text(
            "You've spotted every last Carnival gem—you're officially a Mardi Gras master! Now go celebrate like a true reveler!"),
        const SizedBox(height: 20),
        if (_isLoggedIn) 
          ElevatedButton(
            onPressed: _duplicateHunt,
            child: const Text("Play Same Hunt Again"),
          ),
          const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => GoRouter.of(context).go('/scavenger-hunt/'),
          child: const Text("Generate New Hunt"),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => GoRouter.of(context).go('/'),
          child: const Text("Home"),
        ),
      ],
    );
  }

  /// Build the main hunt list UI
  Widget _buildHuntList() {
    List<dynamic> items = List.from(_huntData!["items"]);

    // Group items by difficulty (ensuring keys are lowercase)
    Map<String, List<dynamic>> groupedItems = {};
    for (var item in items) {
      String diff = (item["difficulty"] as String).toLowerCase();
      groupedItems.putIfAbsent(diff, () => []).add(item);
    }

    // For each difficulty group, sort items by categorySortOrder
    groupedItems.forEach((key, value) {
      value.sort(
          (a, b) => a["categorySortOrder"].compareTo(b["categorySortOrder"]));
    });

    // Fixed order for difficulties
    final difficultiesOrder = ['sample', 'easy', 'medium', 'hard'];
    List<Widget> listWidgets = [];
    for (var diff in difficultiesOrder) {
      if (groupedItems.containsKey(diff)) {
        listWidgets.add(Text(
          diff.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ));
        listWidgets.add(const SizedBox(height: 8));
        for (var item in groupedItems[diff]!) {
          listWidgets.add(
            Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  side: const BorderSide(color: Colors.black),
                ),
              ),
              child: CheckboxListTile(
                title: Text(
                  " ${item["emoji"]} ${item["text"]}",
                  style: TextStyle(
                    fontFamily: "NotoColorEmoji",
                    fontSize: 16,
                    decoration:
                        item["completed"] ? TextDecoration.lineThrough : null,
                    color: item["completed"] ? Colors.grey : Colors.black,
                  ),
                ),
                value: item["completed"],
                onChanged: (bool? value) {
                  if (value != null) {
                    _toggleCompletion(item["id"], value);
                  }
                },
              ),
            ),
          );
        }
        listWidgets.add(const SizedBox(height: 16));
      }
    }

    return ListView(
      shrinkWrap: true,
      children: listWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    if (_loading) {
      return const Scaffold(
        appBar: CustomAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_huntData == null) {
      return const Scaffold(
        appBar: CustomAppBar(),
        body: Center(child: Text("Hunt not found.")),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D00CC), Color(0xFF4A148C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Scavenger Hunt",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 600,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _huntCompleted
                        ? _buildSuccessScreen()
                        : _buildHuntList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
